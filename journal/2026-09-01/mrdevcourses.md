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

---

### Статус Верификации:
- **Backend (JUnit)**: 220/220 тестов Green (100%).
- **Frontend (Vitest)**: 73/73 тестов Green (100%).
- **Production Build**: 0 ошибок (4.35s).