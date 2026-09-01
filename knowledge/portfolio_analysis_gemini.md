# Комплексный Архитектурный Анализ Всех Проектов

Данный анализ охватывает всю экосистему разработанных систем, фиксирует их инженерную зрелость, архитектурные паттерны, ключевые решённые вызовы, уровень отказоустойчивости и сквозную синергию.

---

## 1. Сводная Матрица Проектов и Архитектурных Паттернов

| Проект | Тип и Назначение | Архитектурный Паттерн | Стек (Backend / Frontend) | Уровень Зрелости | Ключевой Инженерный Вызов |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Zhan Finance (JF-1C)** | B2B SaaS CRM, Бухгалтерия и Биллинг | Модульный монолит (14 модулей, 36 сущностей) | Java 17, Spring Boot 3.4, Postgres 17, Flyway (V1..V120) / React 19, TS, FSD, STOMP | **Level 4** (Production Traction, 545 коммитов) | Row-Level Security на 6 ролей, 2FA TOTP, генерация PDF актов/счетов, zero N+1, неизменяемый аудит. |
| **MeDev (DevProfile)** | Data-First AI SaaS для разработчиков | Модульный монолит (10 модулей, L1/L2 Cache) | Spring Boot 3.3, Postgres 17, Redis Valkey 8.1, Groq / React 19, TS, FSD, Tailwind v4 | **Level 4** (Pre-Launch / Live на Vercel & Render) | GitHub API парсер, Smart Merge PDF резюме без галлюцинаций, SSE-стриминг LLM, 6 ATS-тем. |
| **Valeur** | Multi-Tenant Distributed ATS & AI Hiring | Микросервисы (5 сервисов + Spring Cloud Gateway) | Spring Boot 3.3, Cloud Gateway, Postgres 16 (4 схемы), Groq / React 19, FSD, Native Fetch | **Level 2–3** (Heavy Pre-Release MVP) | Изоляция данных компаний (`TenantContext` ThreadLocal), межсервисный `X-Internal-Token`, ATS-скоринг. |
| **MrDevCourses** | Educational LMS & Vibe-Coding Platform | Модульный монолит (10 доменов, RAG + Grader) | Spring Boot 3.3, pgvector, Bucket4j, OpenHTMLtoPDF / React 19, TS, FSD, Tailwind v4 | **Level 3** (Strong Educational MVP, 100% Green) | Гибридный RAG (HNSW + FTS RRF), AI Code Grader с AST-сканером, Anti-Cheat квизы, DB-calculated Drip. |
| **Envie** | Personal Headquarters & Knowledge OS | Local-First Monolith (Zero-Latency, No-Cloud) | Spring Boot 3.4, Postgres 17, Flyway (V1..V7) / React 19, FSD, Canvas 2D, Three.js | **Level 3** (Personal Production Engine) | Отклик <15ms, 3D Wireframe Canvas глобус без WebGL-сбоев, графовая визуализация D3, Emil Kowalski UX. |
| **testCinema & Bot** | Киноплатформа с ML / Чистый JDBC бот | Полиглотный монолит (Spring + FastAPI) / Raw JDBC | Java, Python (FastAPI), Docker / React, FSD \| Core Java, Raw JDBC, Postgres | **Завершены** (Дипломный проект & Фундамент) | Межъязыковая интеграция (Java-Python), рекомендательная модель, управление транзакциями и пулом вручную. |

---

## 2. Детальный Инженерный Разбор Систем

```
                                  [ ЭКОСИСТЕМА ПРОЕКТОВ ]
                                             │
      ┌────────────────────────┬─────────────┴────────────┬────────────────────────┐
      ▼                        ▼                          ▼                        ▼
 [ B2B Enterprise ]     [ Data-First AI ]       [ Distributed ATS ]     [ Education & OS ]
  Zhan Finance (JF-1C)    MeDev (DevProfile)           Valeur             MrDevCourses / Envie
   - 6 Ролей & 2FA        - GitHub Source of Truth    - 5 Микросервисов    - Hybrid RAG (pgvector)
   - Flyway V1-V120       - Smart Merge & L1/L2       - TenantContext RLS  - AI Grader & AST Guard
   - WebSocket STOMP      - Reactive SSE Stream       - Gateway JWT Flow   - Local-First 2D Canvas
```

---

### 2.1. Zhan Finance (JF-1C) — Флагманский B2B SaaS
- **Бизнес-домен**: Автоматизация бухгалтерского аутсорсинга, биллинга и операционной CRM.
- **Архитектурный фундамент**: 
  - Высокоорганизованный модульный монолит: 14 модулей, 36 сущностей, 29 контроллеров, 63 страницы фронтенда.
  - Матрица на 6 ролей (`ADMIN`, `EMPLOYEE`, `CLIENT`, `LEARNER`, `CURATOR`, `ADVISOR`) со сквозной RLS-фильтрацией через `CrmAccessService`.
  - Надежность данных: Неизменяемая цепочка из **120 миграций Flyway**, триггеры PostgreSQL для защиты audit-логов от модификации, маскирование чувствительных данных (`[PROTECTED]`).
- **Сложные инженерные решения**:
  - Двухфакторная аутентификация (TOTP) с защитой от перебора через `two_factor_pre_auth` и автоматической фоновой ротацией refresh-токенов в Redis/DB.
  - Устранение N+1 проблем через `@EntityGraph`, `@BatchSize` и батч-обработку сообщений в STOMP-каналах.
  - Документооборот: Векторная генерация актов и счетов (OpenHTMLtoPDF + Thymeleaf) с поддержкой кириллицы и выгрузкой в ZIP.

---

### 2.2. MeDev (DevProfile) — Data-First AI SaaS для Инженеров
- **Бизнес-домен**: Единый источник правды (Single Source of Truth) для карьеры разработчика без галлюцинаций LLM.
- **Архитектурный фундамент**:
  - Агрегация данных через GitHub GraphQL API (коммиты, байты языков, топология репозиториев) как верифицированный первоисточник.
  - Алгоритм **Smart Merge**: Интеллектуальное слияние старых PDF-резюме и актуальных данных GitHub с гарантией сохранения наработок.
- **Сложные инженерные решения**:
  - **Двухуровневое кэширование (L1 + L2)**: Локальный In-Memory Caffeine (регионы `profiles`, `public-profiles`) для sub-millisecond отдачи + распределённый Redis Valkey 8.1 для сессий и токенов.
  - Транзакционная инвалидация кэша через `TransactionSynchronizationManager.afterCommit()`.
  - Потоковый реактивный AI-генератор контента (Groq API, Server-Sent Events) с детерминированной отпиской `Disposable.dispose()`.

---

### 2.3. Valeur — Распределенная Мультитенантная ATS Платформа
- **Бизнес-домен**: Автоматизация подбора персонала, интеллектуальный скоринг кандидатов и Talent Pool CRM.
- **Архитектурный фундамент**:
  - Топология из 5 изолированных сервисов (`identity`, `vacancy`, `application`, `ai`, `api-gateway`).
  - Spring Cloud Gateway 4.x с санитизацией входящих заголовков, валидацией JWT и пробросом метаданных `X-Tenant-Id`, `X-User-Id`, `X-User-Role`.
- **Сложные инженерные решения**:
  - Мультитенантная изоляция: `TenantContext` на базе `ThreadLocal` с автоматической фильтрацией запросов на уровне SQL/JPA по схемам PostgreSQL.
  - Межсервисная безопасность: Защита внутренних вызовов `RestClient` сервисным токеном `X-Internal-Token` и фильтром `InternalTokenFilter`.
  - Отказоустойчивый ATS-скоринг: Структурированный JSON-парсинг ответа Groq Llama 3.3 70B с эвристическим fallback-алгоритмом при сбоях AI.

---

### 2.4. MrDevCourses — Платформа Обучения & Вайбкодинга
- **Бизнес-домен**: Обучение промышленной разработке с AI-наставничеством и автоматической аттестацией.
- **Архитектурный фундамент**:
  - Модульный монолит (10 доменов), строгая темная дизайн-система (`#0a0a0c`), 100% тестовое покрытие (63 Vitest + 21 JUnit E2E).
  - Расчёт Drip-контента на уровне СУБД: `(NOW() - enrolled_at) >= ((day_number - 1) * INTERVAL '1 day')`.
- **Сложные инженерные решения**:
  - **Гибридный RAG**: Совмещение Dense Cosine Search (`pgvector` HNSW) и Sparse FTS (`tsvector`) через алгоритм Reciprocal Rank Fusion (RRF) в единой базе PostgreSQL.
  - **AI Code Grader**: Статический AST-сканер безопасности (блокировка `Runtime.exec`, `ProcessBuilder`, `System.exit`, бесконечных циклов) перед отправкой в LLM-рубрикатор.
  - **Quiz Anti-Cheat**: Серверная валидация квизов с маскировкой правильных ответов на уровне DTO.

---

### 2.5. Envie — Персональная Инженерная ОС (Local-First)
- **Бизнес-домен**: Автономный командный центр архитектора (заметки, канбан, инкубатор идей, база Markdown).
- **Архитектурный фундамент**:
  - Полный отказ от облачной телеметрии и сторонней авторизации — мгновенный отклик (<15ms).
- **Сложные инженерные решения**:
  - **3D Wireframe Canvas Globe**: Проекционный 3D-движок на HTML5 2D Canvas без использования WebGL (100% совместимость со старыми GPU и мобильными устройствами без сбоев).
  - Three.js Helix-навигация и D3 Force-Graph связей Markdown-шаблонов.
  - Физика интерфейса по стандартам Эмиля Ковальски: анимации исключительно через `transform` и `opacity` (sub-300ms, `active:scale-95`).

---

### 2.6. Фундаментальный Опыт (testCinema & Football Bot)
- **testCinema**: Опыт 10-месячной эксплуатации полиглотного монолита (Spring Boot бэкенд + FastAPI ML-сервисы рекомендаций и перевода + React FSD).
- **Football Bot**: Программирование на чистом Core Java + Raw JDBC без ORM, заложившее глубокое понимание механики транзакций, пулов соединений HikariCP и стоимости абстракций.

---

## 3. Сквозной Срез Архитектурного Мастерства

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ТЕХНИЧЕСКИЙ СТЕК И СТАНДАРТЫ                           │
├──────────────────────┬──────────────────────────────┬───────────────────────┤
│ Backend & Data       │ Security & Resilience        │ Frontend & UX         │
├──────────────────────┼──────────────────────────────┼───────────────────────┤
│ • Java 17 / Spring 3 │ • Stateless JWT httpOnly     │ • React 19 / Vite     │
│ • PostgreSQL 17      │ • Row-Level Security (RLS)   │ • FSD 2.1 (Strict)    │
│ • pgvector (HNSW)    │ • 2FA TOTP (Brute-force prot)│ • Tailwind CSS v4     │
│ • Flyway (V1..V120)  │ • 3-Tier Bucket4j Limiting   │ • TanStack Query v5   │
│ • L1 Caffeine / Redis│ • Static AST Security Scanner│ • @dnd-kit (No races) │
│ • Transaction Outbox │ • Anti-Cheat Quiz Protection │ • HTML5 Canvas 2D/3D  │
│ • Zero N+1 Queries   │ • Immutable Audit Triggers   │ • Sub-300ms Motion    │
└──────────────────────┴──────────────────────────────┴───────────────────────┘
```

### 1. Работа с Данными и Базами
- **Flyway-дисциплина**: Неизменяемость применённых скриптов, строгое версионирование схемы (от V7 в Envie до V120 в JF-1C).
- **Производительность**: Исключение N+1 через `@EntityGraph`, батч-выборки `IN (...)`, многоуровневое кэширование (Caffeine + Redis) и транзакционная инвалидация.
- **Векторные данные**: Использование `pgvector` HNSW внутри PostgreSQL для исключения накладных расходов на отдельные векторные БД.

### 2. Безопасность (Defense-in-Depth)
- **Zero-Trust к клиентским ID**: Защита от IDOR через получение `currentUserId` исключительно из валидированного токена.
- **Stateless Сессии**: Токены в защищённых `httpOnly` + `SameSite=Lax` cookies.
- **Защита ресурсов**: Многоуровневый Rate Limiting на Bucket4j (Auth, AI, General) для защиты от DoS и исчерпания LLM-квот.

### 3. AI-Инженерия без Галлюцинаций
- **RAG Grounding**: Жёсткое заземление ответов в локальный контекст уроков и профилей через AST-чанкинг и Reciprocal Rank Fusion.
- **Structured JSON Mode**: Строгий парсинг ответов моделей (Llama 3.3 70B) с валидацией DTO и деградацией на эвристические алгоритмы.
- **Защита от инъекций**: Санитизация пользовательского ввода и XML-экранирование промптов.

### 4. Фронтенд-Инженерия (Feature-Sliced Design)
- **Строгая FSD-модульность**: Полная изоляция бизнес-логики по слоям (`app` → `pages` → `widgets` → `features` → `entities` → `shared`).
- **Высокая стабильность UI**: Предотвращение race conditions при drag-and-drop (`@dnd-kit`), оптимистичные обновления в React Query, строгая типизация TypeScript (0 `any`).

---

## 4. Итоговое Заключение

Вся линейка проектов демонстрирует эволюцию от глубокого понимания низкоуровневых механизмов (Raw JDBC, транзакции, сокеты) к проектированию масштабируемых B2B/B2C платформ уровня **Level 3–4**:
1. **JF-1C** доказывает способность строить защищенные Enterprise B2B системы с комплексным финансовым и ролевым контуром.
2. **MeDev** подтверждает компетенции в интеграции внешних API, сложном кэшировании (L1/L2) и построении data-first SaaS продуктов.
3. **Valeur** демонстрирует владение распределенными микросервисами и мультитенантной изоляцией данных.
4. **MrDevCourses** подтверждает экспертизу в AI-пайплайнах (RAG, AST-грейдинг, анти-чит) и B2C-продуктовой воронке.
5. **Envie** демонстрирует способность создавать локальные инструменты с бескомпромиссным UX и легковесной графикой.
