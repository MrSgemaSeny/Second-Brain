# Архитектурный паттерн: AI-скоринг резюме и Smart Match на базе Llama 3.3 70B (Groq)

## Контекст и проблема
В B2B ATS / HR-платформах рекрутеры тратят до 70% времени на первичный отсев нерелевантных резюме. Требуется автоматический, быстрый (<1.5s) и детерминированный скоринг соответствия кандидата требованиям вакансии с расчетом Match % (0–100%) и детальной выжимкой сильных/слабых сторон.

## Архитектура решения

```mermaid
graph TD
    Client["Frontend (React 19)"] -->|POST /api/applications/{id}/ai-score| AppService["application-service (8083)"]
    AppService -->|X-Internal-Token| VacancyService["vacancy-service (8082)"]
    AppService -->|X-Internal-Token| IdentityService["identity-service (8081)"]
    AppService -->|POST /internal/ai/match-score| AiService["ai-service (8084)"]
    AiService -->|Groq API: Llama 3.3 70B| LLM["Groq Cloud"]
    AiService -->|JSON Match Verdict| AppService
    AppService -->|Save to application_ai_scores| DB[(PostgreSQL: application)]
```

### 1. Межсервисный контракт (`InternalAiController`)
- **Запрос**: `AiMatchScoreRequest` (`vacancyTitle`, `vacancyDescription`, `vacancyRequirements`, `candidateName`, `candidateSkills`, `candidateExperience`, `candidateBio`).
- **Ответ**: `AiMatchScoreResponse` (`matchScore: Integer [0..100]`, `strongMatches: List<String>`, `missingOrWeak: List<String>`, `recommendation: String`).

### 2. Системный промпт (`resume_match.txt`)
- Задаётся строгий JSON Schema режим с `temperature: 0.1` для детерминированности.
- Модель анализирует совпадение хард-скиллов, уровня опыта (Junior/Middle/Senior) и релевантности стека.
- В промпте запрещены галлюцинации и свободный текст вне JSON-структуры.

### 3. Персистенция и безопасность
- **Миграция Flyway**: `V3__add_application_ai_scores.sql` создает таблицу `application_ai_scores` с колонкой `tenant_id UUID NOT NULL` и внешним ключом на `applications`.
- **Изоляция данных**: Доступ к скорингу разрешен только сотрудникам компании-работодателя (`COMPANY_ADMIN`, `OWNER`, `HR_MANAGER`). Кандидату скоринг скрыт для предотвращения манипуляций.
- **Кэширование**: Результат скоринга сохраняется в БД; повторный запрос возвращает сохраненный вердикт без лишних вызовов LLM.

## Ключевые выводы
- Использование специализированного микросервиса `ai-service` изолирует зависимость от внешнего провайдера (Groq/OpenAI).
- Межсервисная коммуникация по `X-Internal-Token` исключает прямой вызов AI-модели из публичного интернета.
