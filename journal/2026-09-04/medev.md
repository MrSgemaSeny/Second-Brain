# Сессия: 2026-09-04 (MeDev Production Triage & Resume Import Fix)

## Выполненные задачи:

1. **Фиксация рабочей модели Groq (`openai/gpt-oss-20b`)**:
   - На основе реального дашборда Groq подтверждено: рабочая модель — **`openai/gpt-oss-20b`** (GPT-20B). Модели Llama не работают в данном окружении и строго запрещены к использованию.
   - Значения возвращены и жестко закреплены в `application.yml`, `application-prod.yml`, `GroqClient.java`, `GroqHealthIndicator.java`, `AGENTS.md` (Правило 11), `CONTEXT.md` и `knowledge/arch-groq-models-policy.md`.
   - Исправлена валидация в `ImportResumePage.tsx` (только PDF до 10MB) и обработка PDF MIME-типов в `AiController.java` / `AiAnalysisService.java`.
   - В `ProfileService.importParsedResume` добавлен `@CacheEvict` и прямое наполнение коллекций в памяти.

2. **Тестирование**:
   - Backend: 253/253 тестов прошли (`BUILD SUCCESSFUL`).
   - Frontend: 37/37 тестов прошли (`vitest run`).
   - Сборка TypeScript / Vite: успешно (0 ошибок, 0 ворнингов).
