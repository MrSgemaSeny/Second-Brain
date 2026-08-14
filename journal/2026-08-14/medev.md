# Фаза 2: Тестирование контроллеров (Backend) завершена

## Достижения
- Написаны интеграционные тесты для `AuthController`, `ProfileController`, `PortfolioController`.
- Решена проблема с конфликтами безопасности Spring Security при инициализации контекста в `AbstractIntegrationTest`.
- Решена проблема с конфликтом портов при использовании `ServerPortCustomizer` путем отключения для профиля `test`.
- Исправлена валидация `startDate` в `ProfileControllerTest`.
- Итоговое выполнение `./gradlew test jacocoTestReport` завершилось успехом без ошибок.

## Следующий этап
- Переход к Фазе 3 (Frontend Testing).
