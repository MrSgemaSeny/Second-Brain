# Valeur

## Overview
Миграция монолитного приложения CareerHub на микросервисную архитектуру (Spring Boot 3 + React FSD).
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
