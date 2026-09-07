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

## Следующий этап (День 4-6 - Password Reset Flow):
- Разработка безопасного цикла восстановления пароля по email (генерация криптографического токена с хэшированием SHA-256/BCrypt в БД, срок жизни 15 минут, одноразовое использование).
- Бэкенд: `PasswordResetToken` сущность + репозиторий + сервис + почтовый шаблон.
- Фронтенд: страницы `/forgot-password` и `/reset-password?token=...`.
