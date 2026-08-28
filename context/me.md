# Кто я
_Обновлено: 2026-08-14_

**Имя:** Мурат Орынбасар
**Роль:** Full-Stack Engineer → Tech Lead / Software Architect
**Уровень (на основе аудита проектов):** Middle / Strong Middle
**Локация:** Шымкент / Алматы, Казахстан
**Email:** muratorynbasar0@gmail.com
**GitHub:** github.com/MrSgemaSeny

## Стек

**Backend:** Java 17, Spring Boot 3, Spring Security, OAuth2, JWT (access + refresh в Redis), JPA/Hibernate,
PostgreSQL, Flyway, Модульный монолит, Caffeine Cache, Rate limiting (Bucket4j), WebFlux/Reactor (параллельные запросы), Resilience4j, Stripe + webhooks, SSE для стриминга AI, WebSocket (STOMP), JSoup (Web Scraping)

**AI & LLM Integration (Advanced):** Spring AI, RAG (Retrieval-Augmented Generation), pgvector, Groq API, AI-driven architecture (Smart Merge, Tool Calling, Structured JSON Generation), Prompt Engineering

**Frontend:** React 19, TypeScript, Vite, Tailwind CSS v4,
Feature-Sliced Design (FSD), React Query, Zustand, Framer Motion, dnd-kit, zod, i18n

**Инфраструктура:** Docker, GitHub Actions, Fly.io, GitHub Pages

**Дополнительно:** Python, FastAPI, MediaPipe

## Философия разработки и менторства (Mindset)

- **Проекты как жизненный путь, а не витрина для рекрутеров.** Код, архитектура и документация — это нарратив, фиксация инженерных решений, рефлексия и история роста.
- **Роль ментора (Mr Developer):** Первый ученик уже проходит практическое обучение. Студент видит перед собой не абстрактного теоретика, а практикующего разработчика, который прошел путь от нуля до Enterprise-архитектуры и готов передать системное мышление.
- **Двойной блог и открытость:** Документирование пути публично (YouTube + Telegram), построение комьюнити сильных инженеров и вайбкодеров.
- **Главный результат:** Осознание того, что любая техническая идея реализуема при правильной декомпозиции и строгих архитектурных стандартах.

## Архитектурные принципы и стандарты качества

- **Модульный монолит на бэкенде** с последующим выделением в микросервисы (DDD/Bounded Contexts).
- **FSD (Feature-Sliced Design) на фронтенде** — всегда (app, pages, widgets, features, entities, shared).
- **DESIGN.md-first подход** — перед реализацией любого UI составляется и согласовывается контракт дизайн-токенов (4 уровня типографики, палитра `#0a0a0c`/`#18181b`, радиусы `2-4px`, отсутствие визуального шума/deslop).
- **Security first & Zero Trust** — IDOR/RLS защита на уровне сервисов, stateless OAuth2/JWT в httpOnly cookies, rate limiting (Bucket4j).
- **Migrations only** — схема БД строго через Flyway `V{N}__` скрипты, запрет ручных правок и `ddl-auto=update`.
- **Brain's Protocol v2 (.agents Lifecycle Hooks)** — автоматический pre-invocation инжектор контекста, safety-gate барьер команд, enforce-workflow контроль журнала перед push, stop-check контроль незакоммиченных изменений.

## Цели (Grant Period & Roadmap)

- **Grant Period Цель:** Запустить и довести до Уровня 4 минимум 2 проекта (MeDev + JF-1C / Valeur) с реальными пользователями.
- **3-летний майлстоун:** Полноценная экосистема SaaS-продуктов Mr Developer, High-Load Enterprise инфраструктура, менторский клуб.
- **Текущий фокус:** Учебная LMS-платформа MrDevCourses (Level 3 MVP), запуск Telegram/YouTube каналов Mr Developer, масштабирование Valeur на микросервисы.


## Уровни зрелости проектов (моя система)

- **Лвл 1** — пет-проект / прототип
- **Лвл 2** — закрытый MVP
- **Лвл 3** — полнофункциональный релиз (готовый к трафику)
- **Лвл 4** — реальные клиенты, боевой деплой, автоматизация и аналитика
- **Лвл 5** — enterprise, распределенная команда, высокая отказоустойчивость
- **Лвл 6** — глобальный enterprise

---

## 🔗 Карта связей Второго Мозга (Knowledge Graph)
- **Активные проекты:** [[projects/mrdevcourses/mrdevcourses|MrDevCourses]], [[projects/medev/medev|MeDev]], [[projects/mr-developer/mr-developer|Mr Developer]], [[projects/valeur/valeur|Valeur]], [[projects/jf-1c/jf-1c|JF-1C (ZhanFinance)]], [[projects/envie/envie|Envie]]
- **Архитектура и концепты:** [[wiki/concepts/fsd-architecture|FSD]], [[wiki/concepts/spring-security-jwt|Spring Security JWT]], [[wiki/topics/vibe-coding|Вайбкодинг]], [[knowledge/ai-deslop-tools-and-skills|Deslop & DESIGN.md]]
- **База знаний:** [[knowledge/knowledge-index|Zettelkasten Индекс]]
- **Цели и история:** [[mem/goals|Цели]], [[mem/history|История вех]]




