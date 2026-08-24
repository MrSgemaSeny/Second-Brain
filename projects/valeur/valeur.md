# Valeur

## Overview
Миграция монолитного приложения Valeur на микросервисную архитектуру (Spring Boot 3 + React FSD).
Цель: Мультитенантная HR-платформа, построенная по строгим инженерным стандартам (Enterprise).

## Архитектура
- **api-gateway:** Spring Cloud Gateway (роутинг, базовая JWT-проверка)
- **identity-service:** Управление юзерами, тенантами (компаниями) и авторизацией.
- **vacancy-service:** Вакансии и просмотры.
- **application-service:** Отклики и уведомления.
- **ai-service:** Генерация саммари резюме через Groq API (LLaMA-3.3-70b).
- **frontend:** React 19 + TypeScript + Vite + FSD + TanStack Query v5.

## Принципы (Brain's Protocol)
1. **Flyway Migrations:** Ручное управление схемой БД запрещено.
2. **Секреты:** Строго через `.env` переменные.
3. **Безопасность:** Встроена в архитектуру (`X-Internal-Token` для общения сервисов, Column-level Multi-tenancy через `TenantContext`).
4. **Запуск:** База данных PostgreSQL 16 поднимается локально через Docker.

## Журнал разработки
*История разработки (лог сессий) перенесена в `journal/YYYY-MM-DD/valeur.md` согласно правилам Brain's Protocol.* 

## Векторы развития и База Знаний
- Стратегия интеграции ИИ (Phase 9): [[ai_strategy.md]] (Анализ алгоритмов HH.ru и гибридного скоринга).

## Архитектурные риски и долг (Tech Debt)
- **OLTP Аналитика:** На данный момент агрегация аналитики происходит синхронно запросами в OLTP БД. С ростом данных это вызовет деградацию производительности. Требуется (в Roadmap) выделить `analytics-service` с асинхронным сбором метрик через брокер сообщений (Kafka/Rabbit) в OLAP.

## Roadmap & Текущий статус (Commercial Enterprise Release — R1–R4 Complete)
- **R1 (AI Resume Scoring & Match - M1 Complete)**: Groq Llama 3.3 70B ATS evaluation prompt, Bucket4j rate limiting, `POST /internal/ai/match-score`, UI `AiMatchBadge` + `AiScoreBreakdownModal`.
- **R2 (Kanban Hiring Board with SLA - M2 Complete)**: Flyway `V4`, `SlaCalculationService` (O(1), `ON_TRACK`, `WARNING`, `BREACHED` `isStale: true`), HTML5 Drag & Drop pipeline across 6 stages, TanStack Query optimistic updates.
- **R3 (Hiring Funnel Analytics & Time-to-Hire - M3 Complete)**: Flyway `V5`, `ApplicationAnalyticsService` (Conversion Rate %, Time-to-Hire, SLA breakdown by vacancy), visual funnel UI.
- **R4 (Talent Pool & Quick Search - M4 Complete)**: Flyway `V6`, private tags/notes CRUD (1-5 ratings), 1-click vacancy invitation with candidate `Notification`.

## Verification Matrix
- **Тесты**: 379/379 tests PASSED (100% Green):
  - `ai-service`: 6/6
  - `identity-service`: 28/28
  - `vacancy-service`: 37/37
  - `application-service`: 102/102
  - `api-gateway`: 1/1
  - `frontend (Vitest)`: 101/101
  - `tests/e2e`: 104/104 (Tiers 1-4 + Adversarial)
- **Next**: Подготовка к деплою (Fly.io / Render) и боевой онбординг первого тенанта.
