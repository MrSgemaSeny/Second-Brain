# Журнал: MeDev
Дата: 2026-09-09

## Сквозной аудит маршрутизации и генерация сьюта нагрузочного тестирования (Artillery)

### 1. Выполненные действия
- Выполнен полный статический аудит эндпоинтов всех Spring Boot контроллеров модуля `backend/src/main/java/com/medev`.
- Сверен контракт путей, HTTP-методов, DTO и кодов состояния:
  - `ResumeController`: подтверждены эндпоинты `/v1/resume/generate/{template}` (PDF) и `/v1/resume/html/{template}` (HTML) с query-параметрами `preview` и `singlePage`.
  - `AiController`: подтвержден эндпоинт `/v1/ai/quota` (вместо `/usage`) и синхронный характер `/v1/ai/generate/summary` (не SSE, produces `application/json`).
  - `GitHubController`: подтверждено разделение на `/v1/github/fetch` (чтение репозиториев) и `/v1/github/import` (импорт в проекты).
  - `AdminController`: подтвержден эндпоинт `/v1/admin/audit` (вместо `/audit-logs`) и дашборд `/v1/admin/dashboard` с метрикой `totalAiTokensUsedToday`.
  - `JobApplicationController`: подтвержден метод `PUT /v1/tracker/applications/{id}` (вместо `PATCH`) и коды 201 Created при создании и 204 No Content при удалении.
- Разработана и записана конфигурация `artillery.yml` для прогрева Metaspace (Warmup 30s) и стабильной смоук-нагрузки (Smoke 60s, maxVusers: 10).
- Разработан и валидирован скрипт `processor.js` с пулом токенов в памяти (защита от Bucket4j `AuthRateLimiter` 10 req/15min) и безопасной экстракцией ID для гарантированного `DELETE` тестовых данных.
- Проведен первый боевой прогон: выявлены и устранены различия в авторизации эндпоинта `/actuator/metrics` (требует ROLE_ADMIN) и оптимизировано распределение токенов сьюта (`suite-level auth`).
- Запущен контрольный прогон Artillery по боевому серверу Render.

### 2. Затронутые файлы
- `artillery.yml`
- `processor.js`
- `artillery.env.example`
