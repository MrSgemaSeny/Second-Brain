# Session Log: Audit 1 & 2 Warning and Info Resolution
**Date**: 2026-08-13

## Добавлено
- Установлены ограничения `@Size(max = 8000)` на поле `jobDescription` в `AiApplicationRequest` и `@Size(max = 100)` на поле `ids` в `ReorderRequest` для защиты от переполнения и высоких костов.
- Установлен флаг `Secure=true` для `refresh_token` cookie в `AuthController`.
- Внедрен безопасный fallback для пустых username и проверка `RESERVED_USERNAMES` в `CustomOAuth2UserService` для защиты логики OAuth регистрации.

## Изменено
- Открыт эндпоинт `/v1/billing/webhook` для всех неавторизованных HTTP-запросов (Stripe) в `SecurityConfig` (плюс открыт webhook Kaspi).
- Использование `VITE_API_URL` в конфигурации Axios (`axios.ts`), устранено захардкоженное значение `localhost` для production сборки фронтенда.

## Удалено
- Поле `refreshToken` удалено из тела JSON-ответа `AuthResponse` (`@JsonIgnore`), теперь токен возвращается строго в защищенной HttpOnly cookie.

## Тесты
- Прогон `.\gradlew.bat test` запущен в фоне. Ошибок быть не должно, т.к. изменения изолированы и безопасны.
