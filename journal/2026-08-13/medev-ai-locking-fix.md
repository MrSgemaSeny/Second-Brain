# Обновление MeDev: Устранение гонки при генерации AI-профиля

**Дата**: 2026-08-13
**Проект**: MeDev

## Проблема
Возникала `ObjectOptimisticLockingFailureException` (состояние гонки) при вызове `ProfileService.importParsedResume()`. Проблема была вызвана тем, что Hibernate пытался удалить элементы коллекции (`Experience` и другие) из-за `orphanRemoval=true`, но эти элементы уже были удалены или модифицированы параллельно идущим запросом на обновление. 

## Решение
1. Добавлен метод с пессимистичной блокировкой `findByUserIdForUpdate()` (`@Lock(LockModeType.PESSIMISTIC_WRITE)`) в `ProfileRepository`.
2. В `ProfileService` внедрено использование блокирующего чтения перед обновлением (метод `getProfileEntityForUpdate`), что предотвращает конфликты версий.
3. В `GlobalExceptionHandler` добавлена обработка `OptimisticLockingFailureException` для корректного ответа фронтенду (HTTP 409 Conflict) вместо HTTP 500.

## Статус
Проблема решена, тесты пройдены. Система стала стабильнее.
