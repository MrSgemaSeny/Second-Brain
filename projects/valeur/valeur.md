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

## Архитектурные риски и долг (Tech Debt)
- **OLTP Аналитика:** На данный момент агрегация аналитики происходит синхронно запросами в OLTP БД. С ростом данных это вызовет деградацию производительности. Требуется (в Roadmap) выделить `analytics-service` с асинхронным сбором метрик через брокер сообщений (Kafka/Rabbit) в OLAP.

## Roadmap
- **Фаза 1-5** — Done: Identity, vacancy, application, ai-service, api-gateway. Мультитенантность, JWT rotation.
- **Фаза 6** — Done: Docker-compose полный, Dockerfiles для всех сервисов.
- **Фаза 7** — Done: UserController, TenantController. Frontend на нативный fetch, TanStack Query v5, Tailwind v4, моки удалены.
- **Фаза 8** — In Progress: Frontend core. Авторизация (login/register/refresh). Страницы вакансий для кандидата и компании. Подача отклика. Базовый дашборд по ролям.
- **Фаза 9** — Planned: AI интеграция. Генерация саммари резюме через ai-service. Rate limit UI. Трекинг использования.
- **Фаза 10** — Planned: Polish + Security. Фиксы из аудитов. Privacy Policy. Валидация секретов.
- **Фаза 11** — Planned: Deploy. Fly.io или аналог. CI/CD через GitHub Actions. ENV management.
- **Фаза 12** — Planned: Real users. Онбординг первого тенанта. Мониторинг. Feedback loop.
