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

## Следующий этап (День 2 - Юридический блок):
- Создать страницы `/privacy-policy`, `/terms`, `/refund-policy`, `/cookie-policy`.
- Подключить маршруты в `App.tsx`.
- Заменить заглушки `href="#"` в `Footer.tsx` на рабочие роуты с плавной прокруткой наверх.
- Добавить баннер согласия с куки `CookieConsent.tsx`.
- Добавить согласие на обработку ПДн под формами.
