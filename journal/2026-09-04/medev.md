# Сессия: 2026-09-04 (MeDev Production Triage & Resume Import Fix)

## Выполненные задачи:

1. **Диагностика и исправление ошибок `/api/v1/ai/parse-resume` (HTTP 500 и HTTP 400)**:
   - **Root Cause 500**: Дефолтная модель `groq.model` указывала на несуществующую/устаревшую `openai/gpt-oss-20b`. Модель обновлена на актуальную флагманскую Groq-модель `llama-3.3-70b-versatile` в `application.yml`, `GroqClient.java` и `GroqHealthIndicator.java`.
   - **Root Cause 400**: На фронтенде `ImportResumePage.tsx` в поле `accept` были разрешены `.doc,.docx` и в тексте обещана поддержка Word-файлов, тогда как бэкенд парсит только `%PDF` через PDFBox. Пользователь загружал `.docx` и получал 400. Поле исправлено на `application/pdf,.pdf`, описание обновлено, добавлена точная валидация и тосты `toast.error` / `toast.success` через Sonner.
   - **Улучшение надежности PDF Extraction**: В `AiAnalysisService.java` и `AiController.java` добавлена поддержка альтернативных PDF MIME-типов (`application/x-pdf`), проверка расширения `.pdf`, а также детекция пустых/сканированных PDF без текстового слоя с понятным текстом ошибки.
   - **Улучшение сохранения профиля**: В `ProfileService.importParsedResume` добавлены аннотация `@CacheEvict(value = "profiles", key = "#userId")` и корректное наполнение коллекций в памяти `profile.getSkills().add(...)` перед сериализацией в DTO.

2. **Тестирование**:
   - Backend: 253/253 тестов прошли (`BUILD SUCCESSFUL in 1m 4s`).
   - Frontend: 37/37 тестов прошли (`vitest run`).
   - Сборка TypeScript / Vite: успешно (0 ошибок, 0 ворнингов).
