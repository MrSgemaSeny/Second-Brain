# 2026-08-10 - JF-1C

## Добавлено
- Backend: Эндпоинты ручного каскадного удаления `DELETE /api/v1/admin/courses/{id}`, `DELETE /api/v1/admin/courses/chapters/{id}`, `DELETE /api/v1/admin/courses/lessons/{id}` (CourseController, ChapterController, LessonController). 
- Frontend: Функции удаления добавлены в `courseApi.ts` (`deleteCourse`, `deleteChapter`, `deleteLesson`). 
- Frontend: В `AdminCoursesPage.tsx` добавлена кнопка и логика удаления курсов.
- Frontend: В `CourseCurriculumTab.tsx` добавлены кнопки (иконка Trash2) удаления модулей и уроков.
- Security (Backend): Добавлена серверная проверка в `CrmAccessService` (`canAssignTask`, `canUnassignTask`), запрещающая взятие/сброс задач в стадиях `WON` и `LOST`.

## Удалено
- Frontend: Убрана опция `isPreview` (Ознакомительный урок / бесплатно) из `AdminLessonEditPage.tsx` и бейдж в `CourseCurriculumTab.tsx`, так как система не предполагает покупку отдельных курсов, а учеников регистрируют вручную.
- Backend: Убраны ручные удаления связанных сущностей (`LessonProgress`, `Enrollment`, `Certificate`) из `CourseService` и `LessonService`, так как в миграциях V25 и V108 настроен `ON DELETE CASCADE` на уровне базы данных, а JPA-аннотации настроены на `CascadeType.ALL, orphanRemoval = true`.

## Исправлено (Безопасность)
- CORS: В `CorsConfig.java` убрана wildcard-маска `https://*.github.io` из `allowedOriginPatterns`. Оставлен только явный origin `https://mrsgemaseny.github.io` в `allowedOrigins`.
- Frontend: Убрано использование `localStorage.getItem('token')` в функции `downloadCertificatePdf` (`courseApi.ts`). Добавлен флаг `credentials: 'include'` для правильной передачи HttpOnly cookie.
- IDOR (Backend): Из `FileDownloadController.java` убран уязвимый `catch`-fallback в методе `downloadAvatar`. Теперь доступ по `/uploads/avatars/{storageKey}` строго ограничен папкой `avatars/`, предотвращая несанкционированное скачивание чужих документов из корневой папки.
- i18n (Backend): В `GlobalExceptionHandler` доработана логика локализации кастомных исключений — теперь текст исключения используется как ключ только в том случае, если он начинается с префикса `error.` (например, `error.user.exists`), в остальных случаях сырой текст возвращается без изменений.

## Исправлено (Баги)
- WebSocket (Frontend + Backend): Исправлена проблема отсутствия рил-тайм чата на iOS Safari. Из-за блокировок ITP браузер не отправлял кросс-доменную `HttpOnly` куку при STOMP-соединении. Исправлено пробросом токена из памяти в `connectHeaders` (фронт) и чтением `Authorization: Bearer` заголовка в `WebSocketConfig.java` (бэк) как fallback для аутентификации.

## Тесты
- Frontend билд (`npm run build`) успешно завершен.
- Backend тесты (`./gradlew test`) пройдены успешно (BUILD SUCCESSFUL).
