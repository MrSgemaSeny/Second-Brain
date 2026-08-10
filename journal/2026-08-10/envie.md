# Envie — 10.08.2026

## Что изменено / добавлено / исправлено

### 1. Серверные порты и конфигурация
- **Порт бэкенда переведён на 8081**:
  - В `application.yml` добавлен `server.port: ${SERVER_PORT:8081}`.
  - В `WebConfig.java` и `application.yml` добавлены правила CORS для порта `http://localhost:5174`.
  - В `frontend/src/shared/api/client.ts` по умолчанию задан адрес `http://localhost:8081/api/v1`.
- **Порт фронтенда переведён на 5174**:
  - В `vite.config.ts` прописан `server.port: 5174`.
- **Динамический роутинг и исправление 404 ошибки**:
  - В `vite.config.ts` задан динамический `base`: `/` для локального сервера разработки и `/Envie/` при сборке в GitHub Actions.
  - `BrowserRouter` в `App.tsx` переведён на `import.meta.env.BASE_URL`, убрав проблему с 404 при входе на `http://localhost:5174/`.

## Проверка и статус
- `npm run build` — успешно (0 ошибок).
- Запущены серверы: Backend (8081) и Frontend (5174).
- Git: закоммичено и отправлено в `origin/master`.
