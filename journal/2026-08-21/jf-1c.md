# JF-1C — 2026-08-21

## Сессия: Pre-release audit запущен

### Контекст
После инцидента с management.server.port (падение бэкенда из-за Hibernate duplicate listeners)
и security audit от 2026-08-18, принято решение провести полный pre-release audit перед первым
официальным релизом.

### Запущен Teamwork audit
- Команда агентов запущена через /teamwork-preview
- Conversation ID: 890070b3-4342-43ed-b345-888805fe9b1c
- Ветка: audit/pre-release (создаётся командой)
- Фаза 1 (audit-only): отчёт с severity-метками по 7 направлениям
- Фаза 2 (remediation): после checkpoint и согласования приоритетов

### Области аудита
1. Known issues (sort order, avatars, WebSocket race)
2. Security (JWT leak, IDOR, rate limit scope, Swagger в prod, audit triggers)
3. Stability (N+1, unbound collections, Caffeine eviction, cache invalidation)
4. Data/Migrations (Flyway chain reproducibility, seeder idempotency)
5. Backend modules (14 модулей — unhandled exceptions, null safety, @Transactional)
6. Frontend (React Query keys, dnd-kit race, i18next hardcoded strings)
7. CI/CD (test coverage, deploy блокируется на fail)

### Ожидаемый результат фазы 1
Единый markdown отчёт: находка → severity → модуль → root cause → proposed fix → файлы

### Инцидент дня (закрыт)
management.server.port=8081 → Spring создаёт 2 WebApplicationContext →
Hibernate 7 дублирует event listeners → Application run failed → 502 + CORS.
Hotfix: вернули 8080. Задокументировано в incident-02, ADR-008.

### ADR-008 создан
Вектор совместимости: Chrome 109 / Firefox 115, full browser matrix,
исправлены логические ошибки (Tailwind v4 Lightning CSS, prefers-reduced-motion,
OAuth redirect vs popup).
