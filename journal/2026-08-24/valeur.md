# Сессия 2026-08-24 — Инициализация Teamwork-preview для Valeur (Level 2 MVP)

## Статус сессии
- **Запуск мульти-агентной системы**: Запущен `teamwork_preview` (Project Sentinel `715dc8d2-61c9-488f-9c8f-f9ab7540e5da` + Orchestrator `c4637870-160c-463b-84a0-2d79453575e1`).
- **Сформированный артефакт**: `prompt_draft.md` с полными требованиями Level 2 MVP для мультитенантной HR-платформы Valeur.
- **Текущий статус**: Воркер `m1_worker_1` находится в активной фазе кодирования и отладки тестов изоляции `TenantIsolationTest` и RBAC в `identity-service`.

## Прогресс разработки вехи M1
- **E2E Testing Track**: Готов (56 тестов по Tiers 1-4).
- **Кодирование `identity-service`**:
  - `Role.java`: расширен до `OWNER`, `HR_MANAGER`, `VIEWER`, `CANDIDATE`, `COMPANY_ADMIN`.
  - `AuthService.java`: поддержка регистрации тенанта и назначения роли `OWNER`.
  - `SecurityConfig.java`: подключение `@EnableMethodSecurity`.
  - `TenantIsolationTest.java`: написание и отладка проверок изоляции эндпоинтов по ролям.
- **Frontend FSD**: Обновление виджетов `HeaderCompany` и `HeaderApplicant` под новую ролевую модель.

## Ключевые требования и архитектура Level 2 MVP
1. **Бэкенд**: Spring Boot 3.3+, Spring Security 6, Spring Data JPA, Flyway, PostgreSQL 16, JWT с ротацией и аннулированием. Изоляция данных на уровне БД (`tenant_id UUID NOT NULL`), экстракция `tenant_id` из JWT claims (`TenantContext`).
2. **Фронтенд**: React 19 + TypeScript + Vite + FSD + Tailwind v4 + TanStack Query v5.
3. **Модули**: Auth (регистрация компании/тенанта, ролевой доступ OWNER, HR_MANAGER, VIEWER), Vacancy (DRAFT → PUBLISHED → CLOSED → ARCHIVED), Candidate (глобальный профиль), Application (статусная машина NEW → IN_REVIEW → INTERVIEW_SCHEDULED → OFFER_SENT → HIRED/REJECTED, внутренние заметки HR), HR & Candidate Dashboards.
4. **Тестирование**: JUnit 5 + Mockito на бэкенде, Vitest на фронтенде.

## Проверки
- Агент `m1_worker_1` активно доводит тесты и безопасность M1 до зелёного состояния.
