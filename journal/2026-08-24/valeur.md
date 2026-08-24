# Сессия 2026-08-24 — Инициализация Teamwork-preview для Valeur (Level 2 MVP)

## Статус сессии
- **Запуск мульти-агентной системы**: Запущен `teamwork_preview` (Project Sentinel `715dc8d2-61c9-488f-9c8f-f9ab7540e5da` + Orchestrator `c4637870-160c-463b-84a0-2d79453575e1`).
- **Сформированный артефакт**: `prompt_draft.md` с полными требованиями Level 2 MVP для мультитенантной HR-платформы Valeur.
- **Liveness & Rules Forwarding**: Зафиксированы системный промпт и правила архитектора (`ORIGINAL_REQUEST.md`), подтвержден активный статус Оркестратора.

## Прогресс развертывания (Iteration 1 & 2)
- **Phase 0 (Survey) завершена полностью**: Все интерфейсные контракты, структура бэкенда и фронтенда сведены в единый технический паспорт `PROJECT.md`.
- **Непрерывный трек автоматических E2E тестов**: Запущен агент `test_writer_e2e_1` для написания автоматических интеграционных тестов изоляции данных по `tenant_id` и валидации JWT-токенов.
- **Запуск вехи M1 (Auth & Мультитенантная изоляция)**:
  - Инициализированы 3 исследовательских субагента M1: `Identity RBAC`, `Tenant Security Filter` и `Frontend Auth Flow`.
- Следующий этап: Сбор отчетов обследования M1 -> запуск субагента M1 Implementer -> приемка и верификация M1.

## Завершение работы агента spec_miner_e2e_1 (Phase 0)
- **Артефакт спецификации и матрицы E2E тестов**: Сформирован `spec_matrix.md` и `handoff.md`.
- **Покрытие**:
  - Полный инвентарь требований R1 (Auth & Мультитенантная изоляция), R2 (Управление вакансиями и жизненный цикл), R3 (Профиль кандидата и воркфлоу откликов), R4 (HR & Candidate дашборды).
  - 4-уровневая матрица тестов: Tier 1 (Feature Coverage), Tier 2 (Boundary & Corner Cases), Tier 3 (Cross-Feature Pairwise), Tier 4 (Real-World User Journeys).

## Ключевые требования и архитектура Level 2 MVP
1. **Бэкенд**: Spring Boot 3.3+, Spring Security 6, Spring Data JPA, Flyway, PostgreSQL 16, JWT с ротацией и аннулированием. Изоляция данных на уровне БД (`tenant_id UUID NOT NULL`), экстракция `tenant_id` из JWT claims (`TenantContext`).
2. **Фронтенд**: React 19 + TypeScript + Vite + FSD + Tailwind v4 + TanStack Query v5.
3. **Модули**: Auth (регистрация компании/тенанта, ролевой доступ OWNER, HR_MANAGER, VIEWER), Vacancy (DRAFT → PUBLISHED → CLOSED → ARCHIVED), Candidate (глобальный профиль), Application (статусная машина NEW → IN_REVIEW → INTERVIEW_SCHEDULED → OFFER_SENT → HIRED/REJECTED, внутренние заметки HR), HR & Candidate Dashboards.
4. **Тестирование**: JUnit 5 + Mockito на бэкенде, Vitest на фронтенде.

## Проверки
- Sentinel успешно выполнил переход к Milestone M1. Активен трек написания E2E тестов `test_writer_e2e_1`.
