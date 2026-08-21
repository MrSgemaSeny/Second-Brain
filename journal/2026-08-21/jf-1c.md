# JF-1C — 2026-08-21

## Сессия: Pre-release audit запущен

### Контекст
После инцидента с management.server.port (падение бэкенда из-за Hibernate duplicate listeners)
и security audit от 2026-08-18, принято решение провести полный pre-release audit перед первым
официальным релизом.

### Запущен Teamwork audit
- Команда агентов запущена через /teamwork-preview
- Conversation ID: 890070b3-4342-43ed-b345-888805fe9b1c
- Ветка: audit/pre-release
- Фаза 1 (audit-only): отчёт с severity-метками по 7 направлениям
- Фаза 2 (remediation): после checkpoint и согласования приоритетов

### Области аудита
1. Known issues (sort order, avatars, WebSocket race)
2. Security (JWT leak, IDOR, rate limit scope, Swagger в prod, audit triggers)
3. Stability (N+1, unbound collections, Caffeine eviction, cache invalidation)
4. Data/Migrations (Flyway chain reproducibility, seeder idempotency)
5. Backend modules (14 модулей — unhandled exceptions, null safety, @Transactional)
6. Frontend (React Query keys, dnd-kit race, i18next hardcoded strings)
7. CI/CD (test coverage, deploy блокируется на fail)

### Инцидент дня (закрыт)
management.server.port=8081 → Spring создаёт 2 WebApplicationContext →
Hibernate 7 дублирует event listeners → Application run failed → 502 + CORS.
Hotfix: вернули 8080. Задокументировано в incident-02, ADR-008.

### ADR-008 создан
Вектор совместимости: Chrome 109 / Firefox 115, full browser matrix,
исправлены логические ошибки (Tailwind v4 Lightning CSS, prefers-reduced-motion,
OAuth redirect vs popup).

### Phase 1 Pre-Release Audit Завершён — Итоги и Находки
- Полный сводный отчёт: `.agents/teamwork_preview_orchestrator_1/audit_report.md`
- Проверено 4 параллельными потоками subagents:
  1. Stream 1 (Security R1.2): 0 критических уязвимостей. JWT в памяти, /uploads закрыты фильтром, Swagger отключен в prod, Bucket4j изолирован по IP, IDOR проверен на всех 30 контроллерах (22 с параметрами защищены), audit triggers в БД активны.
  2. Stream 2 (Known Issues R1.1 & Stability/Memory R1.3):
     - LMS sort order [WARNING]: коллизия orderIndex=0 в CourseService.java:117 + отсутствие tiebreaker в ChapterRepository.java:11.
     - Avatar 404 [CRITICAL]: FileDownloadController.java:48 передает "avatars/" + storageKey в DatabaseStorageService.java:118, где ключ в stored_files сохранен без префикса.
     - WebSocket teardown race [WARNING]: unmount / visibility change вызывает deactivate() во время in-flight SockJS handshake в ChatNotificationContext.tsx:36.
     - N+1 queries [CRITICAL]: обход каталога курсов (1+N+NM), кураторы (1+N), документы (1+3N), контакты чата (1+2N).
     - Unbounded queries [CRITICAL]: AuditLogController.java:26, Notifications, Documents, Invoices, Subscriptions без пагинации; fetch join коллекции в TaskSpecification.java:36 вызывает in-memory pagination в Hibernate.
     - Missing @CacheEvict [WARNING]: PipelineController.java:45-85 (stage CRUD) и AdminService.java:72-140 (сотрудники).
  3. Stream 3 (Data/Migrations R1.4 & 14 Backend Modules R1.5):
     - Clean DB migration blocker [CRITICAL]: V107 вставляет NULL в courses.created_by (NOT NULL constraint).
     - Missing @Transactional [CRITICAL]: TaskService.requestTask и AdminService mutations (demote, toggle, approve, reject, createLearner) — потеря audit events.
     - Masked 500 errors [WARNING]: ResponseStatusException не обрабатывается в GlobalExceptionHandler.
     - NPE hazards [WARNING]: DashboardService.java:74 (null lostReason) и SubscriptionService.java:95 (null endsAt).
     - Seeder architecture [WARNING]: DatabaseMigrationRunner дублирует DDL/DML; OfficialDocumentTemplateSeeder удаляет шаблоны при старте.
  4. Stream 4 (Frontend R1.6 & Tests/CI-CD R1.7):
     - React Query invalidation [WARNING]: direct API calls в TaskPoolPage.tsx:90 и TaskDetailsModal.tsx:155-348 обходят инвалидацию списков; TaskDetailsModal вызывает window.location.reload().
     - dnd-kit Kanban [WARNING]: мутация item.stageId in-place в onDragOver + отсутствие lock на rapid drag.
     - i18next [WARNING]: 407 захардкоженных строк в JSX; отсутствует казахский языковой пакет (kk).
     - CI/CD: deploy строго блокируется при падении тестов; отсутствуют PR workflow triggers.

### Independent Review
- Независимый ревьюер: `.agents/reviewer_1/handoff.md`
- Вердикт: APPROVE по всем 5 критериям рубрики.
- Готовность к Фазе 2: Полная, сформирована приоритизированная матрица из 28 находок (P1 CRITICAL -> P2 Known Issues -> P3 WARNING -> P4 INFO).

### Teamwork Quota Exhausted
- Teamwork агент упал по квоте (429 Resource Exhausted) до начала Phase 2.
- Все находки Phase 1 сохранены вручную в `.agents/audit_report.md` на ветке `audit/pre-release`.
- Ветка запушена: `origin/audit/pre-release`.
- Phase 2 (remediation) ведётся вручную по тем же правилам: один баг = один коммит.

### Критический технический долг (из аудита)
- C1: Avatar 404 — prefix mismatch в FileDownloadController vs DatabaseStorageService
- C2: N+1 queries — курсы, документы, чат (1+N+NM паттерн)
- C3: Unbounded queries — AuditLog, Notifications, Invoices без пагинации; TaskSpecification in-memory pagination
- C4: V107 миграция — NULL в courses.created_by → clean DB с нуля не поднимется → нужна V111
- C5: Missing @Transactional на 6 методах (TaskService.requestTask + 5 в AdminService) → потеря audit events
- C6: OfficialDocumentTemplateSeeder удаляет шаблоны при каждом старте → продовые кастомные шаблоны уничтожаются при деплое

### Teamwork Agent Recovery (07:20 UTC / 12:20 +05)
- Квота сбросилась ~через 2 часа (05:20 → 07:20 UTC)
- Victory Auditor 2 (ID: 23defb40) запущен для повторной верификации Phase 1 отчёта
- Phase 2 remediation ожидает вердикт Auditor 2
- Ручные сохранения (audit_report.md, CONTEXT.md, context/projects.md) сделаны во время паузы и остаются актуальными

### Victory Audit 2 — Вердикт: VICTORY CONFIRMED (07:25 UTC / 12:25 +05)
- Phase A (Timeline & Git): Ветка audit/pre-release, 0 измененных файлов в кодовой базе (read-only audit строго соблюден).
- Phase B (Forensic Integrity): Фасадов нет, примененного кода в предложениях нет, 14 модулей бэкенда проверены, все ограничения соблюдены.
- Phase C (Independent Tests & Source Verification):
  - Backend: ./gradlew test --no-daemon (BUILD SUCCESSFUL, exit code 0)
  - Frontend: npx vitest run (16 test files passed, 58/58 tests, exit code 0)
  - Выборочная верификация подтвердила точность номеров строк и файлов для C1-C6, W1-W9, I1-I5.
- Итоговый статус: Phase 1 Pre-Release Audit полностью подтвержден и готов к ревью человеком и началу Phase 2 (Remediation).

### Phase 2 Remediation Launched (12:30 +05)
- Источник плана: `C:\Users\murat\Downloads\jf1c-phase2-remediation-plan.md`
- Governance: Ветка `audit/pre-release`, 1 баг = 1 коммит + регрессионный тест, diff перед коммитом.
- Порядок выполнения Tier 1 (CRITICAL):
  1. C6 — Seeder удаляет шаблоны при каждом старте (`OfficialDocumentTemplateSeeder`)
  2. C5 — Missing @Transactional на 6 методах (`TaskService.requestTask` + 5 методов `AdminService`)
  3. C4 — V107 NULL violation на чистой БД (миграция V111)
  4. C1 — Avatar 404 (prefix mismatch)
  5. C3 — Unbounded queries / отсутствие пагинации + TaskSpecification in-memory pagination
  6. C2 — N+1 queries (LMS -> Documents -> Chat)
- Чекпоинт 1 запланирован после завершения всех 6 CRITICAL.

