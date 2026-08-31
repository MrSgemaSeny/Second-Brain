# Brain's Protocol — Second Brain

### Личный «второй мозг» соло-разработчика (MrSgemaSeny / Mr Developer). Живой контекст для AI-сессий, который знает твой стек, твои проекты и твою историю — и передаёт их любому AI за секунды.

> **Это не папка с заметками и не Obsidian-свалка.**  
> Это **исполняемый протокол кумулятивной инженерии**: AI читает контекст → пишет код → прогоняет тесты → фиксирует лог в Second Brain → и только потом делает `git push`.

---

## 1. Проблема, которую решает Brain's Protocol

Каждый соло-разработчик и вайбкодер, работающий с AI-агентами (Claude Code, Antigravity, OpenHands, Cursor, GPT-4o, Gemini 1.5/3.7), сталкивается с одними и теми же системными барьерами:

- **Контекстный налог (Cold Start)**: Каждую новую сессию приходится заново объяснять свой стек (Spring Boot 3 + React 19 FSD), железо (Windows, 4GB VRAM) и стандарты разработки.
- **Амнезия решений**: AI пишет код «в вакууме», не зная архитектурных решений прошлых сессий и причин выбора конкретных библиотек.
- **Отсутствие истории «зачем и почему»**: В git-коммитах виден только дифф изменений, но теряется контекст: с какими багами столкнулись, почему отвергли альтернативы и какие тесты подтвердили корректность.
- **Повторение одних и тех же грабель**: Ошибки Flyway-миграций, циклические зависимости Hibernate, нюансы WebSockets на iOS Safari, проблемы IDOR и MapStruct N+1 отлаживаются заново в каждом проекте.

Brain's Protocol решает это единой структурой и автоматизированными правилами.

---

## 2. Что это даёт на практике

| До внедрения Brain's Protocol | После внедрения Brain's Protocol |
|---|---|
| 10–15 минут объяснять AI стек: «Spring Boot, React, FSD, PostgreSQL» | AI читает `context/me.md` за 3 секунды и стартует с 100% точностью |
| AI предлагает микросервисы «потому что модно» | AI знает железный принцип: модульный монолит на старте (микросервисы только на Level 5+) |
| Забыл, почему в JF-1C сделана роль ADVISOR или как устроен Drip SQL | Открываешь `journal/` или `decisions/ADR-*.md` — там зафиксирована вся цепочка решений |
| Одинаковый баг с Rate Limiting повторяется в трёх проектах | Баг и решение занесены в `knowledge/` — следующий AI обходит его автоматически |
| Коммит «fix bug» без контекста | Структурированный лог сессии перед пушем: что изменено, какие тесты прошли, какие риски закрыты |
| Дисциплина держится на силе воли и рушится при усталости | Lifecycle Hooks физически блокируют push и завершение сессии без тестов и отчета |

---

## 3. Как это работает: Три правила и Главная формула

### Три правила протокола:
```text
ПРАВИЛО №1 → Перед сессией AI читает context/* (Second Brain)
ПРАВИЛО №2 → После зелёных тестов AI пишет в journal/ перед git push
ПРАВИЛО №3 → AI дополняет prompts_for_ai.md и knowledge/ при появлении новых паттернов
```

### Главное правило системы:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ГЛАВНОЕ ПРАВИЛО СИСТЕМЫ                          │
│                                                                         │
│         ТЕСТЫ ПРОШЛИ ──> AI ПИШЕТ В ЖУРНАЛ ──> GIT COMMIT / PUSH        │
│                                                                         │
│                  Никогда наоборот. Никогда без лога.                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Протокол сессии в действии:

```
┌─ ДО НАЧАЛА ──────────────────────────────────────────────────────────────┐
│ 1. context/me.md              → профиль, стек, инженерная ДНК, принципы   │
│ 2. context/projects.md        → активные проекты и актуальные статусы   │
│ 3. context/rules.md           → железные правила разработки             │
│ 4. context/prompts_for_ai.md  → режимы, slash-команды, извлечённый опыт │
│ 5. knowledge/                 → релевантные архитектурные хаки и грабли │
│ 6. projects/{active-project}/ → детальный паспорт текущего проекта      │
│ 7. journal/последний          → что было сделано в прошлый раз          │
│ ──> AI подтверждает готовность (отвечает на 3 контрольных вопроса)      │
└──────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼  (работа с полным контекстом)
┌─ ПОСЛЕ ЗЕЛЁНЫХ ТЕСТОВ ───────────────────────────────────────────────────┐
│ 1. Создать/обновить journal/YYYY-MM-DD/{project}.md по шаблону лога      │
│ 2. Обновить projects/{project}/ при смене статуса или архитектуры       │
│ 3. Экстрагировать ценные хаки/багфиксы в knowledge/                      │
│ 4. Обновить knowledge/knowledge-index.md                                 │
│ 5. Дополнить prompts_for_ai.md новыми паттернами                         │
│ 6. Выполнить git commit && git push                                      │
└──────────────────────────────────────────────────────────────────────────┘
```

Приоритет при конфликте решений:  
$$\text{Security} > \text{Correctness} > \text{Performance} > \text{Code Cleanliness}$$

---

## 4. Аппаратные .agents Lifecycle Hooks (Автоматическое принуждение)

Каждый проект в рабочей среде содержит директорию `.agents/` с хуками, которые превращают правила в **непреодолимый барьер**:

- **PreInvocation (`pre-invocation.ps1`)**: Автоматически подгружает на 1-м шаге сессии `.agents/CONTEXT.md` и ключевые файлы Second Brain (`me.md`, `projects.md`, `rules.md`).
- **PreToolUse (`safety-gate.ps1`)**: Блокирует использование медленных CLI-утилит чтения (`cat`, `grep`, `sed`, `ls`, `head`, `tail`) и деструктивные git-команды (`push --force`, `reset --hard`), форсируя использование нативных инструментов агента.
- **PreToolUse (`enforce-workflow.ps1`)**: Перехватывает вызов `git push` и проверяет наличие свежей записи в `journal/` с поддержкой 24-часового плавающего окна. Без записи пуш физически блокируется.
- **Stop (`stop-check-commits.ps1`)**: Проверяет `git status --porcelain` в основном проекте и Second Brain. Возвращает `decision: continue`, пока все изменения не закоммичены.

---

## 5. Полная структура репозитория

```
Second-Brain/
├── README.md               # Главный манифест и системный обзор протокола
├── MAINTENANCE.md          # Чеклист обслуживания (10 мин еженедельно / 30 мин ежемесячно)
├── combined_docs.md        # Скомпилированный монолитный контекст
├── combine.py / combine.ps1# Скрипты быстрой сборки контекста для внешних LLM
│
├── context/                # ЯДРО СИСТЕМЫ (System Prompts & Living Context)
│   ├── me.md               # профиль, стек, принципы, цели, энергетический цикл
│   ├── projects.md         # все проекты с актуальными статусами (обновлено 31.08.2026)
│   ├── project_levels.md   # 10-уровневая шкала зрелости («Долина смерти»)
│   ├── prompts_for_ai.md   # режимы общения, slash-команды, извлечённые паттерны
│   └── rules.md            # протокол сессии, железные правила разработки
│
├── raw/                    # ВХОДЯЩИЙ ПОТОК СЫРЫХ ДАННЫХ
│   ├── inbox.md            # быстрые мысли и ссылки без структуры
│   ├── articles/           # статьи и спецификации
│   └── screenshots/        # визуальные референсы и материалы
│
├── wiki/                   # СВЯЗАННАЯ БАЗА ЗНАНИЙ (Knowledge Graph)
│   ├── concepts/           # фундаментальные концепты (FSD, JWT, RAG)
│   └── topics/             # сквозные темы (vibe-coding, mentorship)
│
├── projects/               # ПАСПОРТА И МОДУЛЬНАЯ ДОКУМЕНТАЦИЯ ПРОЕКТОВ
│   ├── mrdevcourses/       # образовательная LMS-платформа (Level 3 MVP)
│   ├── jf-1c/              # Zhan Finance — Enterprise B2B SaaS CRM (Level 4 Prod)
│   ├── medev/              # Data-First AI SaaS профилей инженеров (Level 4 Live)
│   ├── valeur/             # Multi-Tenant ATS & AI Hiring Platform (Level 2-3)
│   ├── envie/              # личный Second Brain и OS инженера (Level 3)
│   ├── mr-developer/       # блог, YouTube/TG каналы, программы менторства
│   ├── air-canvas/         # рисование в воздухе (MediaPipe + WebSockets)
│   └── ...                 # архивные проекты (testCinema, Football Bot TG, BallonDorChat)
│
├── journal/                # DAILY WORKING MEMORY (70+ файлов по датам)
│   └── YYYY-MM-DD/
│       └── {project}.md    # логи сессий: что добавлено, изменено, тесты, проблемы
│
├── knowledge/              # ZETTELKASTEN БАЗА ЗНАНИЙ (63+ статей)
│   ├── knowledge-index.md  # полный индексный реестр заметок
│   ├── arch-*.md           # системный дизайн, RAG, Outbox, STOMP, Rate Limiting
│   ├── sec-*.md            # безопасность: IDOR, RLS, Stateless JWT, PII
│   ├── incident-*.md       # разборы боевых инцидентов (Post-Mortems)
│   └── pedagogy-*.md       # педагогика вайбкодинга, матрицы автоматизации
│
├── decisions/              # РЕЕСТР АРХИТЕКТУРНЫХ РЕШЕНИЙ (15 ADR)
│   ├── ADR-001...ADR-014   # зафиксированные архитектурные развилки
│
├── mem/                    # ДОЛГОСРОЧНАЯ ПАМЯТЬ И ИДЕНТИЧНОСТЬ
│   ├── identity.md         # глубокая самоидентификация и ценности
│   ├── goals.md            # стратегические цели (1 мес / 6 мес / 1 год / 3 года)
│   ├── history.md          # летопись ключевых вех карьеры и проектов
│   └── people/             # контекст учеников (student-1.md)
│
├── output/                 # ФИНАЛЬНЫЕ АРТЕФАКТЫ И DELIVERABLES
│   ├── lessons/            # методички и сценарии уроков
│   ├── prompts/            # пакеты промптов (БАЗИК, ПРО, МАСТЕР)
│   ├── posts/              # публикации для Telegram и YouTube
│   └── docs/               # внешняя документация
│
├── hooks_template/         # Шаблоны хуков для Antigravity и Git
├── templates/              # Универсальные шаблоны жизненного цикла
└── templates_for_projects/ # Шаблоны под инструменты (CLAUDE.md, session-log, epic, idea-card)
```

---

## 6. Активные проекты (по состоянию на 31.08.2026)

### 1. MrDevCourses (Educational LMS & Vibe-Coding Platform)
- **Статус:** **Level 3 — Strong Educational MVP / Pre-Release Pilot** (100% Green: 27 сьютов Vitest [64 теста], 184 backend-теста JUnit, 1789 модулей собрано).
- **Стек:** Java 17 + Spring Boot 3.3.0 + Spring Security 6 + Google OAuth2 + JWT (httpOnly cookie) + PostgreSQL 17 (pgvector, pg_trgm) + Bucket4j + OpenHTMLtoPDF + React 19 + TypeScript + Vite + Tailwind v4 + FSD Architecture.
- **Ключевые модули:** Drip-расчет в SQL `(NOW() - enrolled_at)`, гибридный RAG-тьютор (Dense HNSW + Sparse FTS RRF), анти-чит квизы, конвейер сдачи ДЗ ментору (`/admin/homeworks`), 2-колоночный B2C лендинг с видео-трейлером и аккордеоном программы.
- **Философия менторства:** Zero Friction Setup в карточке урока, SOS-кнопка «Не получается», Telegram Dashboard ментора, разделение зон (LMS для рутины, Discord для эмоций).

### 2. Zhan Finance (JF-1C) — Enterprise B2B SaaS Platform
- **Статус:** **Level 4 — Production-Ready v1.0.0 Released** (545 коммитов, 33 чистых рабочих дня, закрыты все 28 пунктов аудита безопасности).
- **Стек:** Java 17 + Spring Boot 3.4+ + Spring Security 6 + PostgreSQL 17 + Flyway (миграции V1–V120) + React 19 + TypeScript + FSD + WebSockets (STOMP) + 2FA TOTP + OpenHTMLtoPDF + Caffeine Cache + Bucket4j.
- **Что это:** Комплексная B2B SaaS платформа для бухгалтерского консалтинга и CRM в Казахстане (CRM Kanban, Task Pool, биллинг, документооборот, LMS, защищённые чаты, 6 ролей с Row-Level Security через `CrmAccessService`).
- **Деплой:** Backend на Fly.io (`zhanfinance.fly.dev`), Frontend на GitHub Pages.

### 3. MeDev (DevProfile) — Data-First AI SaaS для Инженеров
- **Статус:** **Level 4 — Pre-Launch / Private Beta Live** (253 backend теста, 37 frontend тестов, 0 warnings/errors, закрыты уязвимости W-1..W-9).
- **Стек:** Spring Boot 3.3.0 + React 19 + PostgreSQL 17 (pgvector) + Flyway (V24) + Redis Valkey 8.1 (L2 Cache) + In-Memory Caffeine (L1 Cache) + Groq LLM (SSE-стриминг) + Flying Saucer + Vitest.
- **Что это:** Платформа единого источника правды для разработчиков. Парсер GitHub API, алгоритм Smart Merge для старых PDF-резюме без галлюцинаций LLM, 6 дизайн-шаблонов резюме, публичное веб-портфолио (`/:username`) и Job Tracker CRM.
- **Деплой:** Production Live: Frontend на Vercel (`me-dev-two.vercel.app`), Backend & DB & Redis на Render (`medev-backend.onrender.com`).

### 4. Valeur — Multi-Tenant Distributed ATS & AI Hiring Platform
- **Статус:** **Level 2–3 — Heavy Production-Ready MVP** (5 микросервисов + Spring Cloud Gateway, Docker Compose).
- **Стек:** Java 17 + Spring Boot 3.3.4 + Spring Cloud Gateway + PostgreSQL 16 (4 схемы БД) + Groq AI (Llama 3.3 70B) + React 19 + TypeScript + FSD + TanStack Query v5.
- **Архитектура:** Микросервисы (`identity-service:8081`, `vacancy-service:8082`, `application-service:8083`, `ai-service:8084`, `api-gateway:8080`). Изоляция данных компаний по `TenantContext` и `tenant_id`, межсервисный токен `X-Internal-Token`.
- **Что это:** ATS-система со скорингом резюме кандидатов, интерактивным Kanban с SLA-контролем и кадровым резервом (Talent Pool CRM).

### 5. Envie — Personal Headquarters & Knowledge Operating System
- **Статус:** **Level 3 — Personal Production OS** (Все 8 модулей реализованы, sub-15ms отклик).
- **Стек:** Java 17 + Spring Boot 3.4 + PostgreSQL 17 + Flyway (V1–V7) + React 19 + TypeScript + FSD 2.1 + Tailwind v4 + Canvas 2D + Three.js.
- **Что это:** Персональная инженерная операционная среда без облаков и сторонней авторизации. Заметки, плоский Канбан без Jira-бюрократии, инкубатор идей, D3 граф Markdown-шаблонов и 3D Wireframe глобус на HTML5 2D Canvas.

### 6. Air Canvas
- **Статус:** **Завершён**
- **Стек:** Python (FastAPI + MediaPipe) + React (TypeScript + Canvas API) + WebSocket.
- **Что это:** Бесконтактное рисование в воздухе перед веб-камерой с распознаванием 3D-жестов руки в реальном времени.

---

## 7. Техническое ядро (dev-to-dev)

### Стек, под который заточен протокол:
- **Backend:** Java 17, Spring Boot 3.3/3.4, Spring Security 6, Spring Cloud Gateway, JPA/Hibernate, PostgreSQL, Flyway, Caffeine Cache, Bucket4j, WebSocket (STOMP), OpenHTMLtoPDF.
- **Frontend:** React 19, TypeScript, Vite, Tailwind CSS v4, Feature-Sliced Design (FSD), React Query, Framer Motion, dnd-kit.
- **Infra:** Docker, GitHub Actions, Fly.io, Render, Vercel, GitHub Pages.
- **AI & Data:** Groq API (Llama 3.3 70B, GPT-OSS), Spring AI, pgvector (HNSW), Hybrid Search (RRF).

### Архитектурные принципы (вшиты в контекст):
- **Модульный монолит на бэкенде** с последующим выделением в микросервисы (DDD/Bounded Contexts).
- **FSD (Feature-Sliced Design) на фронтенде** — всегда (app, pages, widgets, features, entities, shared).
- **DESIGN.md-first подход** — перед реализацией любого UI составляется контракт токенов (4 уровня типографики, палитра `#0a0a0c`/`#18181b`, радиусы `2-4px`, отсутствие visual clutter/deslop).
- **Security first & Zero Trust** — IDOR/RLS защита на уровне сервисов, stateless OAuth2/JWT в httpOnly cookies, rate limiting (Bucket4j).
- **Migrations only** — схема БД строго через Flyway `V{N}__` скрипты, запрет ручных правок и `ddl-auto=update`.

### Железные правила (AI нарушать не может):
```text
НИКОГДА  не менять применённые Flyway-миграции
НИКОГДА  не хардкодить секреты и пароли в коде
НИКОГДА  ddl-auto=update в продакшене
НИКОГДА  @PostConstruct для DB-операций — только @EventListener(ApplicationReadyEvent.class)
НИКОГДА  не использовать терминальные echo/cat/Add-Content для правки файлов
ВСЕГДА   тесты перед фиксацией журнала и пушем
ВСЕГДА   FSD на фронтенде
ВСЕГДА   security в архитектуре с первого дня
```

### Два режима общения с AI:
- **Режим 1 (по умолчанию) — Senior Architect peer:** уточняющие вопросы, рассуждения вслух, трейд-оффы, прямой пуш-бэк на плохие решения.
- **Режим 2 — поддержка/эмпатия:** тёплый тон, честность не снижается, критика только по запросу или если критично для безопасности.
- Переключение фразами: «включи режим 2» / «вернись в обычный режим».

### Специальные команды (Slash Commands):
- `/audit` — Прогнать код через Security-чеклист (IDOR, JWT, RLS, TenantContext, CORS).
- `/critic` — Найти только проблемы, уязвимости и антипаттерны без похвалы.
- `/firstprinciples` — Разобрать проблему с нуля на фундаментальных принципах.
- `/contrarian` — Оспорить архитектурное решение и найти аргументы «против».
- `/pseudocode` — Описать алгоритмическую логику без синтаксического шума.

### Совместимость с AI-инструментами:
| Инструмент | Интеграция |
|---|---|
| **Antigravity / Gemini** | Пакет из 24 скиллов (`code-review-and-quality`, `source-driven-development`), хуки `enforce-workflow.ps1`, `safety-gate.ps1` |
| **Claude (claude.ai)** | Промпт «Senior Software Architect и наставник» в `prompts_for_ai.md` |
| **Claude Code** | Авточтение `CLAUDE.md` из корня репо (шаблон в `templates_for_projects/claude.md`) |
| **OpenHands** | Модель Claude Sonnet, формат задач `[Действие] [Что] [Где] [Acceptance]` |
| **GPT-4o** | Промпт под Full-Stack (Spring Boot + React TS), production-ready |

---

## 8. Шкала зрелости проектов (10 уровней)

Встроенная система оценки, по которой AI и автор сверяют текущее состояние любого проекта:

| Ур. | Название | Суть и критерии | Проекты |
|---|---|---|---|
| 1 | Sandbox / Playground | «Hello World», проверка гипотезы библиотеки | — |
| 2 | Pet Project | Инструмент для себя, MVC, локальный запуск | — |
| 3 | **MVP (Educational / Product)** | **Монолит, FSD, базовая безопасность, ключевые тесты** | **MrDevCourses, Envie** |
| 4 | **Public Beta / Production** | **CI/CD, 100% покрытие бизнес-сценариев, закрытый аудит безопасности** | **JF-1C, MeDev** |
| **5** | **Traction & Stabilization** | ** «ДОЛИНА СМЕРТИ» — распил God-объектов, Rate Limiting, тесты, Staging** | **Valeur (микросервисы)** |
| 6 | Validated SaaS | PMF, стабильный MRR, 99.9% uptime, Redis-кэш, Zero-downtime | — |
| 7 | Scale-up | Тысячи активных юзеров, очереди (Kafka), кластеры БД | — |
| 8 | Mid-Market Enterprise | SLA, tenant isolation, полный Audit Log, compliance | — |
| 9 | High-Load Enterprise | Миллионы юзеров, K8s, multi-region, Chaos Engineering | — |
| 10 | Tech Giant | Изобретение собственных технологий (Google, Meta, Amazon) | — |

---

## 9. База знаний (Zettelkasten) и реестр ADR

В базе зафиксировано **63+ статьи** в `knowledge/` и **15 ADR** в `decisions/`. Полный реестр ведётся в `knowledge/knowledge-index.md`.

### Ключевые архитектурные паттерны:
- **Архитектура & Высокие нагрузки**:
  - `arch-hybrid-rag-dense-sparse-rrf` — гибридный RAG-поиск: pgvector HNSW (Dense) + FTS (Sparse) через Reciprocal Rank Fusion.
  - `arch-transactional-outbox-event-automation` — Transactional Outbox Pattern в монолите без внешних брокеров.
  - `arch-tiered-rate-limiting-bucket4j` — 3-уровневый Rate Limiting с Bucket4j и Caffeine (Auth, AI, General).
  - `arch-realtime-chat-websocket` — архитектура реалтайм-чатов (STOMP, WebSockets, Pub/Sub).
  - `jvm-metaspace-tuning` — тюнинг памяти JVM для инстансов с 512MB RAM.
  - `arch-caffeine-cache` — локальное кеширование для монолита.
- **Безопасность (Zero Trust)**:
  - `security-idor-rls` — защита от IDOR и Row-Level Security в PostgreSQL.
  - `sec-oauth2-stateless-cookies` — реализация OAuth2 в STATELESS архитектуре без сессий.
  - `sec-file-upload-magic-bytes` — валидация загружаемых файлов по Magic Bytes.
  - `sec-internal-service-token` — защита межсервисного взаимодействия (`X-Internal-Token`).
  - `sec-prompt-injection-xml` — защита от Prompt Injection через XML-теги.
  - `sec-mvp-to-prod-checklist` — чек-лист перехода от MVP к Production.
- **Фронтенд & UI Deslop**:
  - `ai-deslop-strategy-tokens-audit` — Стратегия → Токены (DESIGN.md) → Аудит. 4 уровня шрифтов.
  - `frontend-native-fetch-interceptor` — нативный Fetch с перехватом 401 и ротацией токена.
  - `arch-contextual-quick-nav-drawer` — контекстная навигация без размонтирования плеера.
  - `b2c-lms-course-discovery-and-video-preview` — B2C витрина курсов и Hover-трейлеры.
- **AI & Педагогика**:
  - `arch-ai-code-grader-and-security-scanner` — автоматический AI-грейдер со статическим AST-сканером безопасности.
  - `arch-ai-smart-merge` — слияние данных из нескольких источников (API + PDF) без галлюцинаций LLM.
  - `pedagogy-and-automation-split-for-vibe-coding` — педагогика вайбкодинга: трансформация идентичности, быстрый Win на Уроке 1, Error-Loop, разделение зон LMS и ментора.
- **Постмортемы боевых инцидентов**:
  - `incident-01-flyway-github-actions-desync` — расхождение миграций локально и на prod.
  - `incident-02-management-port-hibernate-crash` — конфликт management-портов и краш Hibernate на Fly.io.

---

## 10. Оценка эффективности и $4\times$ ROI (Взгляд со стороны)

> **Внешняя оценка архитектуры Second Brain: 9.5 / 10.**  
> Система переводит Second Brain из статуса «помощника» в статус **автоматизированной инфраструктуры**.

### Почему система даёт минимум 4-кратное ускорение ($4\times$ Multiplier):
1. **Нулевой Cold-Start (0 секунд на ввод в курс дела)**: Новый агент с первой секунды знает проект, стек, прошлые решения и правила. Без этого тратится 15–20 минут на вводную часть каждой сессии.
2. **Принудительная кумулятивность**: Знания и грабли фиксируются не «когда-нибудь потом», а на каждом шаге по завершении тестов.
3. **Разгрузка оперативной памяти разработчика**: Не нужно помнить детали WebSocket handshake, тонкости OpenHTMLtoPDF или парсинга GitHub — всё подтягивается из `knowledge/`.
4. **Дисциплина без силы воли**: Стандарты инженерии охраняются Lifecycle Hooks на уровне IDE.

### Что решает автоматизация vs Где нужен живой инженер:
- **Автоматизация снимает**: Контекстный налог, повторение старых багов, потерю решений, дрейф архитектуры и лень в ведении документации.
- **Инженер + Тесты закрывают**: Защиту от сильных галлюцинаций LLM, выбор продуктовых приоритетов и живой менторский диалог.

---

## 11. Быстрый старт с любым AI

```bash
git clone https://github.com/MrSgemaSeny/Second-Brain.git
cd Second-Brain
```

1. Открой vault в Obsidian (или любом Markdown-редакторе).
2. Отредактируй `context/me.md` под свой стек и принципы.
3. Заполни `context/projects.md` своими проектами.
4. В начале каждой AI-сессии скорми агенту стартовый промпт.
5. После зелёных тестов — фиксируй лог в `journal/YYYY-MM-DD/{project}.md` перед `git push`.

### Скормить контекст AI одним сообщением:
```text
Прочитай Brain's Protocol перед началом работы:
1. context/me.md
2. context/projects.md
3. context/rules.md
4. context/prompts_for_ai.md

Ты знаешь мой стек, активные проекты и архитектурные стандарты.
Приоритеты: Security > Correctness > Performance > Code Cleanliness.
После успешного прохождения тестов — зафиксируй отчет в journal/YYYY-MM-DD/{project}.md перед git push.
```

---

## 12. Что этот репозиторий НЕ делает

- Не генерирует код сам — он даёт контекст тому, кто генерирует.
- Не заменяет git-коммиты — он дополняет их человеческим контекстом и смыслом.
- Не CRM и не трекер задач — это контекстный слой над твоей реальной работой.
- Не пытается угодить менеджерам — это инструмент программиста для программиста.

---

## 13. Метрики репозитория (В цифрах)

- **370+** структурированных markdown-файлов
- **63+** прикладных Zettelkasten-заметок в `knowledge/`
- **15** зафиксированных Architecture Decision Records (ADR)
- **70+** ежедневных журналов разработки (август 2026)
- **14** паспортов проектов (5 активных боевых систем)
- **1000+** автоматических тестов (JUnit + Vitest) в обслуживаемых проектах
- **4** аппаратных Lifecycle Hook (`pre-invocation`, `safety-gate`, `enforce-workflow`, `stop-check-commits`)
- **24** профессиональных скилла Antigravity

---

## 14. Философия в одном абзаце

Мне важна детерминированность — база данных меняется только через миграции, а не «накатили руками». Мне важна ролевая безопасность на уровне архитектуры, а не патчей поверх дыр. И мне важно доводить проект до реального использования живыми людьми, а не оставлять его демкой в портфолио. Brain's Protocol — это та же дисциплина, перенесённая на работу с AI: контекст зафиксирован, история неизменяема, решения осознанны.

---

## Лицензия

Личный репозиторий. Используй структуру как inspiration для своего второго мозга.

---

> **Brain's Protocol** — контекст, который не теряется между сессиями.
