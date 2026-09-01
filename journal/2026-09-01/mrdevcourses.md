# Журнал разработки — MrDevCourses (2026-09-01)

---

### 1.1. Security Hardening: Защита стены проектов (`/projects`) и 1-User-1-Like Toggle
- Создана Flyway миграция `V20__create_project_likes_table.sql`:
  - Таблица `project_likes` с внешними ключами на `project_showcases(id)` и `users(id)` и ограничением `UNIQUE (project_id, user_id)`.
- Созданы JPA сущность `ProjectLike` и репозиторий `ProjectLikeRepository`.
- `ProjectShowcaseService.toggleLike(userId, projectId)`:
  - Реализован механизм toggle (повторный клик снимает лайк с декрементом счетчика).
  - При `getAllShowcases(currentUserId)` возвращается персональный флаг `hasLiked: boolean`.
- `ProjectShowcaseController`:
  - `POST /api/v1/projects/{id}/like` защищен `@PreAuthorize("isAuthenticated()")`.
  - В `SecurityConfig.java` снят `permitAll` для POST лайков.
- `ProjectsPage.tsx`:
  - Интерактивная кнопка лайка с индикацией состояния `hasLiked`.
  - При клике неавторизованного пользователя происходит безопасный редирект на `/login`.

### 1.2. Frontend Resilience: Suspense для защищенных роутов
- В `router/index.tsx` все защищенные роуты (`/courses`, `/courses/:slug`, `/courses/:cId/lessons/:lId`, `/dashboard`) обернуты в `wrap()` с `<Suspense fallback={<PageLoader />}>`, предотвращая падение React при задержках сети.

### 1.3. Student Profile Page & Settings (`/profile`)
- **Flyway Миграция V21** (`V21__add_profile_fields_to_users.sql`):
  - Добавлены колонки `telegram_username`, `github_username`, `bio`, `goal` в таблицу `users`.
- **Бэкенд**:
  - Обновлена сущность `User` и `CertificateRepository.countByUserId`.
  - Созданы `UserProfileDto`, `UpdateUserProfileRequest`, `UserProfileService` и `UserProfileController` (`GET /v1/users/profile`, `PUT /v1/users/profile`).
  - Автоматическая очистка символа `@` из Telegram и GitHub никнеймов при сохранении.
  - Подсчет агрегированных метрик студента (`enrolledCoursesCount`, `completedLessonsCount`, `certificatesCount`).
  - Тесты: `UserProfileControllerTest` (4 теста: GET/PUT с авторизацией, отказ 401 для анонимов, валидация).
- **Фронтенд**:
  - Создана страница `ProfilePage.tsx` в строгом GitHub-стиле (`#0d1117`, `#0e0e11`, `#18181b`).
  - Сетка статистики (текущий и рекордный стрик, пройденные уроки, курсы, сертификаты выпускника).
  - Редактирование профиля: Имя, аватар с живым предпросмотром, Telegram для ментора, GitHub, цель обучения с быстрыми пресетами и Bio.
  - Добавлен пункт «Профиль и настройки» в `UserProfileDropdown.tsx`.
  - Тесты: `ProfilePage.test.tsx` (2 теста).

### 1.4. AI Context Guards: Системный манифест и PowerShell Prompt Injection Hook
- **Системный манифест (`.agents/AGENTS.md`)**:
  - Добавлены XML-теги `<CRITICAL_INSTRUCTIONS>` со строгим запретом консольных CLI-утилит (cat, grep, ls, dir, head, tail, sed, awk) через `run_command` в пользу нативных API-тулов.
  - Категорический запрет любых эмодзи во всех ответах, коде, коммитах и логах.
  - Обязательное требование перечитывать `AGENTS.md` при сомнениях.
- **PowerShell Prompt Injection Hook (`.agents/prompt-guard.ps1`)**:
  - Функция `prompt` внедряет директивы в поток `[Console]::Error.WriteLine()`.
  - При каждом выполнении команды ИИ получает напоминание в конце `stderr` и держит контекст без галлюцинаций.
- **Инсталлятор (`setup-ai-guards.ps1`)**:
  - Безопасно инжектирует хук в профиль PowerShell (`$PROFILE`) с маркерами `# >>> AI GUARDS HOOK >>>` без перезаписи пользовательских настроек.

### 1.5. Hardening инфраструктуры хуков и устранение замечаний аудита
- **`safety-gate.ps1`**:
  - Расширен regex блокировки для PowerShell-утилит (`Get-Content`, `gc`, `type`, `Select-String`, `sls`, `Get-ChildItem`, `gci`, `dir`).
  - Добавлено явное исключение для легитимных команд `git` (`git grep`, `git log`, `git status`).
- **`stop-check-commits.ps1` & `enforce-workflow.ps1` & `pre-invocation.ps1`**:
  - Устранен хардкод путей — внедрено динамическое разрешение путей к `MrDevCourses` и `Brain's protocol - second brain` через `$PSScriptRoot` и `$env:USERPROFILE`.
- **`pre-invocation.ps1`**:
  - Добавлен lightweight reminder (`[AI GUARD] Active Session`) для повторных вызовов (`invocationNum > 1`) для непрерывного удержания контекста без раздувания токенов.
  - Внедрен автоконтроль размера `CONTEXT.md` (предупреждение при >200 строк).
- **`CONTEXT.md`**:
  - Добавлен раздел `## Current Operational Focus` в самое начало файла для мгновенной ориентации агента при старте сессии.

### 1.6. Persistent Auth Sessions & Remember-Me (7-Day Standard, 30-Day Extended, No F5 Drop)
- **Проблема**: При обновлении страницы (F5) или истечении суток сессия сбрасывалась и пользователя выбрасывало на страницу логина из-за короткого 24-часового TTL токена и отсутствия оптимистичной гидратации.
- **Бэкенд**:
  - `application.yml`: Стандартный срок жизни JWT увеличен до 7 дней (`expiration-ms: 604800000`), добавлен параметр для долгоживущей сессии на 30 дней (`remember-me-expiration-ms: 2592000000`).
  - `JwtTokenProvider`: Реализована поддержка `rememberMeExpirationMs` и методы генерации токенов с claim `rememberMe`. Добавлен `@Autowired` на DI-конструкторе.
  - `JwtCookieHelper`: Добавлен метод `addJwtCookie(response, token, rememberMe)` с вычислением `maxAge` для 7 дней или 30 дней.
  - `LoginRequest` / `RegisterRequest`: Добавлено поле `private Boolean rememberMe = false;`.
  - `EmailAuthService`: Чтение флага `rememberMe` из DTO и передача в генератор токенов и CookieHelper.
  - `OAuth2AuthenticationSuccessHandler`: Автоматическая выдача 30-дневной сессии (`rememberMe = true`) для входа через Google OAuth2.
  - Тесты: `JwtTokenProviderTest` (тест токена с rememberMe и 30-дневным сроком), `OAuth2AuthenticationSuccessHandlerTest`.
- **Фронтенд**:
  - `authContext.tsx`: Внедрена оптимистичная гидратация стейта пользователя из `localStorage` (`mrdev_user_session`). При перезагрузке страницы (F5) `user` мгновенно доступен в `useAuth()`, что полностью исключает ложные редиректы `ProtectedRoute` на `/auth` во время фонового выполнения `checkAuth()`. При получении 401 кэш очищается и происходит корректный логаут.
  - `userApi.ts`: Поддержка передачи флага `rememberMe` в `loginWithEmail` и `register`.
  - `EmailAuthForm.tsx`: Добавлен аккуратный чекбокс «Запомнить меня на 30 дней» (по умолчанию активен), стилизованный под Design System платформы.
- **Верификация**:
  - Backend: 221/221 JUnit тестов пройдены успешно (100% Green).
  - Frontend: 73/73 Vitest тестов пройдены успешно (100% Green).
  - Build: `tsc -b && vite build` успешно собран (1798 модулей, 0 ошибок).

### 1.6. Архивирование legacy-хуков в базу знаний и очистка .agents/scripts
- Создана архитектурная заметка в базе знаний Second Brain: `knowledge/antigravity-hooks-and-guardrails-evolution.md` с сохранением полного исходного кода `reminder.ps1` и `git-reminder.ps1`, контекста их 3-месячного использования и обоснованием перехода к hard guardrails.
- Обновлен `knowledge-index.md` во Втором Мозге.
- Удалены неиспользуемые файлы `reminder.ps1` and `git-reminder.ps1` из `.agents/scripts/`, обеспечив 100% соответствие `hooks.json`.

---

### 1.6. Phase 3: Common Pitfalls FAQ in Lessons & Drop-off Funnel Telemetry
- **Flyway Migration V22** (`V22__create_lesson_pitfalls_table.sql`):
  - Таблица `lesson_pitfalls` с полями `lesson_id`, `title`, `error_symptom`, `solution_markdown`, `order_index`, `created_at` с `ON DELETE CASCADE`.
- **Бэкенд**:
  - Создана JPA сущность `LessonPitfall` с аннотацией `@OnDelete(action = OnDeleteAction.CASCADE)` для полной совместимости с H2 и PostgreSQL.
  - Созданы `LessonPitfallRepository`, `LessonPitfallDto`, `LessonPitfallService`, и `LessonPitfallController` (`GET /v1/courses/{courseId}/lessons/{lessonId}/pitfalls`).
  - Добавлены методы в `HomeworkSubmissionRepository`: `countByLessonId` и `countByLessonIdAndStatus`.
  - Обогащен DTO воронки `CourseFunnelStepDto` метриками `hwSubmissionsCount`, `hwRejectionsCount`, `isBottleneck`.
  - Обновлен `AdminAnalyticsService.getCourseFunnel` с расчетом конверсии, отвала и детекцией узких мест курса.
  - Создан контроллер-тест `LessonPitfallControllerTest` (2 теста, 100% Green).
- **Фронтенд**:
  - Создан компонент `LessonPitfallsAccordion.tsx` (`@/widgets/lesson-pitfalls/ui/LessonPitfallsAccordion`) с поиском ошибок, терминальным блоком симптома и копированием решения.
  - Интегрирован аккордеон граблей и типичных ошибок в `LessonPage.tsx`.
  - Обновлен `lessonApi.ts` с методом `getPitfalls`.
  - Все тесты фронтенда (73/73) и production build (`npm run build`) успешно пройдены.

---

### Статус Верификации:
- **Backend (JUnit)**: 220/220 тестов Green (100%).
- **Frontend (Vitest)**: 73/73 тестов Green (100%).
- **Production Build**: 0 ошибок (4.35s).
- **AI Guards & Hooks**: Полностью протестированы, legacy-скрипты заархивированы в Zettelkasten.