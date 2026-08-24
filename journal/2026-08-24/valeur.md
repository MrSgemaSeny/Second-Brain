# Сессия 2026-08-24 — Инициализация Teamwork-preview для Valeur (Level 2 MVP)

## Статус сессии
- **Запуск мульти-агентной системы**: Запущен `teamwork_preview` (Project Sentinel `715dc8d2-61c9-488f-9c8f-f9ab7540e5da` + Orchestrator `c4637870-160c-463b-84a0-2d79453575e1`).
- **Сформированный артефакт**: `prompt_draft.md` с полными требованиями Level 2 MVP для мультитенантной HR-платформы Valeur.
- **Liveness & Rules Forwarding**: Зафиксированы системный промпт и правила архитектора (`ORIGINAL_REQUEST.md`), подтвержден активный статус Оркестратора.

## Прогресс развертывания (Iteration 1, 2 & 3)
- **Phase 0 (Survey) завершена полностью**: Все интерфейсные контракты, структура бэкенда и фронтенда сведены в единый технический паспорт `PROJECT.md`.
- **Исследовательская фаза вехи M1 (Auth & Tenant Isolation) завершена**:
  - `m1_explorer_1` (Identity RBAC Backend): Завершил исследование `identity-service`. Подтверждено: `Role.java` расширяется до `OWNER`, `HR_MANAGER`, `VIEWER` (с обратной совместимостью `COMPANY_ADMIN`); `@EnableMethodSecurity` требуется в `SecurityConfig.java`; колонка `users.role` является `VARCHAR(50)`, поэтому DDL-миграция не требуется; ротация JWT настроена, требуется поддержка `OWNER` в `AuthService.register()`.
  - `m1_explorer_2` (Tenant Security) и `m1_explorer_3` (Frontend Auth) завершили сбор отчетов и фиксацию архитектурных решений.
- **Следующий этап**: Синтез отчетов обследования M1 Оркестратором и запуск исполнителей (`M1 Implementers`).

## Ключевые требования и архитектура Level 2 MVP
1. **Бэкенд**: Spring Boot 3.3+, Spring Security 6, Spring Data JPA, Flyway, PostgreSQL 16, JWT с ротацией и аннулированием. Изоляция данных на уровне БД (`tenant_id UUID NOT NULL`), экстракция `tenant_id` из JWT claims (`TenantContext`).
2. **Фронтенд**: React 19 + TypeScript + Vite + FSD + Tailwind v4 + TanStack Query v5.
3. **Модули**: Auth (регистрация компании/тенанта, ролевой доступ OWNER, HR_MANAGER, VIEWER), Vacancy (DRAFT → PUBLISHED → CLOSED → ARCHIVED), Candidate (глобальный профиль), Application (статусная машина NEW → IN_REVIEW → INTERVIEW_SCHEDULED → OFFER_SENT → HIRED/REJECTED, внутренние заметки HR), HR & Candidate Dashboards.
4. **Тестирование**: JUnit 5 + Mockito на бэкенде, Vitest на фронтенде.

## Проверки
- `identity-service`: `gradlew.bat test` прошел успешно (BUILD SUCCESSFUL).
- Отчеты сохранены в `.agents/m1_explorer_1/analysis.md` и `handoff.md`.

