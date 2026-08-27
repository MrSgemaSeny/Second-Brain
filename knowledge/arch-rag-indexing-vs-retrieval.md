# RAG: Indexing Pipeline vs Retrieval — что реализовано в MeDev

**Дата:** 2026-08-26
**Контекст:** Аудит AI-модуля MeDev. Spring AI + pgvector + Groq.

---

## Суть RAG (Retrieval-Augmented Generation)

RAG — это архитектурный паттерн, при котором LLM получает не только запрос пользователя,
но и **релевантный контекст**, предварительно найденный через семантический поиск по векторной базе.

```
Пользователь → [запрос] → Система
                              ↓
                    Векторный поиск (pgvector)
                    "Найди топ-5 документов похожих на запрос"
                              ↓
                    Контекст + Запрос → LLM (Groq)
                              ↓
                    Ответ с учётом реального контекста пользователя
```

Без RAG LLM отвечает только на основе своих обучающих данных.
С RAG LLM отвечает с учётом **твоих конкретных данных** (проекты, опыт, резюме).

---

## Два обязательных пайплайна

### Pipeline 1: Indexing (Запись векторов)
Когда данные меняются → переводим текст в вектор → сохраняем в pgvector.

```
ProfileUpdatedEvent → VectorizationService → EmbeddingModel → VectorStore.add()
```

**Статус в MeDev:** РЕАЛИЗОВАН (`VectorizationService.java`).
- Слушает `ProfileUpdatedEvent` через `@Async @EventListener`
- Векторизует `Projects` + `Experiences` каждого пользователя
- Удаляет старые векторы → добавляет новые
- Ночной крон в 3:00 чистит осиротевшие записи

### Pipeline 2: Retrieval (Чтение и поиск)
Когда нужен ответ → ищем похожие документы → подставляем в промпт.

```
Запрос пользователя → vectorStore.similaritySearch() → топ-K документов → промпт → LLM
```

**Статус в MeDev:** НЕ РЕАЛИЗОВАН.
`similaritySearch()` нигде не вызывается. Данные в pgvector есть, но не используются.

---

## Где в MeDev должен жить Retrieval

### Вариант A (основной): Job Tracker AI Match
Пользователь вставляет описание вакансии → система ищет похожий опыт → Groq объясняет совпадения.

```java
// В AiAnalysisService или новом JobMatchService:
List<Document> relevant = vectorStore.similaritySearch(
    SearchRequest.query(jobDescription)
        .withTopK(5)
        .withFilterExpression("userId == '" + userId + "'")
);

String context = relevant.stream()
    .map(Document::getContent)
    .collect(Collectors.joining("\n\n"));

String prompt = "На основе опыта пользователя:\n" + context +
                "\n\nОцени совпадение с вакансией:\n" + jobDescription;

return groqClient.structuredCompletion(systemPrompt, prompt);
```

### Вариант B (дополнительный): AI Chat с контекстом профиля
Чат-ассистент отвечает на вопросы о карьере, зная реальный опыт пользователя.

---

## Почему pgvector + Spring AI

- `pgvector` — расширение PostgreSQL, которое уже есть в проекте (Flyway-миграция, `initialize-schema: false`)
- `spring-ai-core` — уже в `build.gradle`, даёт `VectorStore` и `EmbeddingModel` абстракции
- Embedding-модель нужна для перевода текста → вектор. В текущей реализации использует Spring AI default (локальная или через API)
- Размерность: `dimensions: 384` (в `application.yml`) — стандарт для лёгких моделей (e5-small, all-MiniLM)

---

## Главный инсайт

Наличие `VectorizationService` без `similaritySearch()` — это как построить библиотеку,
расставить все книги по полкам, но убрать каталог и читальный зал.
Данные есть. Поиска нет.

**Ключевой риск текущего состояния:**
Каждое обновление профиля запускает дорогостоящую операцию векторизации (IO + embedding API),
но результат нигде не используется. Это чистый overhead без пользы.

**Решение:**
1. Либо реализовать Retrieval (сделать RAG полноценным)
2. Либо отключить VectorizationService до момента реализации Retrieval (сэкономить ресурсы)

---

## Связанные заметки
- [[arch-ai-chat-integrations]] — SSE стриминг, AI в чате
- [[arch-ai-structured-generation]] — JSON-режим Groq
- [[arch-ai-smart-merge]] — Smart Merge через LLM
