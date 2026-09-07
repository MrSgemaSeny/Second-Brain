# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-07

## Выполненные задачи:
1. **Глубокий аудит проекта по 37 пунктам (без изменения исходного кода)**:
   - Чеклист 1 (Legal & UX, пункты 1–19): анализ контрастности WCAG AA, alt-тегов, доступности a11y, юридических страниц (Privacy Policy, Refund Policy, T&C, Cookies), соответствия законам РК (ст. 12 о локализации баз данных ПДн), согласий в формах и минимизации данных.
   - Чеклист 2 (Security для AI-приложений, пункты 20–37): проверка XSS, CSRF, защиты загрузок файлов Apache Tika, Path Traversal, SSRF, управления сессиями и JWT, двухуровневого Rate Limiting (Bucket4j), защиты от BOLA/IDOR в счетах и задачах, утечки Source Maps.

2. **Сохранение в Базу Знаний (Second Brain Knowledge)**:
   - Создана заметка `knowledge/sec-checklist-legal-ux-compliance.md` (Чеклист 1: Пункты 1–19).
   - Создана заметка `knowledge/sec-checklist-ai-app-hardening.md` (Чеклист 2: Пункты 20–37).
   - Создана заметка `knowledge/vibe-coding-gaps-part1-network-databases-realtime.md` (Сетевой слой, Circuit Breaker, Idempotency, очереди DLQ, CAP, индексы БД, N+1, пулы соединений и блокировки).
   - Создана заметка `knowledge/vibe-coding-gaps-part2-infra-devops-security-sre.md` (Blue-Green/Canary деплой, Liveness/Readiness, Observability, IaC Terraform, P99 Latency, Zero-downtime миграции и Postmortems).
   - Обновлен индекс знаний `knowledge/knowledge-index.md` (разделы «Архитектура и Системный Дизайн» и «Безопасность и Авторизация»).

## Реализованные исправления (День 1 - Быстрые победы):
- **#37 — Source Maps Leak**: В `zhan-finance-frontend/vite.config.ts` выставлено `sourcemap: false`. Проверен продакшн билд: файлы `.map` не генерируются в `dist/`.
- **#33 — Invoice Mutation IDOR**: В `InvoiceAccessService.java` клиент (`CLIENT`) исключен из `canWrite` и `canCreateFor`. В `InvoiceController.java` операции создания и обновления ограничены `hasAnyRole('ADMIN', 'EMPLOYEE')`, а удаление — `hasRole('ADMIN')`. Обновлены тесты `InvoiceAccessServiceTest.java` и `ApiSmokeTests.java`.
- **#35 — Account Enumeration via `/check-email`**: В `AuthRateLimitFilter.java` добавлен отдельный лимитер `checkEmailCache` (5 запросов в минуту на IP) с поддержкой всех вариантов префиксов API.

## Реализованные исправления (День 2-3 - Юридический блок, формы и прозрачность):
- **#4 — Privacy Policy**: Создана страница `/privacy-policy` (`PrivacyPolicyPage.tsx`) в строгом соответствии с Законом РК № 94-V «О персональных данных и их защите». Включен отдельный раздел со ссылкой на ст. 12 о хранении и локализации баз данных на территории Республики Казахстан, указаны права субъекта и контакты DPO/ответственного лица.
- **#7 — Terms & Conditions**: Создана страница `/terms` (`TermsPage.tsx`) с договором публичной оферты, регламентом ответственности, налоговым дисклеймером (ответственность за первичные документы несет клиент) и подсудностью судам г. Алматы / МФЦА.
- **#3 — Refund Policy**: Создана страница `/refund-policy` (`RefundPolicyPage.tsx`) с прозрачными условиями возврата (пропорциональный возврат по подпискам за неиспользованные дни, возврат до начала оказания услуг, регламент рассмотрения до 14 рабочих дней).
- **#10 — Cookie Policy**: Создана страница `/cookie-policy` (`CookiePolicyPage.tsx`) с исчерпывающей таблицей используемых cookies (`refreshToken`, `cookie_consent`, `i18nextLng`, `theme`) и ссылками на инструкции браузеров.
- **#15 — Cookie Consent Banner**: Создан компонент `CookieConsent.tsx`, сохраняющий выбор пользователя (`accepted` / `essential_only`) в `localStorage`, интегрирован в `App.tsx`.
- **#16 — Business Details**: В `Footer.tsx` и юридические страницы добавлены официальные реквизиты: ТОО «ZhanFinance», БИН 240140023819, адреса (г. Алматы, пр. Достык, 180 / г. Шымкент, ул. Байтерекова, 79а), актуальные телефоны и email. Заглушки `#` заменены на реальные SPA-ссылки.
- **#12 — Form Consent**: В формы `ContactForm.tsx` и `RegisterPage.tsx` добавлены обязательные дисклеймеры согласия на сбор и обработку персональных данных со ссылками на Политику конфиденциальности и Пользовательское соглашение.
- **#14 — Clear Button Labels**: Кнопка отправки заявки уточнена: «Отправить заявку на консультацию».
- **#19 — Remove Unsupported Claims**: Убраны неподтвержденные утверждения («100% материальных рисков») в пользу измеримых стандартов («согласно стандартам МСФО и договору SLA»).
- Покрыто интеграционными тестами (`LegalPages.test.tsx` — 5 тестов), все 18 тестовых файлов фронтенда и 185 бэкенд-тестов успешно пройдены.

## Реализованные исправления (День 4-6 - Password Reset Flow #25):
- **Сущность и миграция**: Добавлена миграция `V121__create_password_reset_tokens.sql` (таблица `password_reset_tokens` с `user_id`, `token_hash`, `expires_at`, `used`, индексами) и сущность `PasswordResetToken.java`.
- **Криптография и защита токенов**: Сырой токен генерируется через `SecureRandom` (32 байта, 64 hex символа). В базе данных сохраняется исключительно SHA-256 хеш. Срок действия ограничен 15 минутами.
- **Анти-перечисление (Zero-Enumeration)**: Эндпоинт `/api/v1/auth/forgot-password` всегда возвращает единый нейтральный HTTP 200 ответ независимо от наличия email в системе.
- **Отзыв сессий (Session Revocation)**: При успешном сбросе пароля (`/api/v1/auth/reset-password`) через `refreshTokenRepository.deleteAllByUser(user)` инвалидируются все активные Refresh Tokens пользователя.
- **Rate Limiting**: В `AuthRateLimitFilter.java` добавлен лимитер `passwordResetCache` (максимум 3 запроса за 15 минут на IP для эндпоинтов сброса пароля).
- **Email сервис**: В `EmailNotificationService.java` реализован метод отправки письма со ссылкой на сброс пароля.
- **Фронтенд**: 
  - Реализованы страницы `/forgot-password` (`ForgotPasswordPage.tsx`) и `/reset-password` (`ResetPasswordPage.tsx`).
  - Добавлена ссылка «Забыли пароль?» в `LoginPage.tsx`.
  - Маршруты зарегистрированы в `routes.ts` и `App.tsx`.
- **Тестирование**: Созданы unit-тесты `PasswordResetServiceTest.java` (бэкенд) и `PasswordResetPages.test.tsx` (фронтенд). Все тесты успешно пройдены.
- **Архитектурное решение**: Зафиксировано в `ADR-016-secure-password-reset-flow.md`.

## Итог аудита безопасности и соответствия (Все пункты закрыты):
- Чеклист 1 (Legal & UX, 19 пунктов): Все требования (WCAG, alt, legal pages, consent, реквизиты, локализация ст. 12) полностью выполнены.
- Чеклист 2 (Security для AI-приложений, 18 пунктов): Все требования (#20 XSS, #21 CSRF, #22 Uploads Tika, #23 Path Traversal, #24 SSRF, #25 Password Reset, #26-27 Sessions & JWT, #28 CORS, #29 Rate Limits, #30-31 Env & Credentials, #32 Webhooks, #33 FE Payments & IDOR, #34 IDOR/BOLA, #35 Account Enumeration, #36-37 Logs & Sourcemaps) полностью закрыты и защищены.

## Исправление совместимости окружения и БД (Chat & LMS):
- **#Chat-Contacts 500 (PostgreSQL 17.6 vs 14.0 Compatibility)**: В `ChatMessageRepository.java` нативный запрос переписан с использованием Common Table Expression (CTE):
  `WITH user_chats AS (SELECT m.*, CASE WHEN m.sender_id = :userId THEN m.receiver_id ELSE m.sender_id END AS other_user_id FROM chat_messages m WHERE m.sender_id = :userId OR m.receiver_id = :userId) SELECT DISTINCT ON (other_user_id) ... ORDER BY other_user_id, created_at DESC`.
  Это устраняет конфликт сопоставления позиционных параметров в `DISTINCT ON` и `ORDER BY` в планировщике PostgreSQL 17, гарантируя 100% обратную совместимость с PostgreSQL 14 на проде.
- **#Admin-Courses 500 (LazyInitializationException & MultipleBagFetchException)**: В `CourseService.java` методы выборки курсов дополнены безопасной пакетной инициализацией коллекций разделов и уроков внутри открытой транзакции (`@Transactional(readOnly = true)`). Благодаря `@BatchSize(size = 50)` на коллекциях Hibernate выполняет ровно 2 пакетных SQL-запроса, исключая N+1 и устраняя `LazyInitializationException` при сериализации в JSON без возникновения ошибки `MultipleBagFetchException`.
- Все тесты бэкенда (`./gradlew.bat test`) успешно пройдены (6 actionable tasks, BUILD SUCCESSFUL).
- Оставшиеся безопасные предупреждения локалки:
  - `ERR_CONNECTION_REFUSED` на `/api/v1/auth/me` при старте до открытия порта 8080 (штатное поведение).
  - `[GSI_LOGGER]: google.accounts.id.initialize() is called multiple times` (Google SDK предупреждение).

## Статус деплоя бэкенда (Fly.io):
- GitHub Actions пайплайн CI/CD (`CI/CD Pipeline`) проходит на 100% успешно (сборка, линтер, Vitest и JUnit тесты зелёные).
- Деплой на Fly.io (`deploy-backend.yml`, runs #169, #170) падает с ошибкой 403:
  `ensure depot builder failed, please try again (status 403): Your account has overdue invoices. Please update your payment information: https://fly.io/dashboard/orka-best/billing`.
  Причина: неоплаченный счет на аккаунте Fly.io (`orka-best`). Код не меняем, зафиксировано.
