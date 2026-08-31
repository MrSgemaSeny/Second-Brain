# Transactional Outbox Pattern в Модульном Монолите

## Контекст и Проблема
В монолите часто требуется выполнять асинхронные или фоновые действия после завершения бизнес-транзакции (например: пересчитать семантические связи глоссария, отправить уведомление об открытии когорты, спрогнозировать отток студентов).
Прямой вызов внешних сервисов или тяжелых вычислений внутри `@Transactional` метода:
- Блокирует соединение с БД и поток запроса пользователя.
- Приводит к несогласованности: если запрос завершится ошибкой, внешнее действие уже выполнено.

## Решение: Таблица `outbox_events` и `@Scheduled` процессор

```
[Пользовательский Запрос]
          |
          v
[@Transactional Service]
  ├── 1. Изменение сущности (например, Lesson completed)
  └── 2. Запись в outbox_events (status = 'PENDING')
          |
       [COMMIT] (Атомарно в одной транзакции БД)
          |
          v
[Фоновый OutboxProcessor (@Scheduled)]
  ├── Чтение пачки PENDING событий: SELECT ... WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED
  ├── Обработка события соответствующим обработчиком (EventHandler)
  └── Обновление статуса: status = 'PROCESSED' (или 'FAILED')
```

## DDL Таблицы `outbox_events`

```sql
CREATE TABLE outbox_events (
    id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(64) NOT NULL,
    aggregate_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    retry_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_outbox_pending ON outbox_events(status, created_at) WHERE status = 'PENDING';
```

## Преимущества
1. **At-Least-Once Delivery**: Событие гарантированно сохранится, если закоммитилась основная транзакция.
2. **Отсутствие тяжелых внешних брокеров**: Идеально подходит для Level 3 (Educational MVP) без Kafka/RabbitMQ.
3. **Изоляция сбоев**: Если фоновый воркер упадет, запрос пользователя не пострадает.
