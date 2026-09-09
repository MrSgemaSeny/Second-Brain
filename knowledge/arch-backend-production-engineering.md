# Архитектура и бэкенд-инженерия в продакшене (Backend Production Engineering)

Ключевые инженерные практики масштабируемых и отказоустойчивых сервисов на Spring Boot 3 и PostgreSQL.

---

## 1. Модульный монолит на базе Spring Boot (DDD / Feature Modules)

Вместо дробления на микросервисы на раннем этапе архитектура организуется в виде структурированного монолита:
- Доменные границы разделены по пакетам (`modules.auth`, `modules.crm`, `modules.billing`, `modules.courses`, `modules.documents`, `modules.chat`, `modules.notifications`).
- Взаимодействие между модулями — строго через публичные интерфейсы сервисов или доменные события Spring (`ApplicationEventPublisher`), без прямых перекрёстных зависимостей между репозиториями.
- Общий контекст (`shared`, `common`) содержит сквозные аспекты: безопасность, обработку ошибок, базовые DTO, утилиты дат и форматирования.

---

## 2. Управление миграциями БД Flyway в Production

### 2.1. Неизменяемость применённых миграций
- Файлы миграций (`V1__...sql` — `V108__...sql`) являются **строго неизменяемыми**. Изменение даже одного пробела меняет контрольную сумму (checksum) и блокирует запуск приложения на проде.
- Любые доработки, добавление колонок, индексов или триггеров выполняются строго новым файлом миграции (`V109__...sql`).

### 2.2. Разделение стартапов: @EventListener vs @PostConstruct
- **Категорический запрет**: Использование `@PostConstruct` для операций с базой данных (заполнение справочников, сидеры). `@PostConstruct` может выполниться до завершения миграций Flyway, что приводит к состоянию гонки (Race Condition).
- **Стандарт**: Запуск операций сидирования и первичной инициализации строго по событию готовности контекста:
  ```java
  @EventListener(ApplicationReadyEvent.class)
  public void seedInitialData() {
      // Гарантированно выполняется ПОСЛЕ успешного применения всех миграций Flyway
  }
  ```

---

## 3. Двухуровневый кэш: Caffeine L1 + Redis L2

| Уровень | Технология | Размещение | Назначение | Задержка |
|---|---|---|---|---|
| **L1** | Caffeine Cache | In-Memory (Heap/JVM) | Высокочастотные горячие данные, Rate Limiting, RBAC-матрица, справочники | < 1 ms |
| **L2** | Valkey Redis / Upstash | Внешний сервис | Сессионные токены, распределенный лок, тяжелые кэши публичных профилей | 5–15 ms |

При запросе данных сначала опрашивается L1; при промахе — L2; при повторном промахе — выполняется SQL-запрос с прогревом обоих уровней кэша.

---

## 4. Генерация документов PDF: Flying Saucer vs OpenHtmlToPdf

### 4.1. Сравнение движков
- **Flying Saucer (XHTML + CSS 2.1)**: Требует строгой валидной разметки XML, табличной верстки (`<table>`, `<tr>`, `<td>`), шестнадцатеричных цветов. Любой незакрытый тег или modern CSS (flex/grid) роняет генератор.
- **OpenHtmlToPdf**: Современный форк, лучшая поддержка шрифтов, кириллицы и CSS3.

### 4.2. Регистрация кириллических шрифтов
Шрифты из JAR-архива не могут быть прочитаны парсером напрямую по путям `jar:file:...`.
**Паттерн инициализации**:
1. Проверка наличия ресурса `/fonts/arial.ttf` через `getResourceAsStream()`.
2. Если ресурс найден — извлечение во временную директорию ОС (`Files.createTempFile`).
3. Регистрация пути временного файла в `ITextRenderer` / `PdfRendererBuilder`.
4. Если файл отсутствует — безопасный fallback на системные шрифты без генерации HTTP 500 ошибки.

---

## 5. Потоковый вывод SSE (Server-Sent Events) для AI-чатов

Для интеграции с LLM (Groq, OpenAI) используется протокол `text/event-stream`:
- Контроллер возвращает `SseEmitter` с настроенным таймаутом (например, 120 000 ms).
- Вторичный поток читает чанки из HttpClient и отправляет их в эмиттер:
  ```java
  emitter.send(SseEmitter.event().data(chunk).name("delta"));
  ```
- Обработчики `emitter.onCompletion()` и `emitter.onError()` гарантируют освобождение ресурсов при закрытии вкладки браузера.

---

## 6. Real-Time мессенджер: WebSocket STOMP с JWT аутентификацией

- Подключение по протоколу WebSocket поверх SockJS по адресу `/ws`.
- Аутентификация выполняется на этапе рукопожатия STOMP-фрейма `CONNECT`:
  ```java
  @Override
  public Message<?> preSend(Message<?> message, MessageChannel channel) {
      StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
      if (StompCommand.CONNECT.equals(accessor.getCommand())) {
          String authHeader = accessor.getFirstNativeHeader("Authorization");
          String token = extractToken(authHeader);
          UserDetails user = jwtService.validateAndGetUser(token);
          accessor.setUser(new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities()));
      }
      return message;
  }
  ```
- Персональные очереди пользователя: `/user/topic/chat/{userId}` и `/user/topic/notifications`.

---

## 7. Изоляция Email-движка: @TransactionalEventListener(AFTER_COMMIT)

### 7.1. Проблема синхронной отправки
Прямой вызов `mailSender.send()` внутри `@Transactional` метода приводит к:
1. Зависанию потоков Tomcat при сетевых задержках SMTP-провайдера (3–5 сек).
2. Исчерпанию пула соединений HikariCP (удерживается активная транзакция).
3. Отправке "фантомных" писем при последующем откате (`ROLLBACK`) транзакции в базе.

### 7.2. Решение: Событийная асинхронная модель
1. **Публикация доменного события**:
   ```java
   eventPublisher.publishEvent(new SendHtmlEmailEvent(to, subject, template, model));
   ```
2. **Слушатель strictly AFTER_COMMIT**:
   ```java
   @Component
   public class EmailEventListener {
       @Async("mailExecutor")
       @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
       public void handleEmail(SendHtmlEmailEvent event) {
           emailNotificationService.sendDirect(event);
       }
   }
   ```
3. **Изолированный пул `mailExecutor`**:
   - `corePoolSize = 2`, `maxPoolSize = 6`, `queueCapacity = 200`.
   - Политика сброса: `DiscardPolicy` с записью в лог `WARN/ERROR`.
   - Почтовые сбои никогда не блокируют Tomcat и не исчерпывают соединения БД.

---

## 8. Очистка боевой базы данных (Production DB Hygiene)

### 8.1. Принципы безопасной очистки от тестовых данных
- Все операции проводятся в единой транзакции (`BEGIN ... COMMIT`).
- Удаление происходит в строгом порядке, учитывающем внешние ключи (`Foreign Key Constraints`): дочерние таблицы удаляются первыми, родительские — последними.
- Использование точных селекторов (`WHERE email LIKE 'loadtest_%' OR name LIKE 'Artillery%'`), исключающих случайное удаление реальных записей.
- Проверка счетчиков до и после удаления через предварительный `SELECT count(*)`.
