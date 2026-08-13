# 2026-08-13: Удаление моков и Production-Ready обработка ошибок

## Сделано
По прямому требованию полностью удалена заглушка (Mock Mode) из `StripeService.java`. Проект возвращен в Production-ready состояние:
- Интеграция со Stripe теперь строго требует валидных ключей API.
- В `GlobalExceptionHandler` добавлена обработка `IllegalStateException` (возвращает 400 Bad Request вместо 500 Internal Server Error) на случай попыток повторной подписки для уже PRO-аккаунтов.
