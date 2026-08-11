# Session Log - MeDev - 2026-08-11

## Добавлено
- Лимит на загрузку PDF (`max-file-size: 10MB`).
- Обработка `MethodArgumentNotValidException` и `MaxUploadSizeExceededException` в `GlobalExceptionHandler`.
- Rate Limiting на AI эндпоинт (Bucket4j - 10 запросов/день для Free, 100 для Pro).
- JSON-структурированное логирование (MDC + logback-spring.xml) для продакшена.
- Настройка `Dockerfile` и `fly.toml` для бэкенда.
- Интеграция CORS.
- Добавлена бизнес-логика (AiContextService, GroqClient proxy) для предотвращения утечки `GROQ_API_KEY`.

## Изменено
- Статус проекта в `projects.md` обновлен до Production-Ready MVP (Фаза 3 завершена).
- Файл `README.md` в репозитории MeDev переписан в соответствии с новым статусом MVP.
- Исправлены и обновлены упавшие юнит-тесты: `GitHubServiceTest`, `ProfileServiceTest`.
- Исправлены проблемы типизации Typescript на фронтенде: `GithubImport.tsx`, `ProjectsSection.tsx`.

## Удалено
- Устаревший кэшированный тест в `GitHubServiceTest`, так как логика кэширования была перемещена.

## Проблемы
- FSD архитектура на фронтенде не полностью соблюдена, а также Code Splitting (`React.lazy`) еще предстоит реализовать в следующей итерации для улучшения производительности.
- Отказались от использования GitHub Actions (по запросу пользователя).
- Axios interceptor для автоматического обновления токенов в фоне требует доработки.

## Тесты
- Юнит тесты бэкенда успешно прошли (BUILD SUCCESSFUL, ./gradlew test).
- Билд фронтенда успешен (tsc -b && vite build).
