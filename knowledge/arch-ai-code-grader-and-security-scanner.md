# AI Code Grader & Static Security Scanner

## Назначение
Автоматизированная система проверки практических домашних заданий студентов с двухуровневым контролем:
1. **Fast-path: Статический сканер безопасности (Static Security Scanner)**.
2. **Deep-path: LLM-оценка по критериям (Rubric Evaluation)**.

## Архитектура пайплайна проверки

```
[Студент отправляет код]
          |
          v
[1. Static Security Scanner]
(Запрет опасных конструкций AST: Runtime.exec, ProcessBuilder, Reflection, System.exit)
          |
     +----+----+
     |         |
 (Threat)   (Clean)
     |         |
     v         v
 [Reject]   [2. LLM Rubric Evaluation]
 (Score: 0) (Критерии: Корректность, Архитектура, Безопасность, Чистота)
               |
               v
            [Расчёт суммарного балла (0..100)]
               |
          +----+----+
          |         |
     (Score >= 80) (Score < 80)
          |         |
          v         v
     [Auto-Pass] [Retry Needed]
  (Lesson Completed) (Feedback & Hints)
```

## Статический анализ безопасности (Regex & AST Checks)

Перед отправкой в LLM код студента проходит валидацию на опасные паттерны:
- `java.lang.reflect.*` / `setAccessible(true)`
- `Runtime.getRuntime().exec(...)` / `ProcessBuilder`
- `System.exit(...)`
- `Unsafe` операции и бесконечные циклы `while(true)` без условий выхода.

При обнаружении нарушений грейдер немедленно возвращает `400 Bad Request` или выставляет `0 баллов` с описанием угрозы безопасности, не расходуя токены LLM.

## Промпт-структурирование LLM Grader (Llama 3.3 70B)
Грейдер отвечает строго в формате JSON:
```json
{
  "score": 85,
  "passed": true,
  "summary": "Отличная реализация сервисного слоя с соблюдением принципа SRP.",
  "strengths": [
    "Использование @Transactional(readOnly = true) для запросов выборки",
    "Корректная обработка исключений EntityNotFoundException"
  ],
  "improvements": [
    "Рекомендуется вынести магические числа в константы"
  ]
}
```

## Автоматическое завершение урока
Если итоговый балл `score >= 80`, система автоматически вызывает `lessonProgressService.markCompleted(...)`, открывая доступ к следующему материалу без ручного участия ментора.
