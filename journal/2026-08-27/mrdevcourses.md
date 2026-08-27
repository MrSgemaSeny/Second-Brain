# Journal: 2026-08-27 — MrDevCourses Enterprise Scaling, Vectorization & Automation

## Overview
Комплексное расширение и масштабирование образовательной платформы MrDevCourses:
1. Hardened Enterprise Release (Bucket4j Rate Limiter, Quick-Nav Drawer, PDF Certificates, Admin Analytics Dashboard).
2. Enterprise Vectorization & Automation Subsystems (pgvector Hybrid RAG, Semantic AST Chunking, Automated AI Code Grader / Reviewer, Semantic Auto-linking, Transactional Outbox & Lifecycle Engine).

---

## 1. Релиз ключевых модулей

### [R1] Enterprise Security & Rate Limiting (Donor: JF-1C)
- Интегрирован промышленный Token Bucket лимитер на базе **Bucket4j + Caffeine Cache** (`RateLimiterService`, `RateLimitingFilter`).
- Гранулированные политики: Auth (10 req/15m/IP), AI (5 req/1m/user), General (60 req/1m/user/IP).

### [R2] Contextual Navigation & Quick-Nav Drawer (Donor: JF-1C)
- Боковой выдвижной ящик **QuickNavDrawer** (`GlossaryView`, `ProgressView`, `RoadmapView`).
- Контекстный глоссарий терминов к урокам (`LessonContextPanel`) с возможностью поиска без прерывания видеоплеера.

### [R3] Hybrid Vector RAG & Senior AI Tutor (pgvector + HNSW + RRF)
- Миграция `V10__add_vectorization_and_automation.sql` с расширениями `vector` и `pg_trgm`.
- HNSW-индексация векторных представлений уроков и глоссария (`vector(1536)`).
- **MarkdownSemanticChunker**: AST-aware разбиение материалов уроков с сохранением неделимости блоков кода и классификацией типов чанков (`THEORY`, `CODE`, `GLOSSARY`, `HOMEWORK`).
- **EmbeddingService**: батчевая нормализованная векторизация и расчет косинусного сходства.
- **HybridSearchService**: гибридный поиск (Dense Cosine Similarity + Sparse BM25-like Text Search) с объединением результатов по алгоритму **Reciprocal Rank Fusion (RRF)**.
- Инъекция семантических фрагментов с цитатами первоисточника (`AiCitation`) в промпт Groq Llama 3.3 70B.

### [R4] Automated AI Code Grader & Reviewer
- Модуль сдачи практических заданий `modules/homework` (`HomeworkSubmission`, `AiCodeGraderService`, `HomeworkController`).
- Статический анализатор безопасности: выявление захардкоженных секретов, конкатенации SQL и опасных вызовов Runtime.
- Оценка решения через LLM с выставлением баллов (0-100), выявлением сильных сторон и замечаний уровня Senior Tech Lead.
- Автоматический зачет урока (`LessonService.completeLesson`) при прохождении порога &ge; 80 баллов.
- Интерактивный фронтенд-виджет `HomeworkSubmissionWidget` с редактором кода, историей сдачи и разбором ревью.

### [R5] Transactional Outbox & Lifecycle Automation
- Паттерн **Transactional Outbox** (`outbox_events`, `OutboxService`, `OutboxProcessor`) с обработкой по расписанию для надежной асинхронной доставки событий (векторизация курсов, синк глоссария).
- **SemanticLinkingService**: автоматическое связывание терминов глоссария с материалами уроков.
- **StudentLifecycleService**: мониторинг студентов с риском отвала (>48ч неактивности на открытых уроках) и генерация умных триггеров возврата.
- Админ-эндпоинты управления очередями Outbox и аналитики рисков (`AutomationAdminController`).

### [R6] Automated PDF Certificate Generation & Cohort Analytics
- Генерация PDF сертификатов (Thymeleaf + OpenHTMLtoPDF) с верификацией по коду.
- Когортная аналитика и воронка конверсий по дням курса.

---

## 2. Результаты автоматизированного тестирования
- **Backend**: 112/112 unit & integration tests **100% GREEN** (`BUILD SUCCESSFUL`, `:jacocoTestReport` verified).
- **Frontend**: 34/34 Vitest tests **100% GREEN** (12/12 test suites passed).
- **TypeScript / Build**: `npm run build` — 0 errors, 0 warnings, production chunks built in 7.46s.

---

## 3. Правило Workflow
`ТЕСТЫ ПРОШЛИ -> ЗАПИСЬ В ЖУРНАЛ -> ОБНОВЛЕНИЕ CONTEXT.MD -> GIT PUSH`
Все тесты зеленые, лог записан, контекст синхронизирован.
