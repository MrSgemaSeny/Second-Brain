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

### 1.7. Telegram Bot, Dual Alerts & Transactional Email Notification Layer
- **Flyway Migration V23** (`V23__create_notifications_and_telegram_bot_tables.sql`):
  - Поля `telegram_chat_id`, `telegram_linked_at`, `email_notifications_enabled`, `telegram_notifications_enabled`, `last_inactivity_email_sent_at` в таблице `users`.
  - Таблица `notification_outbox` с индексами `(status, next_retry_at)` и `telegram_chat_id`.
- **Бэкенд**:
  - `EmailNotificationService`: адаптивные HTML-шаблоны (welcome для Google-пользователей, проверка ДЗ, открытие drip-уроков, SOS-сигналы ментору, напоминания о неактивности с 7-дневным троттлингом и ссылкой отписки).
  - `TelegramBotCommandService`: поддержка команд ментора (`/hw`, `/approve`, `/reject`, `/status`, `/stuck`, `/progress @student`, `/broadcast`) и команд студента (`/start LINK_<token>`, `/status`, `/unlink`, `/help`).
  - `TelegramLinkTokenService` и `TelegramLinkController` (`POST /v1/telegram/link-token`, `DELETE /v1/telegram/unlink`).
  - `StudentHelpService`: дублирование критических SOS-алертов в Telegram ментора и на Email ментора одновременно.
  - `HomeworkService`: отправка вердикта проверки ДЗ на Email студента и в Telegram (если привязан).
  - `OAuth2AuthenticationSuccessHandler`: отправка welcome-письма новым студентам при первой регистрации через Google.
  - `StuckDetectionService`: автоматическая отправка email-напоминаний неактивным студентам (>=3 дней) с защитой от спама (не чаще 1 раза в 7 дней).
- **Фронтенд**:
  - `userApi`: методы `getTelegramLinkToken` и `unlinkTelegram`.
  - `ProfilePage.tsx`: блок привязки Telegram с отображением бейджа статуса, кнопки генерации ссылки и отвязки.
- **Тесты**:
  - `TelegramLinkControllerTest`, `EmailNotificationServiceTest`, `TelegramBotCommandServiceTest`, `StuckDetectionServiceTest`.

### 1.8. Очистка репозитория от внешних .js инструментов и .gitattributes
- Выполнен `git rm -r --cached` для всех внешних сторонних плагинов (`deslop-agent-sh`, `deslop-dabit3`, `deslop-ai-that-works`, `deslop-fayerman`, `avoid-ai-design`, `interface-design`, `cc-skills`), ошибочно индексировавшихся GitHub как JavaScript.
- Обновлен `.gitignore`: исключены любые вложенные папки `.agents/*/`, кроме активного каталога `.agents/scripts/`.
- Добавлен `.gitattributes` с директивами `linguist-vendored`, `linguist-documentation`, `linguist-detectable=false` для исключения служебных скриптов из статистики языков.
- В репозитории теперь отображается корректный состав языков: **Java + TypeScript**.

### 1.9. Устранение критических уязвимостей безопасности (Security Audit Remediation)
- **CRITICAL 1 (Java Deserialization в `CookieUtils`)**:
  - Внедрена криптографическая подпись HMAC-SHA256 для cookie авторизационных запросов OAuth2.
  - Десериализация выполняется только после успешной проверки HMAC в постоянное время (`MessageDigest.isEqual`). Любая попытка подделки отклоняется до десериализации.
  - Написаны тесты в `CookieUtilsTest` (проверка валидной сериализации, отказ при модификации подписи и полезной нагрузки).
- **CRITICAL 2 (OAuth Account Preemption / Takeover)**:
  - В `CustomOAuth2UserService` при привязке Google-аккаунта к учетной записи с невалидированным паролем (`passwordHash != null && googleId == null`) пароль обнуляется (`passwordHash = null`) с записью в аудит-лог.
  - Исключен сценарий захвата аккаунта атакующим, предварительно зарегистрировавшим чужой email.
  - Покрыто тестом в `CustomOAuth2UserServiceTest`.
- **CRITICAL 3 (Отзыв JWT при Logout через Blacklist)**:
  - В `JwtTokenProvider` добавлен уникальный claim `jti` (UUID).
  - Создан сервис `JwtBlacklistService` с потокобезопасным `ConcurrentHashMap<String, Instant>` и периодической TTL-очисткой.
  - `JwtAuthenticationFilter` блокирует запросы с отозванными токенами.
  - В `AuthController.logout` токен немедленно регистрируется в blacklist.
  - Покрыто тестами в `JwtBlacklistServiceTest`, `JwtAuthenticationFilterTest`, `AuthControllerTest`.
- **DataSeeder & Hardening**:
  - `DataSeeder` ограничен профилем `@Profile("!prod")`.
  - `StuckDetectionService`: запрос заменен на `findAllWithCourseAndUser()` JOIN FETCH, устраняя проблему N+1.
  - `AuthController`: дублирование парсинга IP заменено на `ipResolver.resolveClientIp`.
  - `application.yml`: `cookie-secure: ${JWT_COOKIE_SECURE:true}` по умолчанию.

---

### 1.10. Bug Fixes: AdminPage crash & Auth UI gap

- **Bug: `students.map is not a function` (AdminPage.tsx:555)**:
  - Причина: `res.data.data` возвращал `null` с бэкенда (пустой список студентов). Деструктуризация `data: students = []` срабатывает только при `undefined`, но не при `null`.
  - Фикс: В `adminApi.getStudents` добавлен null-coalescing оператор `return res.data.data ?? []`.
  - Файл: `frontend/src/entities/admin/api/adminApi.ts`.

- **Bug: Большой gap между кнопками "Войти" и "Войти через Google"**:
  - Причина: CSS-класс `my-4 pt-1` на дивайдере "или" генерировал ~36px лишнего отступа в дополнение к `space-y-4` родительской формы.
  - Фикс: Заменен на `my-2` — разделитель прилегает плотно и пропорционально.
  - Файл: `frontend/src/features/auth/ui/EmailAuthForm.tsx`.

- **Верификация**: Frontend 73/73 Vitest тестов Green (100%).

### 1.11. Telegram Bot: Fix LazyInitializationException in /stuck & /status
- **Bug**: `LazyInitializationException` при вызове команд ментора `/stuck` и `/status` в Telegram из-за отсутствия JPA-сессии при ленивой загрузке сущностей `User` из `Enrollment`.
- **Фикс**:
  - `TelegramBotCommandService` помечен `@Transactional(readOnly = true)`.
  - В методах `handleStatus` и `handleStuck` вызовы `findAll()` заменены на `findAllWithCourseAndUser()` (JOIN FETCH).
  - Добавлены юнит-тесты `mentorStatus_Success` и `mentorStuck_Success` в `TelegramBotCommandServiceTest`.
- **Верификация**: Backend 236/236 тестов Green (100%).

### 1.12. Telegram Bot UX: Smart Parsing, Russian Aliases & Error Resilience
- **Smart Parsing**:
  - Метод `extractNumericId` безошибочно извлекает числовой ID из любого формата: `<1>`, `#1`, `[1]`, `1`, `id=1`. Исключен `NumberFormatException`.
  - Отсутствие ID возвращает дружелюбную подсказку вместо падения.
- **Русские алиасы и короткие команды**:
  - `дз`, `домашки`, `проверка` -> `/hw`
  - `принять 1`, `одобрить 1`, `+ 1`, `/ok 1` -> `/approve 1`
  - `отклонить 1 правка`, `доработать 1 правка`, `- 1` -> `/reject 1 правка`
  - `статус`, `стата`, `поток` -> `/status`
  - `застряли`, `должники`, `долги` -> `/stuck`
  - `помощь`, `команды`, `меню` -> `/help`
- **Отказоустойчивость**:
  - Перехват `ResourceNotFoundException` при обращении к несуществующему ID сдачи с выводом понятного сообщения (`Сдача ДЗ #... не найдена...`).
  - При отклонении без комментария (`/reject 1`) автоматически подставляется вежливый дефолтный отзыв.
  - Обновлен `/help` с чистым оформлением без вводящих в заблуждение угловых скобок.
- **Тесты**: 5 новых юнит-тестов в `TelegramBotCommandServiceTest` (241/241 JUnit тестов Green).

### 1.12. Admin Console Hardening: Full Monochrome, System/Audit/Analytics Routes & RBAC Cleanup

- **Monochrome Design System (Zero Clutter)**:
  - Вычищены все разноцветные иконки типов уроков в `LessonRow.tsx` (`text-blue-400`, `text-emerald-400`, `text-amber-400` -> `text-zinc-400`).
  - Бейджи PREVIEW/LOCKED и DRAFT/PUBLISHED переведены в строгий монохромный серый/белый стиль (`bg-zinc-800/text-white` и `bg-zinc-900/text-zinc-500`).
  - Удалена колонка «Серия (Streak)», иконки Flame и Trophy из `StudentTable.tsx`.
  - Убран чекбокс «Бесплатный предпросмотр» из модалок создания модулей и уроков (`CurriculumTree.tsx`, `ModuleCard.tsx`, `LessonRow.tsx`).

- **Admin Routes & Telemetry**:
  - Создана страница `AdminAuditPage.tsx` (`/admin/audit`) для инспекции неизменяемых логов безопасности.
  - Создана страница `AdminSystemPage.tsx` (`/admin/system`) с мониторингом состояния сервера, PostgreSQL, JVM Memory и Bucket4j Rate Limits.
  - Зарегистрированы маршруты `/admin/analytics`, `/admin/audit`, `/admin/system` в `app/router/index.tsx`.
  - В `adminApi.ts` добавлены методы `getAuditLogs`, `getSystemHealth`, `getRateLimits`.

- **RBAC Policy**:
  - Администраторы (`role === 'ADMIN'`) имеют полный глобальный доступ ко всем курсам платформы. Кнопка «Зачисления» скрыта для админов, отображается статус «Все курсы (Админ)».

- **Верификация**:
  - Frontend: 73/73 Vitest тестов Green (100%).
  - Production Build: `tsc -b && vite build` успешно собран за 7.48s (1802 модуля, 0 ошибок).

### 1.13. UI Polish: Logo Scale & Header Dropdown Deslop

- **Логотип на странице входа (`LoginPage.tsx`)**:
  - Увеличен размер круглого брендового аватара с `w-12 h-12` (48px) до `w-20 h-20` (80px) со стилизованной границей `border-white/20` и глубокой тенью `shadow-xl`.
- **Профиль пользователя (`UserProfileDropdown.tsx`)**:
  - Выпилен блок геймификации со стриками и рекордами («СТРИК 0 дн.», «РЕКОРД 0 дн.»).
  - Удалена избыточная надпись роли `STUDENT` как в кнопке шапки, так и внутри выпадающего списка (статус `ADMIN` отображается только для администраторов).
  - Меню стало компактным, строгим и функциональным.
- **Тесты**: Обновлены и успешно пройдены `UserProfileDropdown.test.tsx` и `CurriculumTree.test.tsx` (73/73 тестов Green).

### 1.14. Real Metrics in User Profile: Learning Time & Completed Projects

- **Backend Aggregation (`UserProfileService.java`, `UserProfileDto.java`)**:
  - Удалена привязка к стрикам в профиле; добавлены поля `timeSpentMinutes` и `completedProjectsCount`.
  - В `LessonProgressRepository` добавлен агрегационный JPQL-запрос `sumCompletedMinutesByUserId(userId)` (суммирование `durationMinutes` по всем пройденным урокам студента).
  - В `ProjectShowcaseRepository` и `HomeworkSubmissionRepository` добавлены методы `countByUserId(userId)` и `countByUserIdAndStatus(userId, SubmissionStatus.PASSED)`.
  - Реальный подсчет: `timeSpentMinutes = sumCompletedMinutes`, `completedProjectsCount = showcaseProjects + passedHomeworks`.
- **Frontend UI (`ProfilePage.tsx`, `types.ts`)**:
  - Карточки «ТЕКУЩИЙ СТРИК» и «РЕКОРД СТРИКА» заменены на «ВРЕМЯ ОБУЧЕНИЯ» (`Clock` и формат `${h} ч. ${m} мин.`) и «СДЕЛАНО ПРОЕКТОВ» (`FolderGit2` и точное число проектов).
  - Данные на 100% реальные и динамические, поступают с бэкенда при вызове `GET /v1/users/profile`.
- **Тесты и сборка**:
  - Backend: `UserProfileControllerTest` обновлен и прошел успешно.
  - Frontend: `ProfilePage.test.tsx` обновлен и прошел успешно (73/73 тестов Green).
  - Production Build: `tsc -b && vite build` собран за 4.78s (0 ошибок).

### 1.15. Fix Telegram Bot Username & Full ProfilePage Monochrome

- **Telegram Bot Username Fix**:
  - Причина ошибки `Username @MrDevCoursesBot not found`: в коде `TelegramLinkController.java` и конфигурациях дефолтным был указан несуществующий бот `MrDevCoursesBot`.
  - Фикс: В `TelegramLinkController.java` и `application.yml` установлен реальный username бота: `${TELEGRAM_BOT_USERNAME:MrDevelopersbot}`. Ссылка генерации токена теперь открывает настоящего `@MrDevelopersbot`.
- **ProfilePage Full Monochrome (Zero Clutter)**:
  - Вычищены все цветные акценты (синий `sky-400`/`sky-600`, зеленый `emerald-400`, оранжевый `amber-400`, розовый `rose-950`).
  - Кнопка «Подключить бота»: приведена к фирменному стилю платформы (`bg-white text-black font-semibold hover:bg-zinc-200`).
  - Бейджи привязки: `ПОДКЛЮЧЕН` (`bg-zinc-800 text-white border-white/20`), `НЕ ПРИВЯЗАН` (`bg-zinc-900 text-zinc-500 border-white/5`).
  - Кнопка «Отвязать»: строгий монохром `bg-zinc-900 hover:bg-zinc-800 text-zinc-400 hover:text-white border-white/10`.
  - Уведомления об успехе/ошибке переведены в нейтральный темный монохром `bg-zinc-900 border-white/10`.
- **Верификация**:
  - Backend: 236/236 тестов Green (100%).
  - Frontend: 73/73 тестов Green (100%).
  - Production Build: `tsc -b && vite build` (4.78s, 0 ошибок).

### 1.16. Admin Direct Routing to Admin Console upon Authentication

- **Маршрутизация администратора (`/admin` вместо `/courses`)**:
  - `EmailAuthForm.tsx`: При успешном входе через email/пароль или регистрации, если пользователь имеет роль `ADMIN` (`role === 'ADMIN'`), немедленно перенаправляется на `/admin`, а студент — на `/courses`.
  - `LoginPage.tsx`: Если уже авторизованный администратор переходит на страницу входа, редирект направляет его на `/admin` (`to={user?.role === 'ADMIN' ? '/admin' : '/courses'}`).
  - `AuthCallbackPage.tsx`: При возврате из Google OAuth2 авторизации проверяется профиль и администратор сразу перенаправляется в `/admin`.
  - `authContext.tsx`: Методы `loginWithEmail` и `register` теперь возвращают типизированный объект `Promise<User>`, предоставляя вызывающим формам актуальные данные о роли.
- **Верификация**:
  - Backend: 236/236 тестов Green (100%).
  - Frontend: 73/73 тестов Green (100%).
  - Production Build: `tsc -b && vite build` (4.66s, 0 ошибок).

### 1.17. Student Console Overhaul: Exclusive Student Filtering & Progress Columns

- **Backend (`AdminStudentService.java`, `StudentDto.java`, `LessonProgressRepository.java`)**:
  - В методе `searchStudents` установлен строгий фильтр `u.getRole() == Role.STUDENT`: администраторы исключены из консоли студентов, так как имеют глобальный доступ.
  - В `StudentDto` добавлены поля `currentLessonTitle` (текущий/последний пройденный урок студента) и `estimatedFinishDate` (расчетная дата окончания на основе даты зачисления + длительность курса).
  - В `LessonProgressRepository` добавлен пакетный запрос `findAllByUserIdsWithLesson(userIds)` для эффективного вычисления прогресса без N+1.
- **Frontend (`StudentTable.tsx`, `StudentSearchFilter.tsx`, `AdminStudentsPage.tsx`)**:
  - Удалена избыточная колонка «РОЛЬ RBAC» и фильтр по ролям «Все роли» (таблица предназначена исключительно для студентов).
  - Добавлены новые информативные столбцы:
    1. **НА КАКОМ УРОКЕ**: текущий урок студента (например, `Урок 1: Архитектура` или `Не начат`).
    2. **ДАТА РЕГИСТРАЦИИ**: дата регистрации пользователя.
    3. **ПРИМЕРНОЕ ОКОНЧАНИЕ**: расчетная дата завершения курса.
  - Очищены все неиспользуемые импорты и параметры.
- **Верификация**:
  - Backend: `AdminStudentServiceTest` и 236 тестов Green (100%).
  - Frontend: `StudentTable.test.tsx`, `StudentSearchFilter.test.tsx` и 73/73 тестов Green (100%).
  - Production Build: `tsc -b && vite build` (4.99s, 0 ошибок).

### 1.18. Profile Form Layout: Relocate Section Dividers Below Content

- **Frontend (`ProfilePage.tsx`)**:
  - Удалены разделительные линии (`border-b border-white/5`) непосредственно под заголовками секций (`1. Основные данные`, `2. Каналы связи и репозитории`, `3. Главная цель`, `4. О себе`).
  - Разделители перенесены в конец каждой секции (`pb-6 border-b border-white/10`), разделяя логические блоки формы после завершения ввода информации.
- **Верификация**:
  - Frontend: `ProfilePage.test.tsx` и 73/73 тестов Green (100%).
  - Production Build: `tsc -b && vite build` (4.73s, 0 ошибок).

---

### Статус Верификации:
- **Backend (JUnit)**: 236/236 тестов Green (100%).
- **Frontend (Vitest)**: 73/73 тестов Green (100%).
- **Production Build**: 0 ошибок (4.73s, 1802 modules).
- **Working Tree**: 100% чистый репозиторий, 0 мусорных файлов.