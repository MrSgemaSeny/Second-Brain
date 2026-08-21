# Мои проекты
_Обновлено: 2026-08-11_

## Активные

### MeDev (DevProfile)
- **Репо:** github.com/MrSgemaSeny/MeDev
- **Статус:** Level 3 - Production-Ready MVP (Все Фазы 1-8 Roadmap завершены: Полная генерация профиля через AI, Smart Merge, 6 HTML/PDF шаблонов включая Clean ATS и GitHub Dark с поддержкой A4 Single-Page и Multi-Page режимов, Job Tracker CRM + Kanban, Публичное портфолио с SEO, UX скелетоны, Multi-Template README Generator, 100% Test Coverage: 91 backend + 37 frontend tests, ADR-001..006, полная безопасность). Готов к деплою на Fly.io / GitHub Pages.
- **Стек:** Spring Boot 3.3 + React 19 + PostgreSQL + Flyway (V24) + Redis + Docker + Groq AI (Llama 3.3 70B) + Spring AI + pgvector + Vitest + Testcontainers
- **Что это:** Data-first AI SaaS платформа для разработчиков. Умный парсинг GitHub (Source of Truth) и PDF (Smart Merge), AI-генерация профиля, Kanban-доска (CRM) с автоматическим AI-матчингом вакансий (Scraper с защитой от SSRF и лимитами), рендер 6 дизайн-шаблонов HTML и PDF резюме (включая Clean ATS), публичная страница портфолио (`/:username`) с OpenGraph и Schema.org разметкой, генератор GitHub Profile README.
- **Деплой:** Готов к деплою (backend на Fly.io, frontend на GitHub Pages, локально через docker-compose)
- **Документация:** `docs/ARCHITECTURE.md`, `docs/API_REFERENCE.md`, `docs/DEPLOYMENT.md`, `docs/EPICS.md`, `docs/ADR.md`, `docs/SECURITY_AUDIT.md`

### JF-1C (ZhanFinance)
- **Репо:** github.com/MrSgemaSeny/JF-1C
- **Статус:** Лвл 4 — задеплоен, идут первые клиенты. Phase 7: pre-release audit remediation.
- **Стек:** Spring Boot 4.1 + React 19 (TypeScript) + PostgreSQL + Fly.io + Tailwind v4 + FSD
- **Что это:** B2B SaaS CRM для казахстанской бухгалтерской компании
- **Роли:** ADMIN, EMPLOYEE, CLIENT, LEARNER, CURATOR, ADVISOR
- **Модули:** Auth, CRM, Billing, Documents, LMS, Chat, Notifications, Audit, Search, Calendar, Landing
- **Миграции:** V1–V110 applied (immutable). V111 planned для фикса C4.
- **Деплой:** backend → Fly.io (zhanfinance.fly.dev), frontend → GitHub Pages
- **Текущая ветка:** audit/pre-release
- **CRITICAL долг (Phase 2 remediation):**
  - C6 [DONE]: OfficialDocumentTemplateSeeder idempotency (commit `d336623`)
  - C5 [DONE]: @Transactional на AdminService (commit `ba0caaf`)
  - C4 [IN PROGRESS]: V107 NULL в courses.created_by → миграция V111
  - C1: Avatar 404 — prefix mismatch в FileDownloadController vs DatabaseStorageService
  - C3: Unbounded queries — AuditLog/Notifications/Invoices без пагинации
  - C2: N+1 queries — курсы (1+N+NM), документы (1+3N), чат (1+2N)
- **Audit report:** `.agents/audit_report.md` (28 находок: 6 CRITICAL, 9 WARNING, 5 INFO)



### Envie
- **Репо:** github.com/MrSgemaSeny/Envie
- **Статус:** Готовы все Core-модули (Notes, Board, Ideas, Templates, Wallpaper, 3D Dashboard)
- **Стек:** React 18 (TypeScript) + Vite + Tailwind v4 + FSD | Java 17 + Spring Boot 3 + PostgreSQL + Gradle
- **Что это:** Личный рабочий штаб (Second Brain) — заметки, канбан, идеи, MD-база знаний, обои/видео, 3D Dashboard
- **Деплой:** Frontend: GitHub Pages | Backend: localhost

### Air Canvas
- **Статус:** ЗАВЕРШЕН (Фаза 6 пройдена)
- **Стек:** Python (FastAPI + MediaPipe) + React (TS + Canvas API) + WebSocket
- **Что это:** Рисуешь в воздухе пальцем — линия появляется на экране
- **Жесты:** указательный = рисуем, два пальца = пауза, кулак = очистить
- **Особенности:** Backpressure-синхронизация по WS, 3D-дистанции для инвариантности к ракурсу, сохранение PNG, эффекты (glow, spray).

## В планах

### Склад
- **Статус:** идея
- **Что это:** Проект для больших экспериментов — мультитенантность, микросервисы, LLM
- **Когда:** будущее

### Valeur (ex. Valeur v2)
- **Репо:** github.com/MrSgemaSeny/Valeur
- **Статус:** Level 2 - Pet Project (Начало миграции с монолита на микросервисы)
- **Стек:** Spring Boot 3.3 + React 19 + Spring Cloud Gateway + PostgreSQL 16 + FSD
- **Что это:** Мультитенантная ATS/HR-платформа. Микросервисная архитектура (api-gateway, identity, vacancy, application, ai).
- **Деплой:** локальный docker-compose (PostgreSQL)
- **Документация:** `projects/valeur/valeur.md`

## Архивные / учебные

### Epoch of Schism (Эпоха раскола)
- **Статус:** пауза
- **Стек:** TypeScript + WebGL, ECS+FSM архитектура
- **Что это:** Тактический top-down шутер, 1 миссия

### testCinema (внутри Backend Damir)
- **Статус:** завершён (дипломный проект, 10 месяцев)
- **Стек:** React + FastAPI + Spring Boot + Docker
- **Что это:** Онлайн-кинoплатформа для казахстанского контента с ML-рекомендациями

### Football Bot TG
- **Статус:** завершён (первый серьезный проект)
- **Стек:** Core Java + Raw JDBC + PostgreSQL + Telegram API
- **Что это:** Сложный Telegram-бот с Gacha-экономикой, PvP и кланами

### Backend Damir
- **Статус:** завершён
- **Стек:** Python 3 + FastAPI
- **Что это:** Микросервисы (test_cinema, Insight) для стриминга видео и ML

### BallonDorChat
- **Статус:** завершён
- **Стек:** Java 11/17 + Maven (Uber-JAR) + WebSockets/NIO
- **Что это:** Высоконагруженный чат-сервер реального времени

### Valeur v1
- **Статус:** завершён
- **Стек:** JavaScript + React + FSD
- **Что это:** ATS-система и HR-портал (фронтенд)

### Chat Naturalov Bot
- **Статус:** завершён
- **Стек:** Python 3 + aiogram + SQLite
- **Что это:** Легкий асинхронный Telegram-бот

### Chat Bot Backend
- **Статус:** завершён
- **Стек:** Java + Spring Boot + WebSockets (STOMP) + JWT
- **Что это:** REST API и WebSocket-сервер для реал-тайм чата

### Chat Bot Frontend
- **Статус:** завершён
- **Стек:** React + Vite + sockjs-client
- **Что это:** SPA клиент для Web-чата
