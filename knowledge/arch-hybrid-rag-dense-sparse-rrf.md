# Гибридный RAG: Dense Vector Search (pgvector HNSW) + Sparse FTS (RRF)

## Контекст и Проблема
Классический векторный поиск (Dense Search через Cosine Similarity) отлично находит смысловые ассоциации, но часто пасует перед точными запросами по именам классов, аннотациям или специфическим ошибкам (например, `org.springframework.security.access.AccessDeniedException`).
Полнотекстовый поиск (Sparse FTS через `tsvector`/`tsquery`), напротив, точно находит ключевые слова, но не понимает синонимов.

## Решение: Гибридный Поиск с Reciprocal Rank Fusion (RRF)

В модуле `rag` в MrDevCourses мы объединили оба подхода в рамках единой PostgreSQL базы:

```
[Пользовательский Запрос]
          |
   +------+------+
   |             |
   v             v
[Vector Search]  [Sparse FTS]
(pgvector HNSW)  (to_tsquery)
(Топ 10)         (Топ 10)
   |             |
   +------+------+
          |
          v
   [RRF Переранжирование]
   RRF_Score = 1 / (60 + rank_dense) + 1 / (60 + rank_sparse)
          |
          v
   [Итоговый Контекст для LLM]
```

## Реализация в SQL

```sql
WITH dense_search AS (
    SELECT id, content, ROW_NUMBER() OVER (ORDER BY embedding <=> :queryVector) AS rank_dense
    FROM lesson_chunks
    WHERE course_id = :courseId
    LIMIT 20
),
sparse_search AS (
    SELECT id, content, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(fts_vector, plainto_tsquery('russian', :queryText)) DESC) AS rank_sparse
    FROM lesson_chunks
    WHERE course_id = :courseId AND fts_vector @@ plainto_tsquery('russian', :queryText)
    LIMIT 20
)
SELECT 
    COALESCE(d.id, s.id) AS id,
    COALESCE(d.content, s.content) AS content,
    (COALESCE(1.0 / (60 + d.rank_dense), 0.0) + COALESCE(1.0 / (60 + s.rank_sparse), 0.0)) AS rrf_score
FROM dense_search d
FULL OUTER JOIN sparse_search s ON d.id = s.id
ORDER BY rrf_score DESC
LIMIT 5;
```

## Преимущества
1. **Нулевая внешняя инфраструктура**: Нет необходимости поднимать отдельный Elasticsearch/OpenSearch или Pinecone/Qdrant. Всё живёт внутри PostgreSQL с расширениями `pgvector` и `pg_trgm`.
2. **Максимальная точность RAG**: Студент находит ответ и по абстрактному вопросу ("как защитить эндпоинт"), и по точному имени аннотации ("@PreAuthorize").
3. **AST-Aware Chunking**: Разбиение конспектов на чанки сохраняет целостность блоков кода (```java ... ```), не разрезая их посредине метода.
