# Journal: 2026-08-27 — MrDevCourses Enterprise Scaling, Vectorization & Domain Hierarchy

## Overview
Комплексное расширение и масштабирование образовательной платформы MrDevCourses:
1. Hardened Enterprise Release (Bucket4j Rate Limiter, Quick-Nav Drawer, PDF Certificates, Admin Analytics Dashboard).
2. Enterprise Vectorization & Automation Subsystems (pgvector Hybrid RAG, Semantic AST Chunking, Automated AI Code Grader / Reviewer, Semantic Auto-linking, Transactional Outbox & Lifecycle Engine).
3. Hotfix Routing & DDL: устранено дублирование префикса контекстного пути (`/api/v1` -> `/v1` в контроллерах) и нормализована совместимость схемы `V10` с валидацией Hibernate.
4. Enterprise Domain Hierarchy & Interactive Assessment (Flyway `V11`, `CourseModule`, `LessonMaterial`, `Quiz`, `QuizQuestion`, `QuizSubmission`, `Cohort`, `LessonQuizWidget`, `LessonMaterialsList`).

---

## 1. Релиз ключевых модулей

### [R1] Enterprise Security & Rate Limiting (Donor: JF-1C)
- Интегрирован промышленный Token Bucket лимитер на базе **Bucket4j + Caffeine Cache** (`RateLimiterService`, `RateLimitingFilter`).
- Гранулированные политики: Auth (10 req/15m/IP), AI (5 req/1m/user), General (60 req/1m/user/IP).

### [R2] Contextual Navigation & Quick-Nav Drawer (Donor: JF-1C)
- Боковой выдвижной ящик **QuickNavDrawer** (`GlossaryView`, `ProgressView`, `RoadmapView`).
- Контекстный глоссарий терминов к урокам (`LessonContextPanel`) с возможностью поиска без прерывания видеоплеера.

### [R3] Hybrid Vector RAG & Senior AI Tutor (pgvector + HNSW + RRF)
- Миграция `V10__add_vectorization_and_automation.sql` с безопасной обработкой расширений `vector` и `pg_trgm`.
- HNSW-индексация и хранение векторных представлений уроков и глоссария.
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

### [R6] Enterprise Domain Hierarchy, Materials & Quizzes (LMS Architecture)
- Миграция `V11__expand_domain_hierarchy.sql`:
  - Иерархия модулей: `course_modules` (главы курса, группировка уроков, флаг free-preview).
  - Расширение сущности уроков: `lesson_type` (VIDEO, ARTICLE, PRACTICE, QUIZ), `duration_minutes`, `is_free_preview`, `materials`.
  - Прикрепляемые материалы: `lesson_materials` (чит-листы, репозитории, документация, PDF).
  - Банк вопросов и тестирование: `quizzes`, `quiz_questions`, `quiz_question_options`, `quiz_submissions`.
  - Потоки обучения: `cohorts` (привязка групп студентов к датам запуска).
- `QuizService` & `QuizController`: безопасная выдача вопросов со скрытием правильных ответов (`QuizOptionDto`), серверная верификация, скоринг и авто-зачет урока при результате &ge; 80%.
- Фронтенд: `LessonQuizWidget` (интерактивный тест с таймером, выбором ответов, разбором ошибок и пояснениями), `LessonMaterialsList` (каталог файлов и ссылок), аккордеон модулей на `CourseDetailPage`.

---

## 2. Результаты автоматизированного тестирования
- **Backend**: 118/118 unit & integration tests **100% GREEN** (`BUILD SUCCESSFUL in 57s`, `:jacocoTestReport` verified).
- **Frontend**: 35/35 Vitest tests **100% GREEN** (13/13 test suites passed).
- **TypeScript / Build**: `npm run build` — 0 errors, 0 warnings, production chunks built in 4.05s.

---

## 3. Правило Workflow
`ТЕСТЫ ПРОШЛИ -> ЗАПИСЬ В ЖУРНАЛ -> ОБНОВЛЕНИЕ CONTEXT.MD -> GIT PUSH`
Все тесты зеленые, лог записан, контекст синхронизирован.
