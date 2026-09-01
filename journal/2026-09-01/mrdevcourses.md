# Журнал разработки — MrDevCourses (2026-09-01)

---

### 1.1. Security Hardening: Защита стены проектов (`/projects`) и 1-User-1-Like Toggle
- Создана новая Flyway миграция `V20__create_project_likes_table.sql`:
  - Таблица `project_likes` с внешними ключами на `project_showcases(id)` и `users(id)` и ограничением `UNIQUE (project_id, user_id)`.
- Созданы JPA сущность `ProjectLike` и репозиторий `ProjectLikeRepository` с методом `findProjectIdsLikedByUser`.
- `ProjectShowcaseService.toggleLike(userId, projectId)`:
  - Реализован механизм toggle (повторный клик снимает лайк с декрементом счетчика).
  - При `getAllShowcases(currentUserId)` возвращается персональный флаг `hasLiked: boolean`.
- `ProjectShowcaseController`:
  - `POST /api/v1/projects/{id}/like` защищен `@PreAuthorize("isAuthenticated()")`.
  - В `SecurityConfig.java` снят `permitAll` для POST лайков.
- `ProjectsPage.tsx`:
  - Интерактивная кнопка лайка с индикацией состояния `hasLiked`.
  - При клике неавторизованного пользователя происходит безопасный редирект на `/login`.
- **Тесты**:
  - `ProjectShowcaseControllerTest`: проверен 401 Unauthorized для анонимных лайков и корректный toggle счетчика для авторизованных.

### 1.2. Frontend Resilience: Suspense для защищенных роутов
- В `router/index.tsx` все защищенные роуты (`/courses`, `/courses/:slug`, `/courses/:cId/lessons/:lId`, `/dashboard`) обернуты в `wrap()` с `<Suspense fallback={<PageLoader />}>`, предотвращая падение React при медленном сетевом соединении.

---

### Статус Верификации:
- **Backend (JUnit)**: 216/216 тестов Green (100%).
- **Frontend (Vitest)**: 71/71 тестов Green (100%).
- **Production Build**: 0 ошибок (4.7s).