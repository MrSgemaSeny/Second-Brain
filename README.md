# Brain's Protocol v2.0

### Личный «второй мозг» соло-разработчика и архитектурный протокол для работы с AI-агентами (Antigravity, Claude, GPT-4o, Gemini).

> Не пассивная свалка заметок. Это исполняемая операционная система: AI читает контекст → проверяет стек по докам → пишет код → прогоняет тесты → проходит через Quality Gate → фиксирует лог в `journal/` → и только потом делает `git push`.

---

## ⚡ Проблема, которую решает Brain's Protocol v2.0

Каждый разработчик, работающий с AI-ассистентами, сталкивается с одними и теми же проблемами:

- **Потеря контекста**: объясняешь AI свой стек, архитектурные ограничения и FSD-слои каждую сессию заново.
- **Галлюцинации и легаси**: AI пишет устаревший код по памяти, не сверяясь с актуальной документацией (React 19, Tailwind v4, Spring Boot 3.3).
- **Сырые коммиты**: в репозитории появляются коммиты `fix` без понимания, почему и зачем это было изменено.
- **Повторяющиеся грабли**: одни и те же архитектурные ошибки (Flyway checksums, IDOR, race conditions) совершаются повторно.
- **Хаос входящей информации**: интересные статьи, скриншоты и мысли теряются в чатах и папке `Downloads`.

Brain's Protocol решает это модульной архитектурой памяти v2.0, жесткими хуками исполнения и арсеналом из 24 профессиональных скиллов.

---

## 🚀 Что даёт Brain's Protocol v2.0

| До | После |
|---|---|
| 10 минут объяснять AI «я пишу на Spring Boot 3.3 + React 19 FSD» | AI читает `context/` и сразу стартует с полного контекста (< 200 строк) |
| AI тащит устаревшие классы и легаси-паттерны | Скилл `source-driven-development` сверяет код по актуальной документации |
| Пуш сломанного или непроверенного кода | Скилл `code-review-and-quality` и хук `enforce-workflow.ps1` блокируют push без тестов и лога |
| Потеря мыслей и быстрых ссылок | Шлюз `raw/inbox.md` для мгновенного сброса информации без форматирования |
| Черновики перемешаны с готовыми продуктами | Четкое разделение: черновики в `projects/`, готовые deliverables — в `output/` |
| Забыл, почему принято решение 2 месяца назад | Открываешь `decisions/` (ADR) или `mem/history.md` — там вся причинно-следственная связь |

---

## 🔄 Как это работает (Протокол сессии v2.0)

```
┌─ 1. ИНИЦИАЛИЗАЦИЯ (ДО НАЧАЛА СЕССИИ) ────────────────────┐
│ 1. context/me.md        → профиль, уровень, принципы       │
│ 2. context/projects.md  → реестр активных проектов         │
│ 3. context/rules.md     → железные правила разработки     │
│ 4. context/prompts_for_ai.md → шорткаты (/audit, /save)   │
│ 5. projects/{active}/   → контекст конкретного проекта    │
│ 6. journal/последний    → что было сделано в прошлый раз   │
│ → AI подтверждает загрузку контекста 3 контрольными ответами│
└───────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─ 2. ИСПОЛНЕНИЕ И КАЧЕСТВО ────────────────────────────────┐
│ • DETECT & FETCH: сверка со скиллом source-driven-dev     │
│ • IMPLEMENT: реализация без оверинжиниринга (SRP, FSD)    │
│ • VERIFY: запуск Unit, Integration и E2E тестов (100% Green)│
│ • 5-AXIS CODE REVIEW: проверка безопасности и чистоты     │
└───────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─ 3. ФИКСАЦИЯ И PUSH (ЖЕЛЕЗНЫЙ ГЕЙТ) ──────────────────────┐
│ 1. Запись лога в journal/YYYY-MM-DD/{project}.md          │
│ 2. Обновление _status.md и context/projects.md            │
│ 3. Экстракция новых хаков/паттернов в knowledge/ и wiki/  │
│ 4. git commit && git push (валидируется хуками)           │
└───────────────────────────────────────────────────────────┘
```

**Приоритет при конфликтах:** `Security > Correctness > Performance > Code Cleanliness`.

---

## 📂 Полная архитектура каталога (v2.0)

```
Second-Brain/
├── README.md                 # Главный манифест и архитектурный гайд v2.0
├── MAINTENANCE.md            # Чеклист гигиены системы (10 мин / 30 мин)
│
├── context/                  # Системный контекст (System Prompt < 200 строк)
│   ├── me.md                 # Профиль разработчика, стек, принципы
│   ├── projects.md           # Главный реестр проектов со статусами
│   ├── project_levels.md     # 10-уровневая шкала зрелости
│   ├── prompts_for_ai.md     # Команды (/audit, /critic), режимы и паттерны
│   └── rules.md              # Протокол сессий и железные правила
│
├── raw/                      # [НОВОЕ v2.0] Входящий шлюз сырых данных
│   ├── inbox.md              # Единственное место для быстрых заметок без структуры
│   ├── articles/             # Исходные статьи и спецификации
│   └── screenshots/          # Скриншоты и визуальные референсы
│
├── wiki/                     # [НОВОЕ v2.0] Связанная база концептов (Knowledge Graph)
│   ├── concepts/             # fsd-architecture.md, spring-security-jwt.md
│   └── topics/               # vibe-coding.md, mentorship.md
│
├── projects/                 # Модульные карточки проектов
│   ├── valeur/               # Enterprise HR Platform (5 микросервисов, 379 тестов)
│   ├── mr-developer/         # Блог, 5-недельный курс вайбкодинга, менторство
│   ├── medev/                # AI Resume SaaS (Render + Vercel, 290 тестов)
│   ├── jf-1c/                # ZhanFinance B2B SaaS CRM v1.0.0 (120 миграций)
│   ├── envie/                # Personal Workspace
│   └── air-canvas/           # CV Drawing (FastAPI + MediaPipe + React)
│
├── journal/                  # Working Memory — хроника по дням (неизменяемая)
│   └── YYYY-MM-DD/
│       └── {project}.md      # Подробный лог сессии: что изменено, какие тесты прошли
│
├── output/                   # [НОВОЕ v2.0] Финальные артефакты и deliverables
│   ├── lessons/              # Готовые методички уроков
│   ├── prompts/              # Пакеты промптов (БАЗИК, ПРО, МАСТЕР)
│   ├── posts/                # Публикации для Telegram и YouTube
│   └── docs/                 # Внешние гайды и регламенты
│
├── mem/                      # [НОВОЕ v2.0] Долгосрочная идентичность
│   ├── goals.md              # Стратегические цели (1 мес / 6 мес / 1 год)
│   ├── people/               # Досье и контекст людей (student-1.md)
│   └── history.md            # Летопись поворотных вех карьеры и проектов
│
├── knowledge/                # Zettelkasten — проверенные хаки и решения багов
│   ├── knowledge-index.md    # Индекс по 23+ заметкам
│   └── *.md                  # IDOR, WebSockets iOS Safari, Thymeleaf PDF, Groq AI
│
├── decisions/                # Архитектурные решения (ADR-001..N)
│
├── hooks_template/           # Шаблоны хуков для Antigravity и Git
│   ├── hooks.json
│   └── scripts/ (enforce-workflow.ps1, reminder.ps1)
│
└── templates_for_projects/   # Шаблоны для копирования (new-project, session-log, epic)
```

---

## 🛠️ Боевой стек и активные проекты

### Стек экосистемы
- **Backend:** Java 17, Spring Boot 3.3, Spring Security 6, Spring Cloud Gateway, PostgreSQL 16/17, Flyway, Redis, Caffeine, Bucket4j, WebSockets (STOMP).
- **Frontend:** React 19, TypeScript, Vite, Tailwind CSS v4, Feature-Sliced Design (FSD), TanStack Query v5.
- **AI & ML:** Groq API (Llama 3.3 70B, GPT-OSS), LangChain/Spring AI, MediaPipe.
- **Infra & DevOps:** Docker, GitHub Actions, Vercel, Render, Fly.io, GitHub Pages.

### Реестр активных проектов:
1. **Valeur**: Enterprise HR & ATS платформа (5 микросервисов: `identity`, `vacancy`, `application`, `ai`, `gateway`). 379/379 тестов (100% Green).
2. **Mr Developer**: бренд, 5-недельный курс вайбкодинга, менторство (Ученик 1), стартер-киты `.agents/` и Second Brain.
3. **MeDev (DevProfile)**: Data-first AI SaaS платформа резюме (Production Live на Vercel + Render, 290 тестов).
4. **JF-1C (ZhanFinance)**: Казахстанская B2B SaaS CRM платформа (Релиз v1.0.0, 120 Flyway миграций).

---

## 🛡️ Арсенал 24 профессиональных скиллов Antigravity

В Second Brain v2.0 интегрирован полный реестр скиллов:

| Категория | Скиллы |
|---|---|
| **Quality & Security** | `code-review-and-quality`, `security-and-hardening`, `debugging-and-error-recovery`, `source-driven-development` |
| **Engineering & Arch** | `planning-and-task-breakdown`, `incremental-implementation`, `api-and-interface-design`, `test-driven-development`, `git-workflow-and-versioning` |
| **Refactoring & Perf** | `code-simplification`, `performance-optimization`, `doubt-driven-development`, `deprecation-and-migration` |
| **Product & Specs** | `spec-driven-development`, `interview-me`, `idea-refine`, `documentation-and-adrs` |
| **DevOps & Tooling** | `shipping-and-launch`, `ci-cd-and-automation`, `browser-testing-with-devtools`, `observability-and-instrumentation`, `context-engineering`, `using-agent-skills` |

---

## 🚀 Быстрый старт с AI-агентом

Скормить контекст AI в начале сессии одним сообщением:

```text
Прочитай Brain's Protocol v2.0 перед началом работы:
1. context/me.md
2. context/projects.md
3. context/rules.md
4. context/prompts_for_ai.md

Ты знаешь мой стек, проекты и архитектурные принципы.
Приоритеты: Security > Correctness > Performance > Code Cleanliness.
Перед push — обязательное code-review и лог в journal/.
```

---

## 📊 В цифрах (v2.0)

- **200+** структурированных файлов
- **5** активных SaaS-проектов с продакшен-кодом
- **23+** проверенных заметок в базе знаний Zettelkasten
- **24** профессиональных скилла Antigravity
- **379+** автоматизированных тестов в ключевых сервисах
- **0** непроверенных коммитов

---

> **Brain's Protocol v2.0** — несокрушимый контекст, дисциплина исполнения и память, которая растёт с каждым коммитом.
