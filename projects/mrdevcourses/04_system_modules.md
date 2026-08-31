# 4. Модули системы MrDevCourses

### 4.1 Auth & Rate Limiting Module
- Google OAuth2 + Email/Password вход, JWT в `httpOnly` + `SameSite=Lax` cookies.
- Row-Level Security через `SecurityUtils.getCurrentUserId()`.
- 3-уровневый Bucket4j Rate Limiter: Auth (10/15 мин), AI (5/мин), General (60/мин).
- Эндпоинты: `GET /api/v1/auth/me`, `POST /api/v1/auth/logout`, `POST /api/v1/auth/register`, `POST /api/v1/auth/login`.

### 4.2 Course & B2C Discovery Module
- B2C витрина (`/courses`) с фильтр-баром `[Поиск] [Уровень] [Формат]` и hover-трейлерами.
- 2-колоночный лендинг курса (`/courses/:slug`) с аккордеоном модулей, плашкой автора (**Mr Developer**), блоками «Чему вы научитесь», «Требования», FAQ и плавающей карточкой записи (`CourseStickyCard`).
- Эндпоинты: `GET /api/v1/courses`, `GET /api/v1/courses/{slug}`, `POST /api/v1/courses/{courseId}/enroll`.

### 4.3 Lesson & Materials Module
- Drip-контент с расчётом доступа на лету: `(NOW() - enrolled_at) >= ((day_number - 1) * INTERVAL '1 day')`.
- Поддержка типов уроков: `VIDEO` (YouTube embed), `ARTICLE` (Markdown), `PRACTICE`, `QUIZ`.
- Вложения материалов: `CHEAT_SHEET`, `SOURCE_CODE`, `REPO_LINK`, `PDF`, `DOCUMENTATION`.
- Эндпоинты: `GET /api/v1/courses/{courseId}/lessons`, `GET /api/v1/courses/{courseId}/lessons/{lessonId}`, `POST /api/v1/courses/{courseId}/lessons/{lessonId}/complete`.

### 4.4 Quiz Assessment Engine Module
- Интерактивные тесты с маскировкой правильных ответов (`isCorrect` не возвращается в API до сабмита).
- Автоматический подсчёт баллов на бэкенде, проверка `passingScore` (70%) и авто-завершение урока.
- Эндпоинты: `GET /api/v1/lessons/{lessonId}/quiz`, `POST /api/v1/lessons/{lessonId}/quiz/submit`.

### 4.5 Progress, Streak & Roadmap Module
- Личный кабинет: текущий стрик активности, календарь доступности уроков, визуальная дорожная карта (`VisualRoadmap`).
- Расчет времени открытия следующего урока (`nextUnlockAt` в UTC).
- Эндпоинты: `GET /api/v1/progress`, `GET /api/v1/progress/{courseId}`.

### 4.6 AI RAG & Contextual Tutor Module
- Гибридный поиск: Dense Cosine (`pgvector` HNSW) + Sparse FTS (`tsvector`) через алгоритм Reciprocal Rank Fusion (RRF).
- AST-aware chunking конспектов с сохранением блоков кода.
- LLM-тьютор на базе Groq Llama 3.3 70B с заземлением в контекст урока и защитой от инъекций.
- Эндпоинты: `POST /api/v1/ai/tutor/ask`.

### 4.7 AI Code Grader & Reviewer Module
- Статический сканер безопасности на запрещённые конструкции Java AST (`Runtime.exec`, `ProcessBuilder`, `System.exit`, `Unsafe`).
- LLM-оценка практических ДЗ по 4 рубрикам (Корректность, Архитектура, Безопасность, Чистота кода).
- Авто-завершение урока при оценке `>= 80/100`.
- Эндпоинты: `POST /api/v1/lessons/{lessonId}/homework/submit`.

### 4.8 Certificate & Verification Module
- Векторная генерация PDF-сертификата (Thymeleaf + OpenHTMLtoPDF) при 100% прохождении курса.
- Публичная страница проверки подлинности по уникальному 12-значному коду.
- Эндпоинты: `GET /api/v1/certificates/my`, `GET /api/v1/certificates/{id}/download`, `GET /api/v1/certificates/verify/{code}`.

### 4.9 Transactional Outbox & Automation Module
- Гарантированная доставка событий без внешних брокеров через `outbox_events` и фоновый `@Scheduled` воркер.
- Фоновый анализ вовлеченности студентов и авто-связывание терминов глоссария.

### 4.10 Admin Suite & Telemetry Module
- Изолированный лейаут `AdminLayout` (`#0a0a0c`).
- Визуальный редактор курсов (Drag-and-Drop модулей, Markdown-редактор, YouTube-валидатор, конструктор квизов).
- Консоль студентов (поиск, переключение ролей `STUDENT <-> ADMIN`, ручное зачисление, шторка прогресса).
- Дашборд когортной аналитики, графики удержания, топ запросов к AI и неизменяемый журнал системного аудита.
- Эндпоинты: `/api/v1/admin/**` с защитой `@PreAuthorize("hasRole('ADMIN')")`.
