# Архитектура Мультитенантности и Оптимизации RAG в pgvector

## Проблема: Уязвимости и неэффективность наивного RAG
1. **Фильтрация по JSON-полям**: использование `WHERE metadata->>'userId' = ?` не защищено строгой типизацией БД, не имеет внешних ключей и приводит к медленному Seq Scan при росте базы.
2. **Orphaned Vectors**: при удалении пользователя записи в `vector_store` остаются навсегда, забивая HNSW-индексы и память.
3. **Full Re-indexing Overhead**: изменение одной строчки в резюме вызывало полную очистку всех векторов пользователя и повторный вызов дорогостоящей нейросети для всего профиля.

## Решение: Реляционная Схема + Контентное Хеширование

### 1. DDL Миграция Flyway (Реляционная изоляция)
```sql
-- Flyway V29
ALTER TABLE vector_store ADD COLUMN IF NOT EXISTS user_id BIGINT;

UPDATE vector_store 
SET user_id = CAST(metadata->>'userId' AS BIGINT) 
WHERE metadata IS NOT NULL AND metadata->>'userId' IS NOT NULL;

ALTER TABLE vector_store 
ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE vector_store 
ADD CONSTRAINT fk_vector_store_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_vector_store_user_id ON vector_store (user_id);
```

### 2. SQL Запрос сходства с жестким WHERE
```sql
SELECT content 
FROM vector_store 
WHERE user_id = :userId 
ORDER BY embedding <=> :queryVector::vector 
LIMIT :topK;
```

### 3. Chunk Content Hash Caching (SHA-256)
Каждый фрагмент данных перед отправкой в Jina AI / OpenAI проверяется на изменение:

```
[Profile Data] -> Chunk String -> SHA-256 (ChunkHash)
                     │
          Существует в БД с тем же ChunkHash?
             ├── ДА  -> Пропустить вызов Embedding API (взять существующий вектор)
             └── НЕТ -> Отправить на векторизацию в Jina AI -> Сохранить в БД
```

### 4. Версионирование метаданных
В JSON-метаданных каждого вектора сохраняются системные параметры:
```json
{
  "userId": "42",
  "type": "EXPERIENCE",
  "sourceId": "105",
  "model": "jina-embeddings-v2-base-en",
  "version": "1.0",
  "dimension": "768",
  "chunkHash": "a3f5c9e..."
}
```
При смене модели эмбеддингов версия инкрементируется, что позволяет триггерить фоновую миграцию без остановки сервиса.
