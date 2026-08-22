# Session Log: MeDev — 2026-08-23

- **Проект:** [[medev]] (MeDev / DevProfile)
- **Цель сессии:** Исправление проблем с запуском проекта в Antigravity / IDEA / Docker / Render, фиксация LLM модели `openai/gpt-oss-20b`.

---

## 1. Что было исправлено и добавлено

### Antigravity & Hooks
- Отключены блокирующие хуки в `.agents/hooks.json`, вызывавшие зависания PowerShell-процессов и падение `Executor is not currently running`.
- Очищен и дедуплицирован `~/.gemini/config/config.json`.

### Backend (Spring Boot)
- **ProfileService.java:** Исправлена ошибка компиляции (несоответствие типов `LocalDate` при маппинге DTO `AiExperienceDto` и `AiEducationDto`, добавлен недостающий импорт `java.time.LocalDate`).
- **Сборка:** Локально проверена сборка `.\gradlew.bat build -x test` и прогон всех 253 тестов (`.\gradlew.bat test`) — 100% green.

### AI Architecture & Model Standard
- Зафиксирована основная модель AI: **`openai/gpt-oss-20b`** (через Groq API прокси).
- Обновлены конфигурации `application.yml`, `README.md`, `.agents/AGENTS.md`, `.agents/CONTEXT.md`, а также базы Second Brain (`context/projects.md`, `context/prompts_for_ai.md`).

---

## 2. Результаты тестов и верификации
- **Backend:** 253 passed (JUnit 5 + MockMvc + Testcontainers)
- **Frontend:** 37 passed, production build `npm run build` успешен.
- **Docker/Render:** Команда сборки `gradlew build -x test` отрабатывает без ошибок.
