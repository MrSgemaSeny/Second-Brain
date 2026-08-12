# Session Log - MeDev - 2026-08-11

## Добавлено
- Лимит на загрузку PDF (`max-file-size: 10MB`).
- Обработка `MethodArgumentNotValidException` и `MaxUploadSizeExceededException` в `GlobalExceptionHandler`.
- Устранена проблема с CORS при `401 Unauthorized` (SecurityConfig теперь возвращает JSON 401 для `/v1/**` вместо 302 Redirect).
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
- Интеграция входа и регистрации через **Google OAuth2**.
- Добавлена миграция `V14__add_google_id.sql` (поле `google_id`).
- Рефакторинг `CustomOAuth2UserService` для обработки атрибутов нескольких провайдеров (GitHub и Google) с умным извлечением `email` (`_email`).
- Создана Docker-инфраструктура для локальной разработки: `docker-compose.yml`, `frontend/Dockerfile`.
- Разрешена проблема с Reactor Netty DNS (ошибка 500 для `api.groq.com`), теперь используется `DefaultAddressResolverGroup.INSTANCE`.
- Написан UI компонент `UserProfileDropdown` в сайдбаре с поддержкой светлой/темной темы и локализации, удален хардкод `dark` в HTML.
- Внедрен `GitHubGraphQLService` для получения реальной статистики (коммиты, контрибуции) по GraphQL.
- Статистика GraphQL интегрирована в `AiContextService` и кэшируется в Redis (на 1 час).
- Внедрен `AuthRateLimiter` (Bucket4j) для защиты эндпоинтов `/v1/auth/**` от брутфорса и спама (лимит 20 запросов в минуту по IP).
## Изменено
- Исправлен баг маршрутизации в `BillingController` (убран дублирующийся префикс `/api/v1` на `/v1`).
- Статус проекта в `projects.md` обновлен до Production-Ready MVP (Фаза 4 завершена).
- Файл `README.md` в репозитории MeDev переписан и обновлен новыми переменными среды (Stripe).
- Исправлены и обновлены упавшие юнит-тесты: `GitHubServiceTest`, `ProfileServiceTest`.
- Исправлены проблемы типизации Typescript на фронтенде: `GithubImport.tsx`, `ProjectsSection.tsx`.
- Кнопки генерации на фронтенде (`AboutSection`, `ProjectsSection`) переведены на синхронные API вызовы со строгим JSON форматом вместо стриминга.
- `useAiGenerate`, `useGenerateSummary` и `useGenerateProjectDescription` теперь перехватывают статус 429 и автоматически открывают `UpsellModal`.
- Система антигаллюцинаций для AI: system prompt (`assistant_system_v1.txt`) обновлен жесткими правилами (XML блок `<github_data>`) не выдумывать статистику по GitHub.
- Устранена уязвимость Account Takeover via Pre-Account Creation в `CustomOAuth2UserService` (при привязке OAuth к неподтвержденному аккаунту с паролем старый пароль инвалидируется генерацией случайного хеша).
## Удалено
- Устаревший кэшированный тест в `GitHubServiceTest`, так как логика кэширования была перемещена.

## Проблемы
- FSD архитектура на фронтенде не полностью соблюдена, а также Code Splitting (`React.lazy`) еще предстоит реализовать в следующей итерации для улучшения производительности.
- Отказались от использования GitHub Actions (по запросу пользователя).
- [РЕШЕНО] Axios interceptor успешно подключен во все AI-хуки (`useQuota`, `useGenerateSummary` и т.д.) для автоматического обновления токенов.
- [РЕШЕНО] Стриминг-эндпоинты (`fetch` с SSE) теперь тоже автоматически обновляют истекшие токены, используя интерсептор axios.

## Тесты
- Юнит тесты бэкенда успешно прошли (BUILD SUCCESSFUL, ./gradlew test).
- Билд фронтенда успешен (tsc -b && vite build).
- `AiEvaluationTest` добавлен и собирается корректно.
