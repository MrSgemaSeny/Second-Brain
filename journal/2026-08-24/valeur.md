# Сессия 2026-08-24 — Инициализация Teamwork-preview для Valeur (Level 2 MVP)

## Статус сессии
- **Запуск мульти-агентной системы**: Запущен `teamwork_preview` (Project Sentinel `715dc8d2-61c9-488f-9c8f-f9ab7540e5da` + Orchestrator `c4637870-160c-463b-84a0-2d79453575e1`).
- **Сформированный артефакт**: `prompt_draft.md` с полными требованиями Level 2 MVP для мультитенантной HR-платформы Valeur.
- **Liveness & Rules Forwarding**: Зафиксированы системный промпт и правила архитектора (`ORIGINAL_REQUEST.md`), подтвержден активный статус Оркестратора.

## Прогресс разработки вехи M1 (Iteration 5)
- **Активное кодирование M1 Worker (`m1_worker_1`)**: Исполнитель выполняет модификацию кода в микросервисах `identity-service`, `vacancy-service` и `application-service` (расширение до ролей `OWNER`, `HR_MANAGER`, `VIEWER`, аннотации `@PreAuthorize`, проверка `TenantContext` и JWT token rotation).
- **Синхронизация E2E-тестового контура (`test_writer_e2e_1`)**: Активно дополняются интеграционные тесты для верификации изоляции данных по `tenant_id` и валидации новых эндпоинтов авторизации.
- **Оркестратор**: Отслеживает жизненный цикл агентов и готовится к приемке и фазе верификации M1.

## Завершение исследовательской фазы M1
- `m1_explorer_1` (Identity RBAC Backend): `Role.java` расширяется до `OWNER`, `HR_MANAGER`, `VIEWER` (с поддержкой `COMPANY_ADMIN`); `@EnableMethodSecurity` добавлена в `SecurityConfig.java`; ротация JWT настроена в `AuthService.register()`.
- `m1_explorer_2` (Tenant Security) & `m1_explorer_3` (Frontend Auth) передали отметки архитектуры.

## Реализация E2E тестового контура (test_writer_e2e_1)
- **Паспорт инфраструктуры**: `TEST_INFRA.md` и `TEST_READY.md` в корне проекта.
- **56 тестов по 4 уровням (Tiers 1-4)**:
  - **Tier 1 (Feature Coverage)**: 23 теста (R1-R4).
  - **Tier 2 (Boundary & Corner Cases)**: 21 тест (Spoofing, Replay Attack, Expired JWT, Deduplication, Unicode Resume).
  - **Tier 3 (Cross-Feature Interaction)**: 8 тестов (Pairwise взаимодействия).
  - **Tier 4 (Real-World Scenarios)**: 4 сквозных пользовательских сценария.

## Ключевые требования и архитектура Level 2 MVP
1. **Бэкенд**: Spring Boot 3.3+, Spring Security 6, Spring Data JPA, Flyway, PostgreSQL 16, JWT с ротацией и аннулированием. Изоляция данных на уровне БД (`tenant_id UUID NOT NULL`), экстракция `tenant_id` из JWT claims (`TenantContext`).
2. **Фронтенд**: React 19 + TypeScript + Vite + FSD + Tailwind v4 + TanStack Query v5.
3. **Модули**: Auth (регистрация компании/тенанта, ролевой доступ OWNER, HR_MANAGER, VIEWER), Vacancy (DRAFT → PUBLISHED → CLOSED → ARCHIVED), Candidate (глобальный профиль), Application (статусная машина NEW → IN_REVIEW → INTERVIEW_SCHEDULED → OFFER_SENT → HIRED/REJECTED, внутренние заметки HR), HR & Candidate Dashboards.
4. **Тестирование**: JUnit 5 + Mockito на бэкенде, Vitest на фронтенде.

## Проверки
- `m1_worker_1` и `test_writer_e2e_1` активно исполняют код. Sentinel завершил очередную проверку жизнеспособности (Liveness check passed).
