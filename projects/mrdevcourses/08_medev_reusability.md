# 8. Связи с MeDev (Что переиспользовать)

MeDev служит эталоном архитектуры для MrDevCourses:

| Компонент MeDev | Адаптация для MrDevCourses |
|-----------------|---------------------------|
| `build.gradle` | Очищен от Redis, Stripe, AI/Groq, PDFBox |
| `OAuth2UserService` & JWT | Прямой перенос логики выпуска JWT в httpOnly cookie |
| `SecurityUtils` | Полный перенос для получения `currentUserId` |
| `GlobalExceptionHandler` | Прямой перенос структуры ошибок |
| FSD архитектура фронтенда | Идентичная структура слоев (app, pages, widgets, features, entities, shared) |
| Dark Aesthetic | Идентичные токены GitHub Dark темы |
