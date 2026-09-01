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

### 1.3. Редизайн страницы курса (CourseDetailPage: 1-колоночный Hero-лейаут)
- Убран отдельный правый плавающий сайдбар (`CourseStickyCard`).
- Кнопки основного действия («Посмотреть полное видео» и «Записаться на курс» / «Продолжить обучение») перенесены прямо в **Hero-блок под плашку автора** в основной колонке.
- Видео-превью и карточка с параметрами курса (модули, уроки, видеочасы, формат + кнопка «Поделиться») гармонично интегрированы в основной поток страницы.
- Проверены и успешно пройдены тесты `CourseDetailPage.test.tsx`.

### 1.4. Изоляция страниц авторизации (AuthLayout без Header и Footer)
- Создан выделенный легковесный компонент `AuthLayout` (`frontend/src/app/layout/AuthLayout.tsx`), свободный от шапки и подвала платформы.
- В `router/index.tsx` страницы `/auth`, `/login` и `/auth/callback` переведены на использование `AuthLayout`.
- Страницы входа и регистрации теперь представляют собой чистый, сфокусированный экран авторизации в стиле GitHub.
- Пройдены тесты `LoginPage.test.tsx` и `App.test.tsx`.

### 1.5. Оптимизация вертикального ритма каталога (CoursesPage)
- Удален принудительный класс `min-h-screen` из контейнера `CoursesPage.tsx`, создававший искусственный пустой зазор высотой в пол-экрана перед футером при малом количестве курсов.
- За счет гибкого `main.flex-1` в корневом `App.tsx` футер аккуратно прижимается к низу страницы без образования пустот и лишнего скролла.
- Проверены и пройдены тесты `CoursesPage.test.tsx`.

### 1.6. Корректировка визуальной иерархии CTA-кнопок курса (CourseDetailPage)
- Слева расположена приоритетная белая кнопка действия **«Записаться на курс»** со значком `<ArrowRight />`.
- Справа размещена вторичная серая/контурная кнопка **«Посмотреть видео»** со значком `<Play />`.
- Успешно пройдены юнит-тесты `CourseDetailPage.test.tsx`.

---

### Статус Верификации:
- **Backend (JUnit)**: 216/216 тестов Green (100%).
- **Frontend (Vitest)**: 71/71 тестов Green (100%).
- **Production Build**: `tsc -b && vite build` — 1795 модулей собрано за 4.35s (0 ошибок).