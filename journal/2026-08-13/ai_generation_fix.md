# Фикс багов AI-Генерации и защиты базы данных

## Проблема
Пользователь сообщил, что кнопка "Умная AI-Синхронизация" не генерирует новые данные (вместо этого в профиле оставались заглушки "Middle Full Stack Engineer", или же появлялась ошибка).
В логах выяснилось, что модель Llama 3.3 от Groq возвращает JSON, обернутый в markdown-блоки ` ```json `, что приводило к исключению в строгом валидаторе Jackson внутри `GroqClient.java`.

Еще одна критическая уязвимость была найдена в `AiAnalysisService`: при исключении (graceful degradation) сервис возвращал пустой объект `AiParsedResumeDto`, который передавался в `ProfileService.importParsedResume`. Этот метод очищал все списки в базе данных (skills, experience, education), тем самым удаляя данные пользователя.

## Решение
1. **GroqClient.java**: Добавлен метод `cleanAndValidateJson`, который надежно очищает markdown-теги перед парсингом. Это устраняет ошибку 500.
2. **AiAnalysisService.java**: Удалена логика "Graceful degradation" с возвратом пустого объекта. Теперь при падении парсера выбрасывается `RuntimeException("AI generation failed or returned invalid format. Aborting to prevent data loss.")`. Это гарантирует откат транзакции БД и показ внятной ошибки пользователю вместо потери данных.

Изменения зафиксированы в репозитории MeDev. Бэкенд требует перезагрузки.
