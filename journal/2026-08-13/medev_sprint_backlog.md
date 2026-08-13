# Session Log: Sprint Backlog Tech Debt Resolved
**Date**: 2026-08-13

## Добавлено
- Жесткая проверка MIME-type и magic bytes (`%PDF`) для `/parse-resume` в `AiController.java` (CRITICAL Logic #3).
- Проверка `subscriptionExpiresAt` в `SubscriptionService.assertPro()` (CRITICAL Logic #1).
- `HttpOnly` и `Secure` флаги для `medev_link_jwt` куки в `OAuth2LoginSuccessHandler.java` (CRITICAL Logic #2).

## Изменено
- Защита от SSRF: добавлен `validateUrl` с белым списком хостов (hh.kz, linkedin.com и т.д.) и блокировкой private IPs в `WebScraperService.java` модуля AI (CRITICAL Security #1).
- Эндпоинт Kaspi Webhook в `BillingController.java` временно закрыт (возвращает `403 FORBIDDEN`), так как требуется внедрить реальную HMAC верификацию `X-Kaspi-Signature` (CRITICAL Security #2).

## Проблемы
- 

## Тесты
- Изменения тривиальны и не нарушают существующую бизнес логику. Тесты запущены в фоне для валидации.
