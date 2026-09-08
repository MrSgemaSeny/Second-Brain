# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-08

## Выполненные задачи:
1. **Систематизация и сохранение таксономии тестирования в Базе Знаний (Second Brain)**:
   - Создана фундаментальная архитектурная заметка `knowledge/qa-testing-classification-and-strategies.md` с детальным разбором всех уровней и типов тестирования ПО:
     - **Функциональные**: Unit (JUnit/Mockito, Vitest), Integration (@SpringBootTest, Testcontainers, Spring Context), E2E (Playwright, Cypress, RestAssured), Contract (OpenAPI Spec Validator, Pact).
     - **Нагрузочные**: Smoke (базовый healthcheck), Load (пиковые RPS, SLA P95/P99), Stress (точка отказа, Graceful Degradation), Spike (резкие скачки трафика, буферы и лимитеры), Soak/Endurance (долговременная нагрузка, поиск утечек памяти и HikariCP соединений).
     - **Безопасности**: OWASP ZAP / Burp Suite (DAST-сканирование), Auth bypass (матрицы RBAC/ABAC, защита от IDOR/BOLA), Rate limit (проверка блокировки 429 и заголовков Retry-After).
     - **Регрессионные**: Snapshot (контроль контрактов и UI-рендера), Mutation (PITest/Stryker, проверка качества и убиваемости мутантов в тестах).
     - **Специфичные**: Flyway migration (валидация цепочек V1..V121 на чистой БД), Cache invalidation (Caffeine/Redis evicted state), WebSocket (STOMP subscription security, изоляция очередей).
   - Обновлен центральный каталог Zettelkasten `knowledge/knowledge-index.md` — добавлен профильный раздел «Тестирование, QA и Обеспечение Качества».

2. **Комплексное E2E и нагрузочное тестирование боевого сервера (Playwright + Artillery)**:
   - **Artillery Load Testing (Каталог и публичный API `https://zhanfinance.fly.dev`)**:
     - 6. **Конфигурация Artillery Smoke-тестирования (`artillery.yml`)**:
       - Сформирован `artillery.yml` для бережного smoke-тестирования (Warmup 30s @ 2 req/s, Sustained 60s @ 5 req/s, maxVusers 20).
       - Реализовано разделение сценариев: «Public Endpoints» (30% веса) и «Authenticated Flow» (70% веса с логином, захватом `accessToken` cookie и проверкой защищенных эндпоинтов).
       - Настроена валидация ApiResponse<T> через `expect: - hasProperty: "success"` и разбивка метрик через плагин `metrics-by-endpoint`.
       - Конфигурация успешно верифицирована соло-прогоном (`vusers.failed: 0`).
     - 1114 запросов за 56 секунд (~36 RPS).
     - 669 успешных ответов HTTP 200, 443 ответа HTTP 429 (срабатывание Bucket4j защиты при превышении лимита 100 req/min).
     - 0 ошибок 5xx (полная стабильность Spring Boot под конкурентной нагрузкой).
     - Задержки: медиана 125.2 ms, P95 = 368.8 ms, P99 = 415.8 ms.
   - **Artillery Stress Testing (Rate Limiting Boundary Check)**:
     - 30 запросов залпом за 5 секунд на эндпоинт `/api/v1/auth/check-email`.
     - Лимитер отработал точно по спецификации: 10 запросов пропущены (HTTP 200), 20 запросов отсечены со статусом HTTP 429 за 104 ms (без утечек соединений и нагрузки на базу).
   - **Artillery Frontend CDN (GitHub Pages `https://mrsgemaseny.github.io/JF-1C/`)**:
     - 950 запросов за 36 секунд (~32 RPS).
     - Медианная задержка отдачи статики и SPA: 70.1 ms.
   - **Playwright Browser E2E (`tests/e2e/frontend-live.mjs`)**:
     - 16 тестов в реальном браузере Chromium/Chrome на живом сайте.
     - Успешно проверены: заголовок и метатеги, баннер CookieConsent (запись в `localStorage`), переключение тем и языков (RU/KZ/EN), страницы `/services`, `/about`, юридический блок (Privacy, Terms, Refund, Cookie), формы входа, сброса пароля и регистрации.
   - **Live Backend API E2E (`tests/e2e/api-live.mjs`, 34 эндпоинта)**:
     - Проверены Actuator Health (`UP`), каталог услуг, заголовки безопасности (HSTS, CSP, nosniff, frame-options), проверка email, создание заявок (`/api/v1/contact-requests`), fail-closed изоляция 22 защищенных маршрутов (строго 401/403).
     - Устранен недочет в `GlobalExceptionHandler.java`: добавлен обработчик `HttpRequestMethodNotSupportedException` (возвращает статус 405 Method Not Allowed вместо падения в 500 при неподдерживаемых HTTP-методах).
   - Все 191 тест бэкенда (`./gradlew.bat test`) успешно пройдены.

3. **Углубление архитектурных паттернов и тестов (Caffeine TTL Expiry & Bucket4j Spoofing)**:
   - **`knowledge/arch-caffeine-cache.md`**:
     - Разобрана природа Stale Data: различие между явным `@CacheEvict` (мутации) и истечением срока жизни ключа (TTL Expiry).
     - Документирована механика ленивой очистки (Lazy Maintenance) Caffeine: отсутствие фоновых потоков на каждый ключ, очистка при вызовах `get`/`put` и через амортизированный `ForkJoinPool.commonPool()`.
     - Зафиксирован шаблон детерминированного тестирования TTL без `Thread.sleep`: внедрение `Ticker` (`FakeTicker`), метод `cache.cleanUp()`, проверка протухания записи и реального повторного похода в БД (`verify(repository, times(2))`).
   - **`knowledge/arch-tiered-rate-limiting-bucket4j.md`**:
     - Сравнение алгоритмов: Fixed Window Counter (дефект Boundary Burst со всплеском 2x на стыке минут), Sliding Window Log/Counter и Token Bucket (Bucket4j, burst allowance и плавное пополнение `refillIntervally` vs `refillGreedy`).
     - Векторы атак: `X-Forwarded-For` spoofing и эксплуатация `CF-Connecting-IP` до подключения Cloudflare. Описана архитектура безопасного извлечения IP (Rightmost Untrusted IP) с доверием заголовкам только от верифицированных прокси (`getRemoteAddr()`).
     - Тестовые сценарии: тест на исчерпание лимита, тест на попытку обхода через поддельные заголовки IP и тест на пропуск CORS `OPTIONS` pre-flight без расходования токенов.
   - **`knowledge/qa-testing-classification-and-strategies.md`**:
     - Разделы 3.3 (Rate Limit Testing) и 5.2 (Cache Invalidation & TTL Expiry) обновлены с учетом этих архитектурных нюансов.

4. **Углубление тестирования безопасности аудита и Observability**:
   - **`knowledge/db-trigger-audit-logs.md`**:
     - Описано свойство WORM (Write Once, Read Many) для аудит-логов в финансовых системах.
     - Добавлен полный набор триггеров PostgreSQL: `BEFORE UPDATE`, `BEFORE DELETE` (на строку) и `BEFORE TRUNCATE` (на таблицу/оператор).
     - Разработан интеграционный тестовый сьют `AuditLogImmutabilityIntegrationTest` на базе реального PostgreSQL (Testcontainers) для валидации блокировки `UPDATE`, `DELETE`, `TRUNCATE` и ORM `auditLogRepository.delete()`.
     - Зафиксировано требование маскирования чувствительных полей (`AuditEntityListener`) до выполнения `INSERT`.
   - **`knowledge/observability-tracing-mdc-and-structured-logging.md`**:
     - Добавлен раздел «Тестирование Структурированного Логирования и Маскирования».
     - Описан сквозной тест распространения Correlation ID (`X-Request-ID`): входящий HTTP-запрос, помещение в MDC, возвращение в заголовке ответа и гарантированная очистка `MDC.clear()` в блоке `finally`.
     - Описана передача MDC в асинхронные воркеры (`@Async` / `ThreadPoolTaskExecutor`) через `MdcTaskDecorator` и тест сохранения контекста.
     - Описан проброс `X-Request-ID` в исходящие вызовы внешних API (`RestClient` / `WebClient`) через интерцепторы с валидацией через `MockRestServiceServer`.
     - Добавлен тест маскирования паролей, токенов и PII в логах через Logback `ListAppender<ILoggingEvent>`.
   - **`knowledge/qa-testing-classification-and-strategies.md`**:
     - Дополнен подразделами 5.4 (Тестирование неизменяемости Audit-логов) и 5.5 (Тестирование Observability и структурированного логирования).

5. **Тестирование загрузки файлов, IDOR матрица сущностей и визуальная регрессия PDF**:
   - **`knowledge/sec-file-upload-magic-bytes.md`**:
     - Добавлен тестовый сьют `FileUploadSecurityTest`:
       - Тест на отсечение MIME Spoofing / Polyglot Executables (бинарный анализ сигнатур magic bytes `%PDF`, отсечение шелл-скриптов с кодом 400).
       - Тест на Path Traversal в имени файла: санитизация через `FilenameUtils.getName()`, генерация `UUID.randomUUID()` ключа хранения, проверка пути `normalize().startsWith(uploadDir)`.
       - Тест на ограничение размера файла (HTTP 413 Payload Too Large) для защиты от DoS/OOM.
   - **`knowledge/security-idor-rls.md`**:
     - Добавлена исчерпывающая IDOR-матрица доступа для SaaS CRM по ролям (`CLIENT`, `EMPLOYEE`, `ADVISOR`, `ADMIN`) и сущностям (`Task`, `Invoice`, `Document`).
     - Зафиксированы правила изоляции тенантов: клиент видит строго свои задачи и счета, не имеет прав на мутации счетов (`PUT/POST/DELETE -> 403`), консультант `ADVISOR` имеет Read-Only доступ ко всем сущностям без прав на изменение.
     - Описан интеграционный сьют `EntityIdorSecurityTest` с проверкой недоступности чужих ресурсов.
   - **`knowledge/arch-pdf-openhtmltopdf-thymeleaf.md`**:
     - Описана опасность формальных Unit-тестов генерации PDF (`byte[] != null`).
     - Разработана стратегия регрессионного тестирования PDF на двух уровнях:
       1. Семантический и структурный контроль (Apache PDFBox): проверка вместимости счета строго в 1 страницу (`getNumberOfPages() == 1`), извлечение текста через `PDFTextStripper` (реквизиты БИН/суммы), контроль отсутствия артефактов шрифта (`???`, `\uFFFD`, tofu).
       2. Визуальное Snapshot-тестирование: рендеринг страницы PDF в растр через `PDFRenderer.renderImageWithDPI(0, 150)` и попиксельное сравнение (Pixel Diff) с эталонным `gold_invoice.png` (порог < 0.1%).
   - **`knowledge/qa-testing-classification-and-strategies.md`**:
     - Обновлены подразделы 3.2 (Entity IDOR Matrix), 3.4 (File Upload Security Testing) и 4.1 (PDF Generation Regression).

6. **Архитектура целостности СУБД, Concurrency Refresh Token, Graceful Shutdown и Cold Start**:
   - **`knowledge/arch-concurrency-refresh-token-and-race-conditions.md`**:
     - Разобрана природа состояния гонки (Race Condition) при ротации Refresh Token в SPA при одновременных 401 ошибках нескольких параллельных компонентов.
     - Описана опасность ложного срабатывания Token Reuse Detection (разлогин пользователя прямо посреди работы).
     - Двухуровневое решение: фронтенд Singleton Refresh Promise (`http.ts`) + бэкенд Grace Period (Leeway Window 15-30 сек) с возвратом того же токена при параллельных запросах.
     - Разработан Concurrency-тест на базе `CountDownLatch(threadCount)` и `CompletableFuture`, подтверждающий отсутствие False Positive Logout при одновременном ударе 10 потоков в одну наносекунду.
   - **`knowledge/arch-database-constraints-and-integrity-testing.md`**:
     - Развенчан миф о достаточности Spring Bean Validation (`@NotNull`, `@Size`): сервисы, фоновые джобы, батчевые вставки и конкурентные гонки легко обходят валидаторы контроллеров.
     - Зафиксированы 4 критических ограничения PostgreSQL: `NOT NULL` связей, `UNIQUE` индексы против гонок при регистрации, `FOREIGN KEY ON DELETE RESTRICT` против появления записей-сирот (orphaned rows) при удалении клиентов, `CHECK` constraints на положительные суммы счетов.
     - Разработан сьют `DatabaseConstraintIntegrityTest` на реальном PostgreSQL (Testcontainers).
   - **`knowledge/arch-flyio-graceful-shutdown-and-cold-start.md`**:
     - Разбор Graceful Shutdown на Fly.io: `server.shutdown=graceful` и `spring.lifecycle.timeout-per-shutdown-phase=30s`. Тестирование завершения активных in-flight запросов с HTTP 200 при сигнале `SIGTERM` без ошибок 502.
     - Разбор задержки Cold Start при Scale-to-Zero на Fly.io: Firecracker (300-800 мс) + JVM/Spring (12-25 сек) + JIT (1 сек) = 15-30 сек задержки первого запроса.
     - Методология тестирования: отдельный замер `Cold Start TTFB` от `Warm P95/P99`. Keep-Alive пинги через UptimeRobot раз в 4 минуты для исключения засыпания в бизнес-часы.
   - **`knowledge/knowledge-index.md` & `knowledge/qa-testing-classification-and-strategies.md`**:
     - В каталог и QA-руководство добавлены подразделы 2.6 (Graceful Shutdown), 2.7 (Cold Start Latency), 5.6 (Database Constraints) и 5.7 (Concurrency Testing).




