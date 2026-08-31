# Brain's Protocol — Second Brain

### Исполняемая операционная среда и контекстный мультипликатор соло-разработчика (Mr Developer / MrSgemaSeny)

> **Это не папка с заметками и не Obsidian-свалка.**  
> Это **исполняемый протокол кумулятивной инженерии**: контекст личности, архитектурных решений, базы граблей и стандартов качества, передаваемый любому AI-агенту за секунды с принудительной фиксацией результатов на уровне Lifecycle Hooks.

---

## 1. Суть системы и проблема, которую она решает

### Проблема «холодного старта» и амнезии AI-сессий
Каждый соло-разработчик и вайбкодер, работающий с современными AI-агентами (Claude Code, Antigravity, OpenHands, GPT-4o, Gemini 1.5/3.7), сталкивается с системными барьерами:
1. **Контекстный налог (Cold Start)**: Каждую новую сессию приходится заново объяснять свой стек, принципы (FSD, модульный монолит, Spring Boot 3, stateless cookies) и ограничения окружения (Windows, VRAM, порты).
2. **Амнезия решений**: AI пишет код в вакууме, не зная, почему неделю назад мы отказались от Axios в пользу нативного fetch или почему для PDF выбран OpenHTMLtoPDF вместо Flying Saucer.
3. **Отсутствие причинно-следственной истории**: В коммитах виден только дифф кода (`git diff`), но потерян контекст «зачем, почему и на основании каких трейд-оффов это сделано».
4. **Повторение одних и тех же граблей**: Ошибки Flyway, циклические вызовы в Hibernate, утечки JWT в WebSocket или N+1 в MapStruct находятся и отлаживаются заново в каждом новом репозитории.

### Решение Brain's Protocol: Автоматизация и Принуждение
Система переводит ведение контекста из ручного труда в **автоматизированную часть рабочего цикла агента**:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ГЛАВНОЕ ПРАВИЛО СИСТЕМЫ                          │
│                                                                         │
│         ТЕСТЫ ПРОШЛИ ──> AI ПИШЕТ В ЖУРНАЛ ──> GIT COMMIT / PUSH        │
│                                                                         │
│                  Никогда наоборот. Никогда без лога.                    │
└─────────────────────────────────────────────────────────────────────────┘
```

Дисциплина подкреплена аппаратными **.agents Lifecycle Hooks** в IDE:
- `pre-invocation.ps1` — автоматически инжектирует ядро Second Brain на первом же шаге любой сессии.
- `safety-gate.ps1` — блокирует деструктивные терминальные команды и неэффективные CLI-утилиты.
- `enforce-workflow.ps1` — физически перехватывает `git push` и запрещает отправку изменений без свежей записи в `journal/`.
- `stop-check-commits.ps1` — блокирует завершение хода агента при наличии незакоммиченных изменений в проекте или Second Brain.

---

## 2. Архитектура и структура репозитория

```
Second-Brain/
├── README.md               # Главный манифест и системный обзор протокола
├── MAINTENANCE.md          # Регламент гигиены и архивации контекста
├── combined_docs.md        # Скомпилированный монолитный контекст
├── combine.py / combine.ps1# Скрипты быстрой сборки контекста для внешних LLM
│
├── context/                # ЯДРО СИСТЕМЫ (System Prompts & Constraints)
│   ├── me.md               # Инженерная ДНК, стек, принципы, энергетический цикл
│   ├── rules.md            # Железные правила разработки и протокол сессии
│   ├── projects.md         # Актуальный статус всех активных и архивных проектов
│   ├── project_levels.md   # 10-уровневая шкала зрелости («Долина смерти»)
│   └── prompts_for_ai.md   # Режимы общения, slash-команды, извлечённые паттерны
│
├── projects/               # ПАСПОРТА И МОДУЛЬНАЯ ДОКУМЕНТАЦИЯ ПРОЕКТОВ
│   ├── mrdevcourses/       # Образовательная LMS-платформа (Level 3 MVP)
│   ├── jf-1c/              # Zhan Finance — Enterprise B2B SaaS (Level 4 Production)
│   ├── medev/              # Data-First AI SaaS профилей инженеров (Level 4 Live)
│   ├── valeur/             # Multi-Tenant ATS & AI Hiring Platform (Level 2-3)
│   ├── envie/              # Персональная инженерная операционная система (Level 3)
│   ├── mr-developer/       # Блог, YouTube/TG каналы, программы менторства
│   ├── air-canvas/         # Бесконтактное рисование (MediaPipe + WebSockets)
│   └── ...                 # Архивные проекты и фундаментальный опыт
│
├── knowledge/              # ZETTELKASTEN БАЗА ЗНАНИЙ (63+ статей)
│   ├── knowledge-index.md  # Индексный граф всех архитектурных заметок
│   ├── arch-*.md           # Системный дизайн (RAG, Outbox, STOMP, Rate Limiting)
│   ├── sec-*.md            # Стандарты безопасности (IDOR, RLS, Stateless JWT, PII)
│   ├── incident-*.md       # Разборы боевых инцидентов (Post-Mortems)
│   └── pedagogy-*.md       # Педагогика вайбкодинга и матрицы автоматизации
│
├── decisions/              # РЕЕСТР АРХИТЕКТУРНЫХ РЕШЕНИЙ (15+ ADR)
│   ├── ADR-001...ADR-014   # Модульный монолит, FSD, Stateless Auth, Drip SQL, B2C Discovery
│
├── journal/                # DAILY MEMORY — ЛОГИ СЕССИЙ (70+ файлов по датам)
│   └── YYYY-MM-DD/         # Логи сессий: Что добавлено, изменено, тесты, проблемы
│
├── mem/                    # ДОЛГОСРОЧНАЯ ПАМЯТЬ И ИДЕНТИЧНОСТЬ
│   ├── identity.md         # Самоопределение, ценности, психологический профиль
│   ├── goals.md            # Стратегические вехи (Grant Period, 1 год, 3 года)
│   ├── history.md          # Хроника ключевых инженерных майлстоунов
│   └── people/             # Контекст учеников и менторских когорт
│
├── wiki/                   # СВЯЗАННЫЙ ГРАФ КОНЦЕПЦИЙ
│   ├── concepts/           # Теоретические основы (FSD, Spring Security, JWT)
│   └── topics/             # Сквозные направления (Вайбкодинг, Менторство)
│
├── hooks_template/         # Шаблоны .agents хуков для копирования в новые репозитории
├── templates/              # Универсальные шаблоны жизненного цикла
└── templates_for_projects/ # Шаблоны под инструменты (CLAUDE.md, session-log, epic, idea-card)
```

---

## 3. Реестр активных проектов (на 31.08.2026)

| Проект | Уровень зрелости | Стек технологий | Ключевая функциональность |
|---|---|---|---|
| **MrDevCourses** | **Level 3** — Strong Educational MVP | Spring Boot 3.3 + React 19 FSD + PostgreSQL 17 (pgvector) + Bucket4j + OpenHTMLtoPDF | Учебная LMS: расчет drip-контента в SQL, гибридный RAG-тьютор (RRF), анти-чит квизы, конвейер сдачи ДЗ ментору (`/admin/homeworks`), 2-колоночный B2C лендинг. |
| **Zhan Finance (JF-1C)** | **Level 4** — Production v1.0.0 | Spring Boot 3.4 + React 19 + PostgreSQL 17 + Flyway (V1..V120) + STOMP + 2FA TOTP | B2B SaaS для бухгалтерского консалтинга: CRM Kanban, Task Pool, биллинг, документооборот, 6 ролей с Row-Level Security (`CrmAccessService`). |
| **MeDev (DevProfile)** | **Level 4** — Private Beta Live | Spring Boot 3.3 + React 19 + PostgreSQL 17 (pgvector) + Redis Valkey + Groq AI + Flying Saucer | Data-First SaaS для инженеров: парсинг GitHub API, алгоритм Smart Merge без галлюцинаций LLM, 6 шаблонов резюме, публичное портфолио (`/:username`). |
| **Valeur** | **Level 2–3** — Heavy MVP | 5 микросервисов + Spring Cloud Gateway + Groq AI (Llama 3.3 70B) + React 19 FSD | Multi-Tenant ATS-платформа: скоринг кандидатов, интерактивный Kanban с контролем SLA, Talent Pool CRM, изоляция по `TenantContext`. |
| **Envie** | **Level 3** — Personal Production OS | Spring Boot 3.4 + React 19 + Tailwind v4 + Canvas 2D + Three.js | Персональная инженерная операционная среда: плоский канбан, инкубатор идей, D3-граф заметок, 3D Wireframe Canvas. |

---

## 4. База знаний и инженерные стандарты

### Zettelkasten Knowledge Base (63+ статей)
База содержит только то, что проверено практикой и решает реальные проблемы:
- **Архитектура & Высокие нагрузки**: `arch-hybrid-rag-dense-sparse-rrf`, `arch-transactional-outbox-event-automation`, `arch-tiered-rate-limiting-bucket4j`, `arch-realtime-chat-websocket`, `jvm-metaspace-tuning`, `arch-caffeine-cache`.
- **Безопасность (Zero Trust)**: `security-idor-rls`, `sec-oauth2-stateless-cookies`, `sec-file-upload-magic-bytes`, `sec-internal-service-token`, `sec-prompt-injection-xml`, `sec-mvp-to-prod-checklist`.
- **Фронтенд & UI Deslop**: `ai-deslop-strategy-tokens-audit` (DESIGN.md-first, 4 уровня типографики), `frontend-native-fetch-interceptor`, `arch-contextual-quick-nav-drawer`, `b2c-lms-course-discovery-and-video-preview`.
- **Педагогика и Вайбкодинг**: `pedagogy-and-automation-split-for-vibe-coding` (психология трансформации идентичности 16–25 лет, дофаминовый win на Уроке 1, Error-Loop).
- **Постмортемы инцидентов**: `incident-01-flyway-github-actions-desync`, `incident-02-management-port-hibernate-crash`.

### Архитектурные принципы (вшиты в системный промпт)
```text
НИКОГДА  не менять применённые Flyway-миграции (только новые V{N}__ скрипты)
НИКОГДА  не хардкодить секреты и токены в коде
НИКОГДА  ddl-auto=update в продакшене
НИКОГДА  @PostConstruct для операций с БД — только @EventListener(ApplicationReadyEvent.class)
ВСЕГДА   FSD (Feature-Sliced Design) на фронтенде
ВСЕГДА   Zero Trust и Row-Level Security на бэкенде
ВСЕГДА   Тесты перед фиксацией журнала и пушем
```

Приоритеты при конфликте решений:  
$$\text{Security} > \text{Correctness} > \text{Performance} > \text{Code Cleanliness}$$

---

## 5. Иерархия зрелости проектов (10 уровней)

| Уровень | Обозначение | Архитектурные требования | Текущие проекты |
|---|---|---|---|
| **Level 1** | Sandbox / Playground | Эксперименты, проверка библиотек, один файл | — |
| **Level 2** | Pet Project | Локальный инструмент для себя, базовый MVC | — |
| **Level 3** | **MVP (Educational / Product)** | **Монолит, FSD, базовая безопасность, тесты ключевых узлов** | **MrDevCourses, Envie** |
| **Level 4** | **Public Beta / Production** | **CI/CD, 100% покрытие бизнес-сценариев, аудит безопасности** | **JF-1C, MeDev** |
| **Level 5** | **Traction & Stabilization** | **«ДОЛИНА СМЕРТИ»: Распил God-объектов, Rate Limiting, Staging** | **Valeur (микросервисы)** |
| **Level 6** | Validated SaaS | PMF, стабильный MRR, 99.9% uptime, Redis-кэш, Zero-downtime | — |
| **Level 7** | Scale-up | Асинхронные очереди (Kafka), кластеры БД, шардинг | — |
| **Level 8** | Mid-Market Enterprise | Strict Compliance, Audit Logs, Tenant Isolation, SLA | — |
| **Level 9** | High-Load Enterprise | Chaos Engineering, Multi-Region, Kubernetes | — |
| **Level 10** | Tech Giant | Изобретение собственных технологий, глобальный масштаб | — |

---

## 6. Мультипликатор эффективности ($4\times$ ROI)

### Почему система дает 4-кратное ускорение:
1. **Нулевой Cold-Start (0 минут на ввод в курс дела)**: Агент с первой секунды знает стек, ограничения памяти, специфику Windows/PowerShell и архитектурный стиль.
2. **Принудительная кумулятивность**: Знания и грабли фиксируются не «когда будет время», а по завершении каждого таска в силу Lifecycle Hooks.
3. **Разгрузка оперативной памяти разработчика**: Не нужно держать в голове тонкости авторизации в WebSocket, CSS-ограничения PDF-рендерера или формулы Drip-доступа — они лежат в `knowledge/`.
4. **Стандарты без силы воли**: Правила разработки защищены хуками, исключая компромиссы качества при усталости или в конце спринта.

### Границы автоматизации (Что решает система vs Человек):
- **Система снимает**: Контекстный налог, повторение старых багов, потерю решений, дрейф архитектуры и лень в документации.
- **Инженер + Тесты закрывают**: Защиту от сильных галлюцинаций LLM, выбор продуктовых приоритетов и живую работу с пользователями/студентами.

---

## 7. Быстрый старт с новым AI-агентом

### Запуск сессии одной командой:
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

## 8. Метрики репозитория

- **370+** структурированных markdown-файлов
- **63+** прикладных Zettelkasten-заметок в `knowledge/`
- **15** зафиксированных Architecture Decision Records (ADR)
- **70+** ежедневных журналов разработки (август 2026)
- **14** паспортов проектов (5 активных боевых систем)
- **1000+** автоматических тестов (JUnit + Vitest) в обслуживаемых проектах
- **4** аппаратных Lifecycle Hook (`pre-invocation`, `safety-gate`, `enforce-workflow`, `stop-check-commits`)

---

> **Brain's Protocol** — операционная система для кумулятивной разработки с искусственным интеллектом. Контекст, который не стирается.
