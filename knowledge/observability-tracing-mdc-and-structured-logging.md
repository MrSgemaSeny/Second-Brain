# Observability First: Сквозной Трейсинг, Correlation ID (X-Request-ID), MDC и Структурированное JSON-Логирование

## Обзор и Проблема
В монолитных и распределенных веб-приложениях при одновременной работе десятков и сотен пользователей неструктурированные строковые логи (`log.info("...")`) приводят к эффекту «стены текста». При возникновении ошибки на клиенте невозможно быстро сопоставить конкретный сбой в браузере с записью в логах бэкенда и JPA-запросами к базе данных.

Паттерн **Observability First** закладывает сквозную трассировку и диагностический контекст на всех слоях системы (Frontend -> Gateway/Filter -> Service -> Database -> Logs -> Grafana Loki).

---

## Архитектурные Компоненты

### 1. Сквозной Correlation ID (`X-Request-ID`)
Каждый входящий или исходящий запрос помечается уникальным идентификатором:
- **Фронтенд (`fetchClient`)**: генерирует `X-Request-ID: crypto.randomUUID()` и передает его в заголовках. При получении ошибки `ApiError` сохраняет этот ID, позволяя вывести пользователю или передать в службу поддержки понятный код инцидента.
- **Бэкенд (`CorrelationIdFilter`)**: фильтр наивысшего приоритета (`Ordered.HIGHEST_PRECEDENCE`) считывает `X-Request-ID` или создает новый, если запрос пришел без него, и возвращает его в ответе клиенту (`response.setHeader("X-Request-ID", requestId)`).

### 2. Mapped Diagnostic Context (MDC)
SLF4J / Logback сохраняет контекст запроса в потоке (`ThreadLocal`):
- `requestId` — сквозной Correlation ID.
- `traceId` — идентификатор распределенного трейса.
- `spanId` — идентификатор текущего шага/операции.
- `clientIp` — реальный IP-клиента (с учетом доверенных прокси Cloudflare/Fly.io).
- `userId` — ID авторизованного пользователя.

**Критическое правило безопасности пула потоков**: Очистка MDC обязательна в блоке `finally` (`MDC.clear()`), чтобы избежать утечки контекста в повторно используемые потоки Tomcat / Jetty.

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
@RequiredArgsConstructor
public class CorrelationIdFilter extends OncePerRequestFilter {

    public static final String CORRELATION_ID_HEADER = "X-Request-ID";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String requestId = request.getHeader(CORRELATION_ID_HEADER);
        if (!StringUtils.hasText(requestId)) {
            requestId = UUID.randomUUID().toString();
        }
        response.setHeader(CORRELATION_ID_HEADER, requestId);
        MDC.put("requestId", requestId);
        MDC.put("clientIp", ipResolver.resolveClientIp(request));

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

### 3. Сквозной трейсинг (Micrometer Tracing + OpenTelemetry)
- **Библиотеки**: `io.micrometer:micrometer-tracing-bridge-otel`.
- **Конфигурация**: `management.tracing.sampling.probability: 1.0`, распространение `W3C,B3`.
- **Назначение**: Автоматическое профилирование контроллеров, REST-запросов и запросов к БД с пробросом `traceId` и `spanId` в MDC.

### 4. Структурированное JSON-логирование (Logstash / Grafana Loki)
Конфигурация Logback (`logback-spring.xml`) разделяется по профилям:
- **Development (`!prod & !json`)**: Человекочитаемый цветной формат:
  ```text
  %clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} %clr(%5p) %clr([${appName},%X{traceId:-},%X{spanId:-},%X{requestId:-}]){magenta} %clr(%logger{39}){cyan} : %m%n%wEx
  ```
- **Production (`prod | json`)**: Однострочный JSON через `net.logstash.logback.encoder.LogstashEncoder`:
  ```json
  {
    "@timestamp": "2026-09-01T18:00:00.123Z",
    "service": "MrDevCourses",
    "level": "INFO",
    "logger": "com.mrdev.modules.homework.controller.HomeworkController",
    "message": "Homework submitted",
    "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
    "spanId": "00f067aa0ba902b7",
    "requestId": "c84b7a12-9e54-4a21-8280-92841cf6b321",
    "clientIp": "192.168.1.50"
  }
  ```

---

## Преимущества
1. **Мгновенная локализация ошибок**: Поиск в Grafana Loki `{service="MrDevCourses"} | json | requestId="c84b7a12"` выводит всю цепочку выполнения за 1 секунду.
2. **Zero-overhead на клиенте**: Браузер всегда имеет `requestId` для корректного отображения ошибок и логирования в Sentry / Crashlytics.
3. **Готовность к распределенной архитектуре**: При выносе микросервисов `traceId` и `X-Request-ID` прозрачно пробрасываются через заголовки HTTP (W3C traceparent).
