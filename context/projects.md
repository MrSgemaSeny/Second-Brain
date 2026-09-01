# Мои проекты
_Обновлено: 2026-08-31_

## Активные и Завершённые Проекты

### 1. MrDevCourses (Educational LMS & Vibe-Coding Platform)
- **Репо:** github.com/MrSgemaSeny/MrDevCourses
- **Проект:** `projects/mrdevcourses/mrdevcourses.md`
- **Мастер Роадмап:** `C:\Users\murat\Downloads\mrdevcourses_roadmap.md` (синхронизирован в `projects/mrdevcourses/mrdevcourses_roadmap.md`)
- **Учебный план курсов:** `mr-developer-curriculum.md`
  - *Курсы Уровня 1 (Базовый)*: Вайбкодинг, тулинг, Git, FSD, Лендинг + Клиентский Маркетплейс.
  - *Курс Уровня 2 (ОСНОВНОЙ КУРС / Флагман Mr Developer)*: Full-Stack (Spring Boot + React + PostgreSQL), RBAC, OAuth 2.0, Three.js 3D (Трекер денег), CRM Kanban + Telegram Bot + CI/CD.
  - *Курсы Уровня 3 (Продвинутый)*: AI Core, Streaming SSE, RAG, WebClient, PII-маскирование, Google SMTP (Pensee).
- **Статус:** **Level 3 — Strong Educational MVP / Pre-Release Pilot** (100% Green: 73 теста Vitest, 236 backend-тестов JUnit, 0 ошибок сборки).
- **Стек:** Java 17 + Spring Boot 3.3.0 + Spring Security 6 + Google OAuth2 + JWT (httpOnly cookie) + PostgreSQL 17 (pgvector, pg_trgm) + Bucket4j + React 19 + TypeScript + Vite + Tailwind v4 + FSD Architecture.
- **Философия менторства Mr Developer:**
  1. *Zero Friction Setup*: Студент устанавливает весь софт (VS Code, Antigravity, Cursor, Git) по прямым ссылкам и пошаговым чеклистам прямо из карточки урока.
  2. *SOS-кнопка «Не получается»*: Мгновенный запрос помощи из любого шага урока с отправкой push-уведомления ментору в Telegram.
  3. *Telegram Dashboard ментора*: Уведомления о ДЗ, SOS-тикеты, stuck detection (3+ дня без активности) и бот-команды `/hw`, `/status`, `/approve`, `/reject`.
  4. *Будущий RAG AI*: Векторный поиск pgvector по конспектам + FAQ база для снятия 60% рутины.
  5. *GitHub-Grade UX*: Чистый, плотный, честный интерфейс уровня GitHub для фокуса на первом живом веб-приложении.
- **Лог:** `journal/YYYY-MM-DD/mrdevcourses.md`

### 2. Zhan Finance (JF-1C) — Enterprise B2B SaaS Platform
- **Репо:** github.com/MrSgemaSeny/JF-1C
- **Проект:** `projects/jf-1c/jf-1c.md`
- **Статус:** **Level 4 — Production-Ready v1.0.0 Released** (545 коммитов, 33 чистых рабочих дня, закрыты все 28 пунктов аудита безопасности).
- **Стек:** Java 17 + Spring Boot 3.4+ + Spring Security 6 + PostgreSQL 17 + Flyway (цепочка миграций V1–V120) + React 19 + TypeScript + FSD + WebSockets (STOMP) + 2FA TOTP + OpenHTMLtoPDF + Caffeine Cache + Bucket4j.
- **Что это:** Комплексная B2B SaaS платформа для бухгалтерского консалтинга и CRM в Казахстане (CRM Kanban, Task Pool, биллинг, документооборот, LMS, защищённые чаты, 6 ролей с Row-Level Security через `CrmAccessService`).
- **Деплой:** Backend на Fly.io (`zhanfinance.fly.dev`), Frontend на GitHub Pages.

### 3. MeDev (DevProfile) — Data-First AI SaaS для Инженеров
- **Репо:** github.com/MrSgemaSeny/MeDev
- **Проект:** `projects/medev/medev.md`
- **Статус:** **Level 4 — Pre-Launch / Private Beta Live** (253 backend теста, 37 frontend тестов, 0 warnings/errors, закрыты все W-1..W-9 уязвимости).
- **Стек:** Spring Boot 3.3.0 + React 19 + PostgreSQL 17 (pgvector) + Flyway (V24) + Redis Valkey 8.1 (L2 Cache) + In-Memory Caffeine (L1 Cache) + Groq LLM (SSE-стриминг) + Flying Saucer + Vitest.
- **Что это:** Платформа единого источника правды для разработчиков. Парсер GitHub API, алгоритм Smart Merge для старых PDF-резюме без галлюцинаций LLM, 6 дизайн-шаблонов резюме, публичное веб-портфолио (`/:username`) и Job Tracker CRM.
- **Деплой:** Production Live: Frontend на Vercel (`me-dev-two.vercel.app`), Backend & DB & Redis на Render (`medev-backend.onrender.com`).

### 4. Valeur — Multi-Tenant Distributed ATS & AI Hiring Platform
- **Репо:** github.com/MrSgemaSeny/Valeur
- **Проект:** `projects/valeur/valeur.md`
- **Статус:** **Level 2–3 — Heavy Production-Ready MVP** (5 микросервисов + Spring Cloud Gateway, Docker Compose).
- **Стек:** Java 17 + Spring Boot 3.3.4 + Spring Cloud Gateway + PostgreSQL 16 (4 схемы БД) + Groq AI (Llama 3.3 70B) + React 19 + TypeScript + FSD + TanStack Query v5.
- **Архитектура:** Микросервисы (`identity-service:8081`, `vacancy-service:8082`, `application-service:8083`, `ai-service:8084`, `api-gateway:8080`). Изоляция данных компаний по `TenantContext` и `tenant_id`, межсервисный токен `X-Internal-Token`.
- **Что это:** ATS-система с интеллектуальным скорингом резюме кандидатов по вакансиям, интерактивной Kanban-доской с SLA-контролем и кадровым резервом (Talent Pool CRM).

### 5. Envie — Personal Headquarters & Knowledge Operating System
- **Репо:** github.com/MrSgemaSeny/Envie
- **Проект:** `projects/envie/envie.md`
- **Статус:** **Level 3 — Personal Production OS** (Все 8 модулей реализованы, sub-15ms отклик).
- **Стек:** Java 17 + Spring Boot 3.4 + PostgreSQL 17 + Flyway (V1–V7) + React 19 + TypeScript + FSD 2.1 + Tailwind v4 + Canvas 2D + Three.js.
- **Что это:** Персональная инженерная операционная среда без облаков и сторонней авторизации. Заметки, плоский Канбан без Jira-бюрократии, инкубатор идей, D3 граф Markdown-шаблонов и 3D Wireframe глобус на HTML5 2D Canvas.

### 6. Air Canvas
- **Статус:** **Завершён**
- **Стек:** Python (FastAPI + MediaPipe) + React (TypeScript + Canvas API) + WebSocket.
- **Что это:** Бесконтактное рисование в воздухе пальцем перед веб-камерой с распознаванием 3D-жестов руки в реальном времени.

### 7. testCinema & Football Bot (Фундаментальный опыт)
- **testCinema**: Дипломная киноплатформа (10 месяцев боевой эксплуатации, Spring Boot + FastAPI ML-сервисы рекомендаций + React FSD).
- **Football Bot**: Telegram-бот на чистом Core Java + Raw JDBC без ORM, заложивший понимание транзакций, пулов соединений и производительности.
- **Что это:** Проект для больших экспериментов — мультитенантность, микросервисы, LLM
- **Когда:** будущее

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
