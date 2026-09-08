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
     - **Каноническое решение:** устранение параллелизма на клиенте через **Frontend Singleton Refresh Promise** (`http.ts`) + Web Locks API (`navigator.locks` между вкладками). Это сохраняет строгий Zero-Trust на бэкенде (мгновенная инвалидация и жесткий Token Reuse Detection).
     - **Критический Security Trade-off:** зафиксирована опасность Backend Grace Period (Leeway Window) — в течение этого окна украденный токен также принимается сервером, ослабляя защиту именно в момент наивысшей вероятности перехвата. Grace Period допустим строго как fallback для нативных мобильных клиентов с окном не более 2-5 секунд и фингерпринтингом IP/User-Agent.
     - Разработан Concurrency-тест на базе `CountDownLatch(threadCount)` и `CompletableFuture`.

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

7. **Комплексный сьют сквозного E2E CRUD тестирования в Artillery (`artillery.yml` + `processor.js`)**:
   - Реализована полная конфигурация нагрузочного и сквозного CRUD-тестирования для боевого сервера `https://zhanfinance.fly.dev/api`.
   - Включает 4 сценария:
     1. `Public Endpoints` (вес 5): Actuator Health, список услуг, подсветка услуг, проверка доступности email, отправка лид-формы `ContactRequest`.
     2. `Admin Full CRUD` (вес 40): Вход администратора, проверка сессии (`/auth/me`, `/users/me`), сбор аналитики дашборда и финансов, CRUD задач CRM с комментариями и аудитом, пайплайны, клиенты, сотрудники, CRUD меток (`labels`), календарь событий, выставленные счета, документы, глобальный поиск, уведомления, чат-контакты, экспорт задач, заявки и курсы LMS.
     3. `Employee Flow` (вес 30): Генерация динамических учетных данных сотрудника через `processor.js`, регистрация (статус `PENDING`), вход администратора для подтверждения регистрации через `/v1/admin/employees/{id}/approve`, последующий вход сотрудника и исполнение рабочего процесса.
     4. `Client Flow` (вес 25): Генерация учетных данных через `processor.js`, регистрация клиента (авто-активация `APPROVED`), вход клиента, просмотр персонализированного дашборда, задач, календаря, счетов и создание заявки на услугу через `/v1/crm/tasks/request`.
   - Исправлена совместимость со спецификацией Artillery v2:
     - Создан `processor.js` с универсальной сигнатурой контекста (`context.vars.empEmail`, `context.vars.cliEmail`), исключающий зависимость от capture из ответа регистрации.
     - Параметр `maxVusers: 10` вынесен на глобальный уровень `config`.
     - Блок `ensure` приведен к формату Artillery v2 (`p95: 3000`, `maxErrorRate: 1`).
     - Нестандартный `hasProperty` заменен на связку `statusCode: 200` + `contentType: json` с активацией плагина `expect: {}`.
     - Добавлен хук `extractPendingEmpId` в `processor.js` (через `afterResponse`), сопоставляющий `empEmail` конкретного виртуального пользователя со списком pending-заявок. Это полностью исключает race condition при параллельном исполнении (когда два VU брали первого `$.data[0].id` и один получал 404/null).
     - Успешно верифицирован соло-прогон `artillery run --solo` с кодом возврата 0 и 100% успешных проверок.

8. **Боевой IDOR-аудит и результаты нагрузочного тестирования API (`tests/e2e/idor-live.mjs`)**:
   - **IDOR Live Security Test**:
     - Разработан и исполнен автоматизированный сьют `tests/e2e/idor-live.mjs` (21 проверка матриц RBAC/ABAC на боевом проде `https://zhanfinance.fly.dev/api`).
     - Результат: 15 тестов пройдены, 6 выявили критические уязвимости и дефекты:
       1. `[CRITICAL BUG]` Мутация чужих инвойсов клиентом: `PUT /v1/billing/invoices/{id}` возвращает 200 вместо 403. Клиент имеет возможность менять параметры счета.
       2. `[HIGH BUG]` Нарушение роли ADVISOR в CRM: `PUT /v1/crm/tasks/{id}` возвращает 200 вместо 403. Консультант имеет права на изменение задач в `CrmAccessService.canUpdateTaskDetails`.
       3. `[HIGH BUG]` Нарушение роли ADVISOR в Документах: `DELETE /v1/documents/{id}` возвращает 200 вместо 403. Консультант может удалять чужие документы в `DocumentAccessService.canWrite`.
       4. `[MEDIUM BUG]` Ошибка рендеринга PDF инвойса: `GET /v1/billing/invoices/{id}/pdf` падает с HTTP 500 (`PdfGeneratorService: Font file arial.ttf not found in resources`).
   - **Архитектурный инсайт по Rate Limiting (`AuthRateLimitFilter`)**:
     - Жесткий лимит Bucket4j (10 req/min на IP для `/api/v1/auth/**` и 5 req/min для `/check-email`) корректно защищает прод от брутфорса, но требует использования предварительной аутентификации и токен-кеширования (`beforeScenario` + `beforeRequest: attachAuthHeader`) при проведении конкурентных нагрузочных тестов с одного IP-адреса.

9. **Анализ инцидентов продакшена (Rate Limiter 429, Telegram Bot Lead, JVM Metaspace Alert)**:
   - **Инцидент 1: Блокировка входа администратора со статусом HTTP 429**:
     - *Симптомы*: При попытке входа в панель администратора через браузер появилось всплывающее уведомление «Request failed with status 429». Спустя 6-10 секунд повторный вход прошел успешно.
     - *Корневая причина*: Запуск Artillery-тестов производился с того же публичного IP-адреса, что и сессия администратора. Запросы тестового раннера исчерпали доступные 10 токенов в корзине IP-адреса (`Bandwidth.classic(10, Refill.greedy(10, Duration.ofMinutes(1)))`).
     - *Поведение системы*: Лимитер отработал штатно по спецификации fail-closed, заблокировав превышающие запросы. Механизм `Refill.greedy` плавно восстановил 1 токен через 6 секунд, восстановив доступ без перезапуска сервиса.
   - **Инцидент 2: Боевая доставка лида в Telegram (`zhfbot`)**:
     - *Событие*: В Telegram поступило уведомление «Новый лид: Artillery Test, Телефон: +77000000000, Email: artillery@test.com».
     - *Причина*: Сценарий `Public Endpoints` протестировал эндпоинт `POST /v1/contact-requests`. Сервис `ContactRequestService` асинхронно передал задачу в `TelegramNotifierService`, подтвердив полную работоспособность интеграции с Telegram Bot API на проде под нагрузкой.
   - **Инцидент 3: Срабатывание алерта Grafana `metaspace-near-limit`**:
     - *Событие*: Алерт `metaspace-near-limit` перешел в состояние Firing (`Value: 126.38 MB`). Описание: «Metaspace используется на 126.4MB, лимит -XX:MaxMetaspaceSize=128m».
     - *Анализ JVM*:
       - Запрос метрик напрямую из Spring Actuator (`/actuator/metrics/jvm.memory.used?tag=id:Metaspace` и `jvm.memory.max`): текущее потребление составляет **126.5 MB**, реальный физический лимит на ноде — **160 MB** (79% заполнения).
       - Причина скачка: Первый сквозной прогон всех модулей (CRM, Invoices, Documents, Calendar, LMS, Analytics) вызвал массовую подгрузку системных классов, генерацию динамических CGLIB/ByteBuddy-прокси для транзакций и безопасности, а также прогрев рефлексии Jackson и Thymeleaf.
       - Динамика: Metaspace вышел на стабильное плато (классы загружаются однократно).
       - Устранение риска: В `fly.toml` прописан флаг `JAVA_TOOL_OPTIONS = "-XX:MaxMetaspaceSize=256m"`. На запущенной машине действовал предыдущий лимит 160m. При следующем рестарте/деплое лимит расширится до 256m, а порог алерта в Grafana подлежит калибровке до 220 MB.

10. **Сквозные Пользовательские Сценарии в Реальном Браузере (Playwright Authenticated Journeys)**:
    - Разработан и исполнен сьют `tests/e2e/authenticated-journeys-live.mjs` на базе Playwright (headless Chrome) против боевого интерфейса на GitHub Pages и API на Fly.io.
    - **Результат: 17 из 17 проверок успешно пройдены (100% PASS)**:
      1. **Administrator Journey (8 проверок)**: Вход через UI форму логина -> редирект в `/admin` -> проверка рендера виджетов дашборда -> Канбан задач CRM (`/admin/tasks`) -> Справочник клиентов (`/admin/clients`) -> Список сотрудников (`/admin/employees`) -> Воронка лидов (`/admin/leads`) -> Таблица счетов (`/admin/invoices`) -> Журнал аудита (`/admin/audit-logs`) -> Выход.
      2. **Employee Journey (5 проверок)**: Вход сотрудника через UI форму -> редирект в `/employee` -> Доска назначенных задач (`/employee/tasks`) -> Закрепленные клиенты (`/employee/clients`) -> Файловое хранилище документов (`/employee/documents`) -> Рабочий календарь (`/employee/calendar`) -> Выход.
      3. **Client Journey (4 проверки)**: Вход клиента через UI форму -> автоматическая обработка Bucket4j rate-limit (задержка и повторный клик при 429 на едином тестовом IP) -> редирект в `/client` -> Документы клиента (`/client/documents`) -> Каталог доступных услуг (`/client/services`) -> Бухгалтерский календарь (`/client/calendar`) -> Выход.
    - Мастер-раннер `tests/run-all-tests.mjs` обновлен и включает запуск сквозных пользовательских путей и сьюта IDOR-безопасности.
