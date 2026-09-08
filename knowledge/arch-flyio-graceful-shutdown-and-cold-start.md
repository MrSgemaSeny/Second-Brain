# Архитектура: Fly.io Graceful Shutdown и Cold Start (Scale-to-Zero vs Warm Latency)

## 1. Graceful Shutdown при Rolling Deploy на Fly.io

### Проблема резкого обрыва соединений:
При выполнении `fly deploy` платформа поднимает новую виртуальную машину (VM), проверяет healthcheck и отправляет старой машине сигнал `SIGTERM`.
По умолчанию Tomcat в Spring Boot гасит процесс немедленно:
- Все запросы, находящиеся в обработке (In-Flight Requests: генерация тяжелого PDF-отчета, загрузка договора, расчет налогов), аварийно обрываются.
- Пользователь в браузере видит белый экран с ошибкой `502 Bad Gateway` или `Connection Reset by Peer`.
- Транзакции в базе данных падают в экстренный Rollback, а фоновые асинхронные задачи теряют контекст.

### Конфигурация Graceful Shutdown:
В `application.properties`:
```properties
# Включение мягкого завершения веб-сервера
server.shutdown=graceful

# Максимальное время ожидания завершения in-flight запросов
spring.lifecycle.timeout-per-shutdown-phase=30s
```

### Механика работы:
1. При получении `SIGTERM` Spring Boot переводит фазу жизненного цикла в SHUTTING_DOWN.
2. Tomcat **прекращает принимать новые подключения** (новые запросы маршрутизируются на уже поднятую новую машину Fly.io).
3. Все текущие активные запросы получают до 30 секунд на штатное завершение.
4. После завершения последнего запроса (или по истечении таймаута) закрываются HikariCP пулы соединений и процесс завершается с кодом 0.

### Тестирование Graceful Shutdown:
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GracefulShutdownTest {

    @LocalServerPort
    private int port;

    @Autowired
    private ConfigurableApplicationContext context;

    @Test
    void shouldCompleteInFlightRequestDuringShutdown() throws Exception {
        RestClient client = RestClient.create("http://localhost:" + port);

        // 1. Запускаем асинхронный долгий запрос (например, обработка 3 секунды)
        CompletableFuture<ResponseEntity<String>> inFlightRequest = CompletableFuture.supplyAsync(() -> 
            client.get()
                  .uri("/api/v1/test/long-running-operation")
                  .retrieve()
                  .toEntity(String.class)
        );

        // Даем запросу гарантированно дойти до сервиса
        Thread.sleep(500);

        // 2. Инициируем остановку контекста (эмуляция SIGTERM от Fly.io)
        CompletableFuture.runAsync(() -> context.close());

        // 3. In-flight запрос обязан успешно завершиться с кодом 200 OK
        ResponseEntity<String> response = inFlightRequest.get(10, TimeUnit.SECONDS);
        assertThat(response.getStatusCode().value()).isEqualTo(200);

        // 4. Попытка отправить НОВЫЙ запрос после начала shutdown обязана быть отклонена
        assertThatThrownBy(() -> 
            client.get().uri("/api/v1/services/highlighted").retrieve().toBodilessEntity()
        ).isInstanceOf(ResourceAccessException.class);
    }
}
```

---

## 2. Cold Start: Анализ задержек при Scale-to-Zero

### Проблема засыпающих машин (Auto-Stop):
На экономных тарифах Fly.io включена политика авто-остановки неактивных машин:
```toml
[http_service]
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0
```
Когда запросов нет более 5-10 минут, машина переходит в статус `stopped`.

### Анатомия задержки Cold Start:
При поступлении первого внешнего HTTP-запроса клиент упирается в совокупную задержку трех фаз:
1. **Пробуждение микро-VM Firecracker (Fly.io):** 300–800 мс.
2. **Инициализация JVM и Spring Boot:** 12–22 секунды (загрузка Metaspace, валидация 121 миграции Flyway, запуск Hibernate 7, прогрев пула HikariCP).
3. **Первый JIT компилятор и DispatcherServlet:** 500–1200 мс.

**Итоговый Cold Start Latency:** 15–25 секунд для первого пользователя (риск таймаута браузера 504).  
**Warm Latency (после прогрева):** 60–150 мс.

### Методика тестирования Cold Start:
1. **Разделение метрик в SLA:** Никогда нельзя усреднять Cold Start с Warm Latency. В отчетах фиксируются две раздельные метрики:
   - `Cold Start TTFB` (Time to First Byte после холодного пробуждения).
   - `Warm P95 / P99 Latency`.
2. **Скрипт проверки Cold Start в CI/CD (Artillery / Bash):**
   ```bash
   # 1. Принудительно гасим инстанс на Fly.io
   fly machine stop $(fly machine list -q)
   sleep 5

   # 2. Замеряем точное время пробуждения до первого HTTP 200
   curl -o /dev/null -s -w 'Cold Start TTFB: %{time_starttransfer}s\n' https://zhanfinance.fly.dev/actuator/health
   ```

### Инженерные меры оптимизации и предотвращения:
1. **Class Data Sharing (CDS):** Использование `java -XX:ArchiveClassesAtExit=app.jsa` сокращает запуск JVM на 30-40%.
2. **Keep-Alive пинги (Production Best Practice):** Для исключения засыпания в бизнес-часы (с 08:00 до 20:00 по времени Алматы UTC+5) настраивается внешний пинг через UptimeRobot / Cron раз в 4 минуты на легкий эндпоинт `/actuator/health`. Это удерживает машину в "горячем" состоянии за 0$ дополнительных затрат.
