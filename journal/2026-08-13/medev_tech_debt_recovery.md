# Session Log: MeDev Tech Debt Recovery
**Date**: 2026-08-13

## Добавлено
- Успешно прогнаны тесты для ранее модифицированных файлов, которые не были закоммичены из-за прерывания сессии.

## Изменено
- `RateLimitFilter.java` (использование `getRemoteAddr()` для ограничения запросов).
- `application-prod.yml` (настройка `show-details: when_authorized` для actuator).
- `EncryptionUtils.java` (проверка логики AES/GCM).
- Различные мелкие исправления в KaspiPay сервисах и WebScraper сервисах, оставшиеся с предыдущей сессии.

## Проблемы
- Предыдущая сессия ИИ прервалась до того, как успела выполнить коммит и push. Жизненный цикл (lifecycle hook) `check-protocol.ps1` успешно предотвратил потерю работы и заставил агента обработать не закоммиченный код.

## Тесты
- Прогон `.\gradlew.bat test` прошел успешно. `BUILD SUCCESSFUL`. Все 5 задач up-to-date.
