# Журнал 2026-08-18

## Что было сделано
1. Исправлены уязвимости: Path Traversal (DatabaseStorageService), IP Spoofing (DocumentController), IDOR (CourseMediaController), DoS (ContactRequestService), Token Race Condition (RefreshTokenService), CSV Injection (ExportController).
2. Код запушен в репозиторий (коммит de7c86f).
3. Интегрирована система хуков (enforce-workflow, reminder) из проекта Valeur.

## Дополнительные фиксы (Phase 2)
1. CRIT-3: Удален JWT токен из URL параметров в JwtAuthenticationFilter.
2. WARN-2: Заголовок Content-Disposition теперь генерируется безопасно через Spring ContentDisposition builder.
3. CRIT-1: Добавлен строгий Rate Limit (10 запросов в час на IP) для загрузки файлов в ApiRateLimitFilter.
4. WARN-1: Actuator перенесен на порт 8081 в application.properties, чтобы скрыть метрики из публичного доступа.
5. CRIT-2: Добавлена валидация MIME-типа через Apache Tika (tika-core) вместо доверия клиентскому заголовку Content-Type.
