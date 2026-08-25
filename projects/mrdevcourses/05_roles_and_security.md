# 5. Ролевая модель и безопасность MrDevCourses

### Роли
- `STUDENT`: Просмотр курсов, запись на курс, доступ к открытым урокам согласно drip-графику, отметка прогресса.
- `ADMIN`: Полный доступ ко всем модулям, создание/редактирование курсов и уроков, просмотр списка студентов.

### Защитные механизмы
1. **IDOR Prevention**: Идентификация текущего пользователя строго через `SecurityUtils.getCurrentUserId()` из JWT клеймов.
2. **Server-side Drip Enforcement**: Фронтенд только отображает статус (открыт/замок), сервер при обращении к `/lessons/{lessonId}` строго проверяет дату `(NOW() - enrolled_at)` и возвращает `403 Forbidden` с таймштампом открытия при попытке обойти ограничение.
3. **Cookie Security**: `httpOnly` защита от XSS, `Secure` в production, `SameSite` защита от CSRF.
4. **UTC Timezone**: Все даты хранятся и рассчитываются в UTC (`spring.jpa.properties.hibernate.jdbc.time_zone=UTC`, `TIMESTAMP WITH TIME ZONE`).
