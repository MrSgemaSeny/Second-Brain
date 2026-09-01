# Code Review: MrDevCourses — Основные блоки и безопасность

**Дата**: 2026-08-31
**Ревьюер**: Antigravity (Security + Backend Architecture + Frontend Architecture)
**Объем проверки**: 23 модуля бэкенда, 7 слоев фронтенда, полная цепочка аутентификации

---

## Вердикт: Request Changes

Проект архитектурно зрелый для Level 3 MVP. Модульная структура, IDOR-защита, JWT-в-cookie, rate limiting, Security Headers — все ключевые столпы на месте. Но есть 3 Critical и 6 Required проблем, которые нужно закрыть.

---

## Critical (Блокирует мердж)

### C1. `POST /v1/projects/{id}/like` — без аутентификации и без rate limit

> [!CAUTION]
> Эндпоинт лайков открыт для анонимов (`permitAll` в [SecurityConfig.java:L65](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/config/SecurityConfig.java#L65)) и обрабатывается в [ProjectShowcaseController.java:L38-L42](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/modules/project/controller/ProjectShowcaseController.java#L38-L42) без проверки userId.

**Угроза**: Любой бот может бесконечно накручивать лайки через `curl` в цикле. Rate limit тоже не спасает — path `/v1/projects/*/like` — это `POST`, но попадает в `GENERAL` tier (60 req/min/IP), что все еще слишком щедро для анонима.

**Исправление**: 
1. Убрать `.requestMatchers(HttpMethod.POST, "/v1/projects/*/like").permitAll()` из SecurityConfig.
2. Сделать `.authenticated()` и привязать лайк к `userId` (deduplicate — один лайк на user+project).
3. Или, если лайки должны быть анонимными, привязать к IP + fingerprint с жестким rate limit.

---

### C2. Drip Content вычисляется в Java, а не в SQL

> [!CAUTION]
> Согласно архитектурному контракту, Drip Content **СТРОГО** должен использовать SQL: `(NOW() - enrolled_at) >= ((day_number - 1) * INTERVAL '1 day')`.

Текущая реализация в [CourseService.java](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/modules/course/service/CourseService.java) и [LessonService.java](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/modules/lesson/service/LessonService.java) выполняет `calculateUnlockTime` на стороне JVM, что:
- Тянет все уроки в память для фильтрации
- Рассинхронизируется с серверным временем БД
- Нарушает архитектурный контракт проекта

**Исправление**: Перенести вычисление доступности в SQL-запрос (WHERE clause в repository) с использованием `NOW()` и `enrolled_at`.

---

### C3. Frontend: отсутствие `<Suspense>` для lazy-загружаемых protected-роутов

> [!CAUTION]
> Лениво-загружаемые компоненты (`CoursesPage`, `DashboardPage` и др.) внутри [ProtectedRoute.tsx:L33](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/app/router/ProtectedRoute.tsx#L33) не обернуты в `<Suspense>`.

**Результат**: React выбросит runtime-ошибку при навигации к любой защищенной странице, если чанк еще не загрузился. Приложение крэшится.

**Исправление**: Обернуть `children` в `<Suspense fallback={<Spinner />}>` внутри `ProtectedRoute`.

---

## Required (Необходимо исправить)

### R1. Hardcoded JWT secret в default value

> [!WARNING]
> [JwtTokenProvider.java:L26](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/modules/auth/service/JwtTokenProvider.java#L26) и [application.yml:L28](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/resources/application.yml#L28) содержат hardcoded fallback JWT secret: `404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970`.

Это типичный «Tutorial secret» из StackOverflow. Если env var `JWT_SECRET` не задан (забыли при деплое), бэкенд запустится с этим предсказуемым ключом. Злоумышленник сможет генерировать валидные JWT с любым userId/role.

**Исправление**: Убрать default value. Если `JWT_SECRET` не задан — приложение НЕ ДОЛЖНО запускаться. Используйте `@Value("${app.jwt.secret}")` без дефолта.

---

### R2. Unbounded Queries в Admin-модуле

> [!WARNING]
> [AdminService.java](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/modules/admin/service/AdminService.java) — `getAllStudents()` вызывает `userRepository.findAll()`. При росте базы это OOM.

Аналогично `EnrollmentRepository.findAllWithCourseAndUser()` загружает ВСЕ записи.

**Исправление**: Внедрить `Pageable` во все list-эндпоинты админки.

---

### R3. AdminService — God Object (нарушение SRP)

`AdminService` напрямую работает с репозиториями `Course`, `Lesson`, `Enrollment`, дублируя бизнес-логику из `CourseService` и `LessonService`. Должен делегировать предметным сервисам.

---

### R4. Frontend: повсеместное отсутствие обработки ошибок API

`useQuery` / `useMutation` хуки не обрабатывают `isError` / `onError`:
- [CoursesPage.tsx:L21-24](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/pages/courses/CoursesPage.tsx#L21-L24) — список курсов молча пустой при ошибке
- [CourseDetailPage.tsx:L62-70](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/pages/course/CourseDetailPage.tsx#L62-L70) — `enrollMutation` без `onError`, UI зависает
- [DashboardPage.tsx:L19-22](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/pages/dashboard/DashboardPage.tsx#L19-L22) — прогресс без fallback

**Исправление**: Добавить `onError` с toast-уведомлением или ErrorBoundary.

---

### R5. TypeScript: `any` типы вместо строгих

`catch (err: any)` и `course: any` в `.map()` — компилятор не ловит баги:
- [CoursesPage.tsx:L132](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/pages/courses/CoursesPage.tsx#L132)
- [AdminCurriculumPage.tsx:L35](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/pages/admin/AdminCurriculumPage.tsx#L35)
- [AddProjectModal.tsx:L30](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/features/project-showcase/ui/AddProjectModal.tsx#L30)

**Исправление**: `catch (err: unknown)` + `instanceof Error` guard.

---

### R6. FSD нарушения

- **Entities root exports**: Файлы API лежат прямо в корне `entities/` (например, [adminApi.ts](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/entities/adminApi.ts)) вместо `entities/{slice}/index.ts`.
- **Widget-to-Widget импорт**: [LessonContextPanel.tsx:L2](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/widgets/lesson/ui/LessonContextPanel.tsx#L2) импортирует `useQuickNav` из `widgets/quick-nav`. Widgets не должны импортировать друг друга.

---

## Security Posture Summary (Мой аудит)

### Что реализовано ХОРОШО:

| Аспект | Статус | Детали |
|--------|--------|--------|
| **IDOR защита** | OK | Все 11 student-facing контроллеров берут `userId` из `SecurityUtils.getCurrentUserId()`, не из параметров |
| **JWT Cookie** | OK | `httpOnly=true`, `SameSite=Lax` (dev) / `None` (prod), `Secure=true` (prod) |
| **CSRF** | OK | Disabled корректно — stateless JWT, cookie `SameSite` защищает |
| **Security Headers** | OK | [SecurityHeadersFilter](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/backend/src/main/java/com/mrdev/common/security/SecurityHeadersFilter.java) — CSP, X-Frame-Options DENY, nosniff, Referrer-Policy |
| **Rate Limiting** | OK | 3-tier Bucket4j (AUTH 10/15m, AI 5/min, GENERAL 60/min) |
| **Input Validation** | OK | `@Valid` + bean validation на RegisterRequest, LoginRequest, HomeworkSubmitRequest |
| **BCrypt** | OK | Пароли хешируются через `BCryptPasswordEncoder` |
| **User Enumeration** | OK | Login возвращает одинаковую ошибку при несуществующем email и неверном пароле |
| **Admin RBAC** | OK | `/v1/admin/**` -> `hasRole("ADMIN")` в SecurityConfig |
| **Secrets** | OK | Prod config использует `${ENV_VARS}` для DB, Google OAuth, Telegram |
| **Actuator** | OK | Только `health,info,metrics` endpoints exposed |
| **XSS (Frontend)** | OK | `dangerouslySetInnerHTML` не используется, Markdown рендерится через безопасный кастомный парсер |
| **OAuth2** | OK | Email null-check, googleId lookup, upsert pattern корректен |

### Что нужно усилить:

| Аспект | Проблема | Серьезность |
|--------|----------|-------------|
| JWT fallback secret | Hardcoded default в коде и yml | **Required** |
| Like endpoint | `permitAll` + POST без userId | **Critical** |
| IP Spoofing (Rate Limit) | `X-Forwarded-For` доверяется без проверки proxy chain | **Optional** (Fly.io ставит свой XFF) |

---

## Optional / Consider

- **Выделение Mapper-классов**: `toDto` / `toDetailDto` в сервисах — сотни строк ручного маппинга. Вынести в отдельные Assembler/Mapper классы.
- **Оптимизация prev/next lesson**: Загрузка ВСЕХ уроков курса для поиска соседей. Заменить на SQL `LAG`/`LEAD` оконные функции.
- **MarkdownViewer**: Самописный regex-парсер хрупкий. Рассмотреть `react-markdown` + `rehype-sanitize`.
- **CourseDetailPage.tsx (419 строк)**: Модалки трейлера, enrollment confirmation, certificate — вынести в отдельные компоненты.
- **IP Resolver**: 12 заголовков для определения IP избыточно. За Fly.io достаточно `Fly-Client-IP` + `X-Forwarded-For` + `RemoteAddr`.

---

## Nit

- `console.error` в [LessonRow.tsx:L130](file:///c:/Users/murat/IdeaProjects/new_world/MrDevCourses/frontend/src/widgets/admin-curriculum/LessonRow.tsx#L130) — молчаливый лог без обратной связи пользователю
- `CourseDto` содержит дублирующие поля `isActive`/`active` и `isEnrolled`/`enrolled`
- Flyway V12 seed-миграция смешивает DDL и данные (приемлемо для Level 3, но маркирую)

---

## Приоритетный план исправлений

| # | Задача | Критичность | Оценка |
|---|--------|-------------|--------|
| 1 | Like endpoint: auth + deduplicate | Critical | 1h |
| 2 | Drip Content: перенос в SQL | Critical | 2-3h |
| 3 | Frontend Suspense boundary | Critical | 15min |
| 4 | JWT secret: убрать default | Required | 10min |
| 5 | Admin pagination (Pageable) | Required | 2h |
| 6 | API error handling (onError) | Required | 1h |
| 7 | TypeScript: `any` -> `unknown` | Required | 30min |
| 8 | AdminService SRP decomposition | Required | 2h |
| 9 | FSD: entities + widget imports | Required | 1h |
