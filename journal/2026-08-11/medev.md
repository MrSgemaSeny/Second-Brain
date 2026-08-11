# Session Log - MeDev - 2026-08-11

## Добавлено
- Лимит на загрузку PDF (`max-file-size: 10MB`).
- Обработка `MethodArgumentNotValidException` и `MaxUploadSizeExceededException` в `GlobalExceptionHandler`.
- Rate Limiting на AI эндпоинт (Bucket4j - 10 запросов/день для Free, 100 для Pro).
- JSON-структурированное логирование (MDC + logback-spring.xml) для продакшена.
- Настройка `Dockerfile` и `fly.toml` для бэкенда.
- Интеграция CORS.
- Добавлена бизнес-логика (AiContextService, GroqClient proxy) для предотвращения утечки `GROQ_API_KEY`.
- Внедрен `LlmProvider` интерфейс для абстракции AI-провайдеров.
- Добавлены `Resilience4j` CircuitBreaker и Retry для отказоустойчивости `GroqClient`.
- Промпты вынесены в `resources/prompts/` и загружаются через `PromptLoader`.
- Реализованы эндпоинты `/generate/summary` и `/generate/project-description` (`AiGenerateService`).
- Обработка ошибок в AI-парсере переведена на graceful degradation.
- Интегрирована таблица `ai_usage` и `TokenAccountingService` для мониторинга расхода токенов.
- Добавлен сбор обратной связи от пользователей через `AiEvaluation` и эндпоинт `/api/v1/ai/feedback`.
- Создан тестовый `Golden Dataset` для оценки стабильности ответов ИИ (`AiEvaluationTest`).
- Добавлена интеграция Stripe Checkout на фронтенде (`useCheckout`, `PricingPage`).
- Создан и интегрирован `QuotaWidget` (отображение лимитов AI: 10 для Free, 100 для Pro) в боковую панель.
- Внедрен Soft Upsell Flow (показ модального окна перехода на Pro при достижении лимита запросов 429).

## Изменено
- Статус проекта в `projects.md` обновлен до Production-Ready MVP (Фаза 3 завершена).
- Файл `README.md` в репозитории MeDev переписан в соответствии с новым статусом MVP.
- Исправлены и обновлены упавшие юнит-тесты: `GitHubServiceTest`, `ProfileServiceTest`.
- Исправлены проблемы типизации Typescript на фронтенде: `GithubImport.tsx`, `ProjectsSection.tsx`.
- Кнопки генерации на фронтенде (`AboutSection`, `ProjectsSection`) переведены на синхронные API вызовы со строгим JSON форматом вместо стриминга.
- `useAiGenerate`, `useGenerateSummary` и `useGenerateProjectDescription` теперь перехватывают статус 429 и автоматически открывают `UpsellModal`.

## Удалено
- Устаревший кэшированный тест в `GitHubServiceTest`, так как логика кэширования была перемещена.

## Проблемы
- FSD архитектура на фронтенде не полностью соблюдена, а также Code Splitting (`React.lazy`) еще предстоит реализовать в следующей итерации для улучшения производительности.
- Отказались от использования GitHub Actions (по запросу пользователя).
- Axios interceptor для автоматического обновления токенов в фоне требует доработки.

## Тесты
- Юнит тесты бэкенда успешно прошли (BUILD SUCCESSFUL, ./gradlew test).
- Билд фронтенда успешен (tsc -b && vite build).
- `AiEvaluationTest` добавлен и собирается корректно.
