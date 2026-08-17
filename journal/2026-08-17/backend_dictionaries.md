# 2026-08-17 — Mock Purge + Dictionary Backend

## Выполнено

### Backend (identity-service)
- Создана Flyway-миграция V2__add_dictionaries.sql: таблицы hard_skills_dictionary, soft_skills_dictionary в схеме identity
- Создан HardSkillDictionary entity + repo + service + controller
- Создан SoftSkillDictionary entity + repo + service + controller
- Эндпоинты: GET/POST /api/dictionaries/hard-skills, GET/POST /api/dictionaries/soft-skills
- SecurityConfig: /api/dictionaries/** — permitAll (публичный доступ)
- Проверено: GET http://localhost:8080/api/dictionaries/hard-skills возвращает данные из БД

### API Gateway
- Добавлен /api/dictionaries/** в маршрут identity
- JwtAuthenticationFilter: /api/dictionaries — проброс без токена
- Исправлены env var имена: IDENTITY_SERVICE_URL -> SERVICES_IDENTITY_URL и т.д. (align с docker-compose)

### Frontend
- useDictionary.ts: localStorage -> TanStack Query + real apiClient
- HardSkillsManager.tsx: убраны hardcoded данные, подключён backend
- SoftSkillsManager.tsx: убраны hardcoded данные, подключён backend
- Удалены файлы: db_helper.ts, mockTests.json, mockHandlers.ts

## Остатки (не моки, а honest stubs)
- useAnalytics.ts: нет backend endpoint для аналитики (TODO)
- getCompanyStats / getStudentStats: нет endpoint для статистики (TODO)
- HiddenTestModal / useTestSession: нет backend для тестов (TODO)

## Commits
- feat: real dictionaries endpoint in identity-service
- fix: align gateway routes with docker-compose service URLs + expose /api/dictionaries public
