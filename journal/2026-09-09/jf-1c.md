# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-09

## Отчет по статусу исправления 4 уязвимостей и деплою

### 1. Статус исправления уязвимостей в кодовой базе
Все 4 уязвимости, выявленные в ходе сквозного аудита безопасности, полностью устранены в исходном коде, проверены автоматическими тестами и зафиксированы в ветке `main` (коммиты `a497bda` и `a1fa33c`):

1. **[HIGH] CLIENT может изменить сумму/статус чужого Invoice через PUT**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `CLIENT` удалена из методов `canWrite` и `canCreateFor` в `InvoiceAccessService.java`. Создавать и изменять инвойсы разрешено только `ADMIN` и `EMPLOYEE`. В `InvoiceController.java` и `InvoiceService.java` реализован метод `GET /api/v1/invoices/{id}` с предикатом `assertCanRead` — клиент видит строго свои счета, чужие блокируются с `403 Forbidden`.

2. **[HIGH] ADVISOR может мутировать Task (должен быть Read-Only)**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `ADVISOR` исключена из `CrmAccessService.canUpdateTaskDetails` и из аннотации безопасности `@PreAuthorize` на методе `updateTaskDetails` (`PUT /v1/crm/tasks/{id}`) в `TaskController.java`. Советник переведен в режим строгого Read-Only наблюдения.

3. **[HIGH] ADVISOR может удалить Document (должен быть Read-Only)**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `ADVISOR` исключена из `DocumentAccessService.canWrite` и `canCreateFor`. Советник имеет доступ только на чтение и скачивание документов, удаление и создание блокируются с `403 Forbidden`.

4. **[MEDIUM] PDF Invoice возвращает 500 — отсутствует шрифт arial.ttf**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: В `PdfGeneratorService.java` добавлена безопасная проверка доступности ресурса `/fonts/arial.ttf` в classpath (`getResourceAsStream`). Если шрифт отсутствует в контейнере, генератор не падает с необработанным исключением 500, а использует встроенные шрифты рендерера.

5. **Сопутствующие критические исправления целостности**:
   - LMS Course Deletion: В `CourseService.deleteCourse` добавлена каскадная очистка записей прогресса, зачислений и сертификатов перед удалением сущности курса, что исключило ошибки внешних ключей PostgreSQL (`fk_enrollments_course_id`).
   - LMS Chapter ID: В `CourseService.createChapter` добавлено сохранение через `chapterRepository.save(chapter)` для гарантии возврата сгенерированного ID в API-ответе.
   - HTTP 405 Method Not Allowed: В `GlobalExceptionHandler.java` добавлен обработчик `HttpRequestMethodNotSupportedException` вместо падения в 500.

### 2. Результаты тестов
- Backend: 169 тестов JUnit 5 — 100% green (`./gradlew.bat test --rerun-tasks`).
- Frontend: 74 теста Vitest — 100% green (`npm test -- --run`).
- E2E Lifecycle: 9 сьютов полного цикла (`tests/run-all-e2e.mjs`) пройдены успешно.
- CI/CD: Шаг сборки и тестов `Build and Test` в GitHub Actions завершился успешно.

### 3. Причина статуса "ожидают деплоя" на проде
- Изменения запушены в репозиторий GitHub в ветку `main`.
- Пайплайн автоматического деплоя `.github/workflows/deploy-backend.yml` успешно скомпилировал проект и прогнал все тесты, но упал на шаге `flyctl deploy --remote-only` с ошибкой:
  `ensure depot builder failed (status 403): Your account has overdue invoices. Please update your payment information: https://fly.io/dashboard/orka-best/billing`
- Боевой контейнер на Fly.io пока работает на предыдущем образе. Как только учетная запись на Fly.io будет разблокирована (оплачен счет в биллинге), запуск деплоя автоматически применит готовые фиксы на проде.

### 4. Очистка боевой базы данных от тестовых данных
Выполнена транзакционная очистка базы данных `zhanfinance` на `zhanfinance-db` от мусорных данных нагрузочных (Artillery) и E2E тестов с сохранением реальных данных:
- Удалены тестовые лиды/заявки (`contact_requests`): 125 записей (id >= 16). Сохранено 15 реальных заявок клиентов (id 1..15).
- Удалены тестовые пользователи (`app_users`): 33 записи (e2e.*, artillery.*). Сохранено 16 постоянных учетных записей (id 1..22).
- Удалены связанные тестовые профили (`client_profiles`): 31 запись.
- Удалены тестовые токены (`refresh_tokens`): 22 записи.
- Удалены тестовые уведомления (`notifications`): 32 записи.
- Удалены тестовые сообщения чата (`chat_messages`): 3 записи.
- Удалены тестовые задачи CRM (`tasks`): 11 записей (id >= 35) и 2 записи аудита истории. Сохранено 26 реальных задач (id 1..34).
- Удалены тестовые курсы LMS (`courses`): 4 записи (id 21, 22, 24, 26), 4 главы, 4 урока, 4 прогресса, 4 зачисления, 4 сертификата. Сохранено 4 основных курса.
- Удалены тестовые инвойсы (`invoices`): 3 записи (id 1, 3, 5).
- Документы (`documents`): 27 реальных файлов (id 17..45) сохранены в полном объеме, ни один боевой документ не затронут.

### 5. Архитектурный аудит Email-движка (EmailNotificationService)
Проведена ревизия механизма отправки писем (`EmailNotificationService.java`) и его взаимодействия с транзакциями (`AuthService.register()`, `AdminService.approveEmployee()`, `TaskService`, `ContactRequestService`):
1. **Текущее состояние**:
   - Методы `EmailNotificationService` уже аннотированы `@Async`.
   - Аннотация `@EnableAsync` активна в `AsyncConfig.java` и `ZhanFinanceBackendApplication.java`.
   - Вызовы методов делегируются в общий пул `taskExecutor` (core 4, max 10, queue 200).
2. **Выявленные скрытые риски и архитектурный долг**:
   - **`CallerRunsPolicy`**: При переполнении очереди пула (200 задач) политика `CallerRunsPolicy` перенаправляет выполнение в вызывающий поток Tomcat. Внутри транзакционного метода (`@Transactional`) это приводит к удержанию соединения HikariCP (лимит всего 8 соединений) на время сетевого I/O с SMTP, вызывая каскадный отказ пула соединений БД.
   - **Отсутствие сокет-таймаутов**: В `application.properties` не настроены `connectiontimeout`, `timeout`, `writetimeout` для SMTP, что может блокировать поток на неопределенный срок.
   - **Отсутствие `AFTER_COMMIT`**: Асинхронная отправка инициируется до коммита транзакции в БД. При откате транзакции письмо уже отправлено пользователю; при обращении к ленивым связям возможен `LazyInitializationException`.
   - **Отсутствие изолированного пула (Bulkhead)**: Почта делит общий `taskExecutor` вместо выделенного `mailExecutor`.
3. **Рекомендации**:
   - Использовать Spring Domain Events + `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`.
   - Выделить изолированный `mailExecutor` с политикой сброса `DiscardPolicy` и таймаутами 5000мс на сокеты SMTP.

### 6. Реализация: Устранение рисков и перевод Email-движка на надёжные асинхронные рельсы
Выполнены все 3 шага промышленного харденинга почтового движка:
1. **Таймауты SMTP сокетов**: В `application.properties` заданы `connectiontimeout=5000`, `timeout=5000`, `writetimeout=5000` мс. Зависание почтового провайдера больше не замораживает потоки ОС.
2. **Изолированный пул `mailExecutor` (Bulkhead)**: В `AsyncConfig.java` зарегистрирован выделенный `mailExecutor` (core 2, max 6, queue 200, префикс `mail-worker-`). Опасная `CallerRunsPolicy` заменена на кастомный обработчик с логированием `ERROR` и сбросом задачи (DiscardPolicy). Переполнение почтовой очереди физически не способно затронуть рабочие потоки Tomcat и исчерпать соединения HikariCP к БД.
3. **Транзакционная безопасность (`AFTER_COMMIT`)**:
   - Созданы Spring Events: `SendHtmlEmailEvent`, `SendSimpleEmailEvent`, `EmailAttachment`.
   - Создан слушатель `EmailEventListener` с аннотациями `@Async("mailExecutor")` и `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)`.
   - В `EmailNotificationService` вызовы отправки публикуют события. Физическая передача писем по SMTP выполняется строго ПОСЛЕ успешной фиксации (`COMMIT`) транзакции в PostgreSQL. При откате (`ROLLBACK`) письмо не отправляется. Все HTML-шаблоны и байты вложений резолвятся синхронно в рамках исходного контекста, что исключает ошибки `LazyInitializationException`.
4. **Верификация тестами**:
   - Backend: 196/196 тестов JUnit 5 пройдены успешно (100% green).
   - Frontend: 74/74 тестов Vitest пройдены успешно (100% green).

### 7. Формирование генерального отчёта аудита (Master Audit Report)
- Создан документ `AUDIT_REPORT_JF1C_2026-09-09.md` (версия 2.0), полностью выдержанный по структуре и стандарту `AUDIT_REPORT_MEDEV_2026-09-09.md`.
- Копия размещена в `C:\Users\murat\Downloads\AUDIT_REPORT_JF1C_2026-09-09.md`.
- В отчёт вошли:
  1. Архитектурная топология бэкенда (модульный монолит DDD) и фронтенда (React 19 + FSD).
  2. Полный реестр API бэкенда (30 контроллеров, маршруты `/api/v1/**`, роли, методы).
  3. Реестр маршрутов фронтенда (компоненты, типы защиты, ролевые гварды).
  4. Нагрузочное тестирование Artillery (1 114 запросов, 0 ошибок 5xx, медиана 125.2ms, P95 368.8ms, анализ Incident-03 Metaspace 126.5MB).
  5. Сквозное E2E тестирование (34 API эндпоинта, OWASP заголовки, 3 роли пользователей, 5 бизнес-сьютов: 45/45 PASS).
  6. Аудит безопасности IDOR & RBAC (устранение 4 уязвимостей в счетах, задачах, документах и PDF).
  7. Архитектурный харденинг Email-движка (SMTP сокет-таймауты, `mailExecutor` с DiscardPolicy, Spring Events `AFTER_COMMIT`).
  8. Реестр автотестов (315 проверок: 196 backend + 74 frontend + 45 E2E — 100% PASS).
  9. Отчёт об очистке продакшен базы данных от тестового мусора (125 лидов, 33 юзера, 11 задач, 4 курса удалены; реальные данные 100% сохранены).
  10. Текущий операционный статус деплоя и готовность к продакшену.

### 8. Кристаллизация базы знаний (Second Brain Knowledge Base)
По итогам аудитов MeDev и ZhanFinance в Second Brain зафиксирован и проиндексирован практический knowledge-срез из 6 направлений:
1. `knowledge/sec-production-security-and-hardening.md`: IDOR prevention, RBAC матрица (ADVISOR read-only), Token Bucket (Bucket4j), OWASP security headers (CSP, HSTS), JWT Grace Period (15s), Anti-enumeration (/check-email), SSRF защита (WebScraperService), Adversarial rate limit тесты.
2. `knowledge/qa-production-testing-and-benchmarking.md`: Artillery нагрузочное тестирование (weighted scenarios, capture, ifFalse), Playwright E2E мультиролевые сценарии, JUnit 5 + MockMvc, Vitest + React Testing Library, перекрёстные IDOR тест-кейсы.
3. `knowledge/arch-backend-production-engineering.md`: Spring Boot DDD модульный монолит, Flyway в production (v108 JF-1C, v24 MeDev), Caffeine L1 + Redis L2, генерация PDF (шрифты кириллицы), SSE стриминг для AI, WebSocket STOMP с JWT auth на CONNECT, `@TransactionalEventListener(AFTER_COMMIT)` для email-изоляции, атомарная очистка БД с сохранением FK integrity.
4. `knowledge/frontend-production-architecture-and-resilience.md`: FSD архитектура (все слои), React Query с префиксными ключами (Query Key Factory), Zustand store, дедупликация JWT refresh через синглтон-промис (`refreshPromise`), настройка CSP для iframe превью, `lazyWithRetry` для защиты от 404 ChunkLoadError.
5. `knowledge/observability-production-metrics-and-alerts.md`: Grafana/Prometheus алерты (относительные пороги >85%, задержка `for: 5m`), физика прогресса Metaspace в Spring Boot (CGLIB/Jackson/Hibernate) и эффект плато, безопасность Actuator endpoints.
6. `knowledge/infra-hybrid-cloud-deployment-and-cicd.md`: Fly.io JVM тюнинг и health checks, Render Docker multi-stage деплой, GitHub Pages vs Vercel, GitHub Actions CI/CD и ночные дампы БД через Fly SSH.
Все 6 заметок добавлены в главный реестр `knowledge/knowledge-index.md`.


