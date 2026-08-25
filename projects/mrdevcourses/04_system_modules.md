# 4. Модули системы MrDevCourses

### 4.1 Auth Module
- Google OAuth2 вход, автосоздание пользователя.
- Эндпоинты: `GET /api/v1/auth/me`, `POST /api/v1/auth/logout`.

### 4.2 Course Module
- Публичный каталог и деталка курса.
- Запись на курс (создание `enrollment` с меткой времени `enrolled_at = NOW()`).
- Эндпоинты: `GET /api/v1/courses`, `GET /api/v1/courses/{slug}`, `POST /api/v1/courses/{courseId}/enroll`.

### 4.3 Lesson Module
- Просмотр уроков с валидацией drip-тайминга.
- Отметка урока как завершенного (`lesson_progress`).
- Эндпоинты: `GET /api/v1/courses/{courseId}/lessons`, `GET /api/v1/courses/{courseId}/lessons/{lessonId}`, `POST /api/v1/courses/{courseId}/lessons/{lessonId}/complete`.

### 4.4 Progress Module
- Дашборд студента: текущий день с момента записи, количество пройденных и открытых уроков, расчет времени открытия следующего дня (`nextUnlockAt`).
- Эндпоинты: `GET /api/v1/progress`, `GET /api/v1/progress/{courseId}`.

### 4.5 Admin Module
- Роль `ADMIN`.
- CRUD курсов и уроков, просмотр списка студентов и их прогресса, ручное зачисление.
- Эндпоинты: `/api/v1/admin/**`.
