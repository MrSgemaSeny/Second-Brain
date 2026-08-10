# Мои проекты

## Активные

### MeDev (DevProfile)
- **Репо:** github.com/MrSgemaSeny/MeDev
- **Статус:** Минимальный MVP (Реализован базовый функционал + GitHub OAuth + ИИ-генерация)
- **Стек:** Spring Boot 3 + React 19 + PostgreSQL + Flyway + Redis
- **Что это:** Data-first SaaS платформа для разработчиков. Интеграция с GitHub OAuth, автоматическая сборка профиля, AI-генерация текстов (Groq API, SSE), Dnd-kit редактор, экспорт в PDF.
- **Деплой:** В планах Fly.io (backend), GitHub Pages (frontend)
- **Документация:** `projects/medev/medev.md`

### JF-1C (ZhanFinance)
- **Репо:** github.com/MrSgemaSeny/JF-1C
- **Статус:** Лвл 3→4, готов к первым клиентам
- **Стек:** Spring Boot 3 + React 19 + PostgreSQL + Fly.io
- **Что это:** B2B SaaS CRM для казахстанской бухгалтерской компании
- **Роли:** ADMIN, EMPLOYEE, CLIENT, LEARNER, CURATOR, ADVISOR
- **Модули:** Auth, CRM, Billing, Documents, LMS, Chat, Notifications, Audit
- **Миграции:** V1–V110+
- **Деплой:** backend → Fly.io, frontend → GitHub Pages
- **Документация:** docs/PROJECT_GUIDE.md

### Envie
- **Репо:** github.com/MrSgemaSeny/Envie
- **Статус:** Готовы все Core-модули (Notes, Board, Ideas, Templates, Wallpaper, 3D Dashboard)
- **Стек:** React 18 + Vite + TS + Tailwind v4 + FSD | Java 17 + Spring Boot 3 + PostgreSQL + Gradle
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

### CareerHub v2
- **Статус:** далёкое будущее
- **Что это:** Мультитенантная HR-платформа
- **Старый CareerHub:** Лвл 1, фронтенд-онли

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

### Career Hub v1
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
