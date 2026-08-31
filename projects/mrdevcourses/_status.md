# Статус проекта: MrDevCourses

**Текущая фаза:** Фаза 5 — B2C Discovery & Course Landing Experience
**Дата обновления:** 2026-08-31
**Текущее состояние:**
- Бэкенд: 100% зелёные интеграционные и E2E тесты (21/21 в AdminSuiteE2ETest).
- Фронтенд: 100% зелёные тесты Vitest (60/60 в 24 сьютах), production сборка без ошибок.
- Архитектура: Модульный монолит, FSD, dual layout RBAC (AdminLayout vs Client Layout), httpOnly JWT, DB-calculated drip-content.
- В работе: Реализация B2C витрины курсов (/courses) и B2C лендинга (/courses/:slug) с аккордеоном модулей, hover-трейлерами и Sticky Card.
