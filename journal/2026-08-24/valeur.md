# Сессия 2026-08-24 — Запуск коммерческого Enterprise-релиза Valeur

## 1. Текущий статус проекта
- **Level 2 MVP**: 100% завершен и верифицирован (64/64 тестов Vitest, 102 бэкенд теста, 55 E2E тестов).
- **Коммерческий Enterprise-релиз**: В активной реализации. Завершен Milestone M1: AI-Powered Resume Scoring & Smart Match.

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

### R3. Аналитика воронки найма & Time-to-Hire (В процессе)
- Конверсия воронки и среднее время закрытия вакансий на основе `application_status_history`.

### R4. База талантов (Talent Pool) & Быстрый поиск (В процессе)
- Внутренний банк резюме компании со сквозным поиском по навыкам, опыту, тегам и быстрым приглашением на вакансии.

---

## 3. Результаты тестирования Enterprise Release (Milestone M1 Verified)
- **`ai-service`**: **6 / 6 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`identity-service`**: **28 / 28 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`vacancy-service`**: **37 / 37 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`application-service`**: **47 / 47 тестов PASSED** (`BUILD SUCCESSFUL`).
- **`frontend` (Vitest)**: **86 / 86 тестов PASSED** (`22 / 22 test files`, 100% green).
- **`frontend` (Vite Build)**: **SUCCESSFUL** (`dist/` собран без ошибок).
- **`tests/e2e`**: **92 / 92 тестов PASSED** (`24 / 24 test suites`, 100% green).