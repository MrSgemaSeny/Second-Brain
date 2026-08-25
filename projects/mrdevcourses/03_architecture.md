# 3. Архитектура системы MrDevCourses

```
[Браузер Студента]
    │
    │  HTTPS (React 19 + FSD)
    ▼
[Spring Boot 3 Монолит] ──► [Google OAuth2]
    │
    ▼
[PostgreSQL (UTC)]
    (users, courses, lessons, enrollments, lesson_progress)
```

### Архитектурные принципы
1. **Модульный монолит**: Модули `auth`, `course`, `lesson`, `progress`, `admin` изолированы на уровне пакетов сервисов и DTO.
2. **Security & RLS**: `userId` берется исключительно из токена авторизации через `SecurityUtils.getCurrentUserId()`. Защита от IDOR.
3. **Stateless Auth Flow**:
   - Google Login -> OAuth2 Callback -> сохранение/апдейт `users` -> генерация JWT -> отправка в `Set-Cookie` (`httpOnly`, `Secure` на проде, `SameSite=Lax/None`).
4. **Drip Flow**:
   - Расчет доступности прямо в запросе через `enrollments.enrolled_at` и `day_number`.
