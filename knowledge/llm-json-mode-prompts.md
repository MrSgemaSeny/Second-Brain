# LLM JSON Mode (Groq / OpenAI)

## Проблема
Если при вызове API (Groq или OpenAI) используется флаг `response_format: { type: "json_object" }`, то API жестко требует, чтобы в системном промпте (или сообщении пользователя) явно присутствовало слово "JSON".

## Симптомы
Если в промпте будет написано что-то вроде "return ONLY text, no JSON", сервер API (Groq) моментально вернёт **400 Bad Request**. В Spring Boot клиенте (через WebClient) это может обернуться в 500 ошибку или `LlmException`, если 400-е ответы не обрабатываются корректно.

## Решение
1. Если включен режим `json_object`, системный промпт ОБЯЗАН содержать инструкцию по возврату JSON.
2. Идеальный формат промпта: `Output format: Return a valid JSON object containing exactly one key "content" with the generated text as its value.`
3. На стороне Spring Boot эндпоинты, возвращающие эту JSON-строку, должны иметь аннотацию `@PostMapping(..., produces = MediaType.APPLICATION_JSON_VALUE)`, чтобы Axios на клиенте автоматически распарсил строку в JSON объект.
