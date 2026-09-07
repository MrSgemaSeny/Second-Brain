# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-07

## Выполненные задачи:
1. **Глубокий аудит проекта по 37 пунктам (без изменения исходного кода)**:
   - Чеклист 1 (Legal & UX, пункты 1–19): анализ контрастности WCAG AA, alt-тегов, доступности a11y, юридических страниц (Privacy Policy, Refund Policy, T&C, Cookies), соответствия законам РК (ст. 12 о локализации баз данных ПДн), согласий в формах и минимизации данных.
   - Чеклист 2 (Security для AI-приложений, пункты 20–37): проверка XSS, CSRF, защиты загрузок файлов Apache Tika, Path Traversal, SSRF, управления сессиями и JWT, двухуровневого Rate Limiting (Bucket4j), защиты от BOLA/IDOR в счетах и задачах, утечки Source Maps.

2. **Сохранение в Базу Знаний (Second Brain Knowledge)**:
   - Создана заметка `knowledge/sec-checklist-legal-ux-compliance.md` (Чеклист 1: Пункты 1–19).
   - Создана заметка `knowledge/sec-checklist-ai-app-hardening.md` (Чеклист 2: Пункты 20–37).
   - Обновлен индекс знаний `knowledge/knowledge-index.md` в разделе «Безопасность и Авторизация».

## Ключевые критические точки для исправления в JF-1C:
- **[CRITICAL] Invoice Mutation (Пункт 33-34)**: В `InvoiceAccessService.java` клиент (`CLIENT`) может отправлять `PUT /invoices/{id}` и менять сумму и статус на `PAID`. Требуется исключить `Role.CLIENT` из прав на изменение счетов.
- **[CRITICAL] Source Maps Leak (Пункт 37)**: В `zhan-finance-frontend/vite.config.ts` параметр `build.sourcemap: true` публикует `.map` файлы на GitHub Pages, раскрывая оригинальный TypeScript-код. Требуется отключить или использовать `sourcemap: 'hidden'`.
- **[CRITICAL] Юридические страницы (Пункты 3, 4, 7, 10, 15)**: Создать страницы `/privacy-policy`, `/terms`, `/refund-policy`, `/cookies-policy` и баннер `CookieConsent`.
- **[CRITICAL] Согласие в формах (Пункт 12)**: Добавить дисклеймер согласия на обработку ПДн под кнопками в формах контактов и регистрации.
- **[WARNING] Account Enumeration (Пункт 35)**: Эндпоинт `/v1/auth/check-email` раскрывает факт существования пользователей третьим лицам.
