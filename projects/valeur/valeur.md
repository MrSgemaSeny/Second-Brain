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

## Roadmap & Текущий статус
- **Фаза 1–6 (Done)**: Микросервисы (identity, vacancy, application, ai, api-gateway), мультитенантность (TenantContext), Docker Compose.
- **Фаза 7 (Done)**: Нативный fetch, TanStack Query v5, Tailwind v4, FSD.
- **Фаза 8 (In Progress)**: Frontend core и миграция страниц (Login/Register, дашборды, вакансии, отклики).
- **Фаза 9 (Planned)**: Интеграция Llama 3.3 70B AI-скоринга и аналитики.
- **Фаза 10 (Planned)**: E2E тестирование, закрытие техдолга и подготовка к деплою.

---

## 🔗 Связи в Базе Знаний (Knowledge Graph)
- **Концепты и стек:** [[wiki/concepts/fsd-architecture|FSD Архитектура]], [[wiki/concepts/spring-security-jwt|Spring Security 6 JWT]], [[knowledge/backend-threadlocal-tenant-context|Multi-Tenancy TenantContext]]
- **Безопасность и шлюз:** [[knowledge/arch-api-gateway-jwt-injection|Gateway JWT Claims]], [[knowledge/sec-internal-service-token|Internal Service Token]]
- **Глобальный контекст:** [[context/projects|Реестр проектов]], [[mem/goals|Цели]], [[mem/history|История вех]]


