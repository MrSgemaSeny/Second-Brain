- Проверен "InternalTokenFilter" — защита всех эндпоинтов работает корректно через строгую проверку "X-Internal-Token".
- Усилена валидация секретов в SecretValidator: теперь приложение упадет при старте, если JWT_SECRET или INTERNAL_SERVICE_TOKEN будут пустой строкой (ранее пустая строка обходила проверку).
- Добавлен Rate Limiting (Bucket4j) для эндпоинтов /api/auth/login и /api/auth/register в identity-service (защита от брутфорса).
- Написан тест HeaderSanitizationFilterTest для api-gateway, проверяющий срезание служебных заголовков.
- Принято архитектурное решение (Эпик D): Роль ADMIN является глобальной системной ролью. Доступ к /api/admin/vacancies не имеет tenant-scoping, так как глобальные администраторы управляют всей системой.
- Написаны интеграционные тесты для vacancy-service:
  1. TenantIsolationTest: проверяет, что арендатор A не может обновить или удалить вакансию арендатора B.
  2. AdminVacancyControllerSecurityTest: проверяет, что CANDIDATE получает 403 Forbidden при попытке доступа к админским эндпоинтам, а ADMIN получает корректный доступ (404 Not Found при отсутствии вакансии, вместо 401/403).
- Проверена клиентская фильтрация (Эпик B): FeedPage.tsx использует серверный запрос `usePublicVacancies({ q: searchQuery })`, клиентской бизнес-логики больше нет.
- Принято решение (Эпик E): Файловый аплоад (S3) исключен из текущего MVP и перенесен на следующий этап (Phase 12), так как это не критично для безопасности и базового функционала платформы.
- Эпик C (Observability): Actuator и Zipkin (Structured Logging) были оценены, но так как это не блокер для MVP, задача отложена до следующего рефакторинга инфраструктуры. Аудит MVP-фазы закрыт.
- **[Исправлено]** Найденная уязвимость с обходом Rate Limiting (Spoofing заголовка `X-Forwarded-For`) закрыта: `HeaderSanitizationFilter` в `api-gateway` теперь вырезает клиентский `X-Forwarded-For` перед роутингом, благодаря чему SCG корректно проставляет реальный IP адрес подключения, и `identity-service` ограничивает реальные IP.
- **[Исправлено]** В `ApplicationsPage.tsx` удалены дублирующиеся атрибуты `className`, которые вызывали конфликты стилей.
- **Вектор развития AI (Phase 9)**: Проанализированы алгоритмы hh.ru для будущего AI Job Matcher:
  1. Автофильтры (жесткие критерии: ЗП, опыт, локация) — детерминированная логика, отсев до вызова LLM.
  2. Парсинг и скоринг: LLM проверяет плотность ключевых слов и семантическое соответствие опыта.
  3. Штрафы за низкую заполненность профиля (<80%).
  4. Стандартизация должностей (LLM мапит креативные тайтлы кандидата в стандартные рыночные).
- Created new modern iOS-inspired design direction document for Valeur.
- Reviewed and revised valeur_ios_design_direction.md as the Art Director to enforce native iOS minimalism, ensuring no brutalism, and defining strict Tailwind v4 implementation rules.
- **Security Audit Fixes (Phase 10: Polish + Security)**
  - **Секреты:** Во всех 4 сервисах + gateway обновлён `SecretValidator.java`. Теперь требуется длина ключей `JWT_SECRET` и `INTERNAL_SERVICE_TOKEN` >= 32 символа. Обновлён `.env.example`.
  - **Identity Service:** Добавлен rate limit на эндпоинт `/refresh`. Защищено чтение `X-Forwarded-For` — теперь оно доверяется только при наличии `X-Internal-Token` (то есть когда запрос прошел через Gateway).
  - **Tenant Isolation & Roles:** В `TenantContextFilter` (vacancy, application, ai) добавлена строгая проверка на валидные Enum роли (`ADMIN`, `COMPANY_ADMIN`, `CANDIDATE`). Иначе — 401 Unauthorized.
  - **Application Controller:** Добавлена эшелонированная защита `@PreAuthorize("hasRole('COMPANY_ADMIN')")` на методы получения списка кандидатов и обновления статуса отклика, чтобы CANDIDATE не мог даже стучаться туда (помимо защиты на уровне БД).
  - **AI Service:** Добавлена защита от Prompt Injection. Строки `skills` режутся до 500 символов, `experience` — до 2000. В конец промпта добавлено системное предупреждение `[SYSTEM BOUNDARY]`. В `/health` убран провайдер (Groq) для предотвращения Information Disclosure.
  - Все тесты пройдены, код отправлен в GitHub.
- Завершен глобальный редизайн всего frontend приложения в стиле iOS minimalism (bg-surface-card, shadow-sm, border-black/5, rounded-lg/xl, font-bold). Все страницы, компоненты и сущности были переведены с помощью регулярных выражений и скриптов (56 файлов). Тесты и билд проходят успешно. Выполнен git push.
- **[КРИТИЧЕСКИЙ БАГ ИСПРАВЛЕН]** Обнаружена и устранена проблема `403 Forbidden` для аутентифицированных запросов (например, `/api/users/me`). Причиной была автоматическая регистрация `GatewayHeaderFilter` и `TenantContextFilter` в стандартном контейнере сервлетов Tomcat (Spring Boot Behavior), так как фильтры имели аннотацию `@Component`. Это приводило к двойному выполнению фильтра: до Spring Security, где контекст задавался и сразу очищался (из-за блока finally), и внутри Spring Security, где выполнение блокировалось `OncePerRequestFilter`. В `SecurityConfig` всех четырех сервисов добавлены `FilterRegistrationBean` со значением `setEnabled(false)`, чтобы фильтры выполнялись строго только внутри Spring Security Filter Chain.
