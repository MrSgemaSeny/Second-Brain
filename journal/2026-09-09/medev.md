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
- Проведен боевой прогон Artillery (210 VU, 1066 HTTP-запросов):
  - 932 успешных 2xx ответа (200: 578, 201: 177, 204: 177).
  - Сценарий User Full Flow отработал с созданием, обновлением и обязательным удалением (DELETE) навыков и заявок трекера.
  - Среднее время отклика (mean latency): 1659 мс, медиана: 1495 мс.
  - Выявлено: вызовы `/v1/github/fetch` и `/import` возвращают 500 для пользователей, зарегистрированных по email (не через GitHub OAuth), из-за выброса неперехваченного `RuntimeException("GitHub account is not connected.")`.
  - Выявлено: при одновременных запросах к LLM через Groq API время генерации summary достигает p95 = 4867 мс, а Bucket4j корректно возвращает 429 при превышении квоты 5 req/min.

### 2. Затронутые файлы
- `artillery.yml`
- `processor.js`
- `artillery.env.example`

## Исправление CORS для app.medev.mrsgemaseny.com и падения CookieBanner

### 1. Выполненные действия
- Выявлена причина ошибки CORS при запросах с `https://app.medev.mrsgemaseny.com` на `https://medev-backend.onrender.com/api/v1/auth/refresh`: субдомен `app.medev.mrsgemaseny.com` отсутствовал в дефолтном списке `cors.allowed-origins` конфигураций `application-prod.yml` и `application.yml`.
- Обновлен `SecurityConfig.java`: теперь разрешенные источники разделяются на точные (`setAllowedOrigins`) и шаблоны (`setAllowedOriginPatterns`), предотвращая отказ Spring Security при наличии масок поддоменов.
- Добавлен субдомен `https://app.medev.mrsgemaseny.com` в `cors.allowed-origins` в `application-prod.yml` и `application.yml`.
- Выявлена и устранена причина фронтенд-ошибки `TypeError: Cannot destructure property 'basename' of 'M.useContext(...)' as it is null`: компонент `CookieBanner` был смонтирован в `App.tsx` вне контекста `RouterProvider` (`AppRouter`) и использовал компонент `Link` из `react-router-dom`. Заменен `Link` на нативный тег `<a>`, сделав `CookieBanner` полностью автономным от контекста роутера.

### 2. Затронутые файлы
- `backend/src/main/resources/application-prod.yml`
- `backend/src/main/resources/application.yml`
- `backend/src/main/java/com/medev/shared/security/SecurityConfig.java`
- `frontend/src/shared/ui/CookieBanner.tsx`

