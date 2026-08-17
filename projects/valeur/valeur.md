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
- **17.08.2026:** Завершен Этап 1. `identity-service` переведен на Gradle. Настроен Flyway (`V1__init.sql`). Реализованы мультитенантность (`Tenant`, `User`, `TenantContext`), Stateless JWT Auth (records DTO, Rotation refresh токенов). Внедрен `InternalTokenFilter` для защиты `/internal/**`. Код проверен и запушен в `main`.
- **17.08.2026:** Завершены Этапы 2 и 3. Реализован `api-gateway` (порт 8080) с `JwtAuthenticationFilter` (декодирование JWT, передача Downstream Headers). Реализован `vacancy-service` (порт 8082, схема `vacancy`) с `TenantContextFilter`, миграциями, сущностями `Vacancy` и `VacancyView`. Настроены хуки `.agents/hooks.json` для автоматических коммитов.
- **17.08.2026:** Завершен Этап 4. Реализован `application-service` (порт 8083, схема `application`). Реализованы сущности `Application` и `Notification`, межсервисный вызов `VacancyServiceClient` через `RestClient` для проверки существования вакансии перед откликом, добавлено автоматическое создание нотификаций. Исключены папки `build/` из репозитория.
- **17.08.2026:** Завершен Этап 5. Реализован `ai-service` (порт 8084, схема `ai`). Интегрирован `GroqClient` (llama-3.3-70b) через `RestClient`. Добавлен In-Memory Rate Limiter через `Bucket4j` (10 req/min) и таблица трекинга `ai_usage`. Системный промпт читается из `resources/prompts/summary.txt`. Код успешно скомпилирован и закоммичен.
- **17.08.2026:** Завершен Этап 7. **Бэкенд:** Реализованы `UserController` и `TenantController` для Identity-сервиса (работа с профилями кандидатов и компаний). **Фронтенд:** Инфраструктура полностью переведена на нативный `fetch` (кастомный `apiClient.ts` с перехватом 401 и обновлением токенов), внедрен `@tanstack/react-query` v5 для data fetching, а также интегрирован `Tailwind CSS v4` через `@tailwindcss/vite`. Моки (`db_helper.ts`) удалены. 
