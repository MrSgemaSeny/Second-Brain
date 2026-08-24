# Сессия 2026-08-24 — Запуск коммерческого Enterprise-релиза Valeur

## 1. Текущий статус проекта
- **Level 2 MVP**: 100% завершен и верифицирован (64/64 тестов Vitest, 102 бэкенд теста, 55 E2E тестов).
- **Коммерческий Enterprise-релиз**: В активной реализации. Завершены Milestone M1 (AI Smart Match) и Milestone M3 (Hiring Funnel Analytics & Time-to-Hire).

---

## 2. Скоуп и статус киллер-фич

### R1. AI-Powered Resume Scoring & Smart Match (100% Реализован и Верифицирован)
- **AI Service (8084)**:
  - Промпт `prompts/resume_match.txt` для Llama 3.3 70B via Groq с защитой от промпт-инъекций (`[SYSTEM BOUNDARY]`).
  - Метод `calculateMatchScore` в `AiService.java` с парсингом JSON, санитайзингом, контролем длины текста, эвристическим fallback и логированием токенов в `ai_usage`.
  - Эндпоинт `POST /internal/ai/match-score` в `InternalAiController.java`, защищенный `X-Internal-Token`.
  - Тесты `AiServiceTest.java` и `InternalAiControllerTest.java` (6/6 green).
- **Identity Service (8081)**:
  - Эндпоинты `GET /internal/candidates/{id}/profile`, `GET /internal/users/{id}/profile`, `POST /internal/candidates/batch` в `InternalUserController.java`.
  - MockMvc тесты `InternalUserControllerTest.java` (28/28 green).
- **Vacancy Service (8082)**:
  - Эндпоинты `GET /internal/vacancies/{id}/details`, `POST /internal/vacancies/batch` в `InternalVacancyController.java`.
  - MockMvc тесты `InternalVacancyControllerTest.java` (37/37 green).
- **Application Service (8083)**:
  - Миграция `V3__add_application_ai_scores.sql` (таблица `application_ai_scores`, индексы `tenant_id`, `vacancy_id`).
  - JPA-сущность `ApplicationAiScore.java` с `StringListJsonConverter.java` и репозиторий `ApplicationAiScoreRepository.java` с полной изоляцией тенантов.
  - Клиенты `AiServiceClient.java`, `IdentityServiceClient.java`, `VacancyServiceClient.java` с `X-Internal-Token`.
  - Сервис `ApplicationAiScoringService.java` с кэшированием и принудительным пересчетом `force=true`.
  - Эндпоинты `POST /api/applications/{id}/score` и `GET /api/applications/{id}/score` в `ApplicationController.java` с `@PreAuthorize`.
  - Тесты `ApplicationAiScoringServiceTest.java`, `ApplicationControllerTest.java`, `TenantIsolationTest.java` (47/47 green).
- **Frontend (5173)**:
  - FSD-слайс `features/AiResumeScoring`: `aiScoreApi.ts`, `useAiScoring.ts`, `AiMatchBadge.tsx`, `AiScoreBreakdownModal.tsx`, `index.ts`.
  - Интеграция `AiMatchBadge` и `AiScoreBreakdownModal` в таблицу и превью откликов `ApplicationsPage.tsx`.
  - Тесты `AiMatchBadge.test.tsx` и `AiScoreBreakdownModal.test.tsx` (86/86 green, сборка Vite 100% SUCCESS).

### R2. Интерактивная Kanban-доска найма с SLA (100% Реализован)
- `SlaCalculationService` рассчитывает длительность нахождения кандидата на этапе и подсвечивает превышение SLA (`SlaBadge`: green, amber, red).
- Фронтенд-фича `ApplicationsKanban` (`KanbanBoard`, `KanbanColumn`, `KanbanCard`, `SlaBadge`, `useKanbanBoard`) с плавным Drag & Drop, модальным окном заметок и TanStack Query синхронизацией.

### R3. Аналитика воронки найма & Time-to-Hire (100% Реализован и Верифицирован — Milestone M3)
- **Application Service (8083)**:
  - Flyway миграция `V5__add_funnel_analytics.sql`: добавлены колонки `hired_at`, `rejected_at`, `rejection_stage`, выполнен бэкфилл таймстемпов для нанятых/отклоненных откликов, созданы составные индексы `(tenant_id, created_at)`, `(tenant_id, status)`, `(tenant_id, hired_at)`, `(tenant_id, vacancy_id, created_at)`.
  - JPA-сущность `Application.java` обновлена полями `hiredAt`, `rejectedAt`, `rejectionStage`.
  - `ApplicationService.updateStatus` автоматически проставляет `hiredAt = now` при переводе в `HIRED` и `rejectedAt = now, rejectionStage = fromStatus` при переводе в `REJECTED`.
  - `ApplicationAnalyticsService.java`:
    - Поэтапная конверсия (Conversion Rate %) и отсев (Drop-off Rate % / Drop-off count) по стадиям `NEW` → `IN_REVIEW` → `INTERVIEW_SCHEDULED` → `OFFER_SENT` → `HIRED`.
    - Time-to-Hire (TTH): расчет среднего, минимального и максимального количества дней до найма.
    - SLA breakdown: среднее время нахождения в каждом статусе на основе `application_status_history`.
    - Сводка по вакансиям (`vacancies-summary`): сводная аналитика откликов, воронки, конверсии и TTH по каждой вакансии тенанта.
    - Строгая изоляция тенантов `WHERE tenant_id = :tenantId`.
  - `ApplicationAnalyticsController.java`:
    - `GET /api/applications/analytics/funnel` (`vacancyId`, `startDate`, `endDate`)
    - `GET /api/applications/analytics/time-to-hire` (`vacancyId`, `startDate`, `endDate`)
    - `GET /api/applications/analytics/vacancies-summary`
    - Защищены `@PreAuthorize("hasAnyRole('COMPANY_ADMIN', 'OWNER', 'HR_MANAGER', 'VIEWER', 'ADMIN')")`.
  - Тесты: `ApplicationAnalyticsServiceTest.java`, `ApplicationAnalyticsControllerTest.java`, `ApplicationServiceTest.java` (54/54 бэкенд тестов green).
- **Frontend (5173)**:
  - `features/CompanyAnalytics`:
    - `api/analyticsApi.ts`: REST API клиенты для воронки, TTH и сводки по вакансиям.
    - `model/types.ts`: строгие интерфейсы `HiringFunnel`, `TimeToHire`, `StageConversion`, `VacancyAnalyticsSummary`.
    - `model/useAnalytics.ts`: TanStack Query хуки `useHiringFunnel`, `useTimeToHire`, `useVacanciesSummary`, `useAnalytics`.
    - `ui/DashboardOverview.tsx`: Stat cards (Всего откликов, Конверсия в найм %, Средний Time-to-Hire в днях, Активные вакансии).
    - `ui/TimeToHireCard.tsx`: виджет скорости найма с минимумом/максимумом и шкалами SLA по этапам.
    - `ui/DashboardCharts.tsx`: улучшенная воронка с процентами конверсии и отсева, таблица сравнения вакансий компании, графики навыков и вузов.
  - `pages/Company/AnalyticsPage`: полноценный дашборд аналитики с фильтрами по вакансиям и временным интервалам (`30d`, `90d`, `all`).
  - Навигация: добавлен пункт "Аналитика" в боковое меню `CompanySidebar`.
  - Тесты: 101/101 тестов Vitest green, сборка Vite `dist/` без ошибок.

### R4. База талантов (Talent Pool) & Быстрый поиск (В процессе)
- Внутренний банк резюме компании со сквозным поиском по навыкам, опыту, тегам и быстрым приглашением на вакансии.

---

## 3. Результаты тестирования Enterprise Release (Milestones M1 & M3 Verified)
- **`ai-service`**: **6 / 6 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`identity-service`**: **28 / 28 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`vacancy-service`**: **37 / 37 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`application-service`**: **54 / 54 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`frontend` (Vitest)**: **101 / 101 тестов PASSED** (`29 / 29 test files`, 100% green).
- **`frontend` (Vite Build)**: **SUCCESSFUL** (`dist/` собран без ошибок).