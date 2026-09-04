# Архитектурное Решение: Политика LLM-моделей Groq (GPT-20B vs Llama)

**Контекст проекта:** MeDev (DevProfile)  
**Статус:** Окончательное решение (Закреплено)  
**Дата:** 2026-09-04  

---

## 1. Проблема и Факты

При интеграции с Groq API в проекте MeDev возник сбой:
1. Модели семейства **Llama** на используемом аккаунте / пайплайне Groq **НЕ РАБОТАЮТ** или выдают отказы / ошибки авторизации и валидации.
2. Единственная стабильно работающая модель на Groq API в проекте — **`openai/gpt-oss-20b`** (GPT OSS 20B).

## 2. Архитектурное Правило (Hard Guardrail)

1. **Единственный разрешенный идентификатор модели:** `openai/gpt-oss-20b`.
2. **Запрет на подмену:** Строго запрещено переключать модель на любые вариации Llama (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant` и т.д.).
3. **Места фиксации:**
   - `backend/src/main/resources/application.yml` (`groq.model: openai/gpt-oss-20b`)
   - `backend/src/main/resources/application-prod.yml` (`groq.model: openai/gpt-oss-20b`)
   - `backend/src/main/java/com/medev/modules/ai/service/GroqClient.java`
   - `backend/src/main/java/com/medev/config/GroqHealthIndicator.java`
   - `.agents/AGENTS.md` (Правило 11)
   - `.agents/CONTEXT.md`

## 3. Итог

Любые обращения к AI (генерация summary, чат-ассистент, Smart Merge резюме, онбординг-визард) должны идти строго через модель `openai/gpt-oss-20b`.
