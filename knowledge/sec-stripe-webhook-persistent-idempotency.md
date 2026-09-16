# Двухуровневая Идемпотентность Вебхуков (Stripe / Kaspi) и Синхронизация Подписок

## Проблема: Уязвимости обработки финансовых вебхуков
1. **Потеря состояния в Redis**: вебхуки Stripe могут повторно доставляться в течение 72 часов. Кэш с TTL 24 часа не защищает от повторной обработки устаревших событий.
2. **Дрейф дат (Billing Date Drift)**: при расчете даты истечения подписки через `now().plusMonths(1)` накапливается систематическая ошибка по сравнению с календарем биллинга провайдера.
3. **Параллельная доставка одинаковых событий**: при сетевых задержках Stripe может послать 2 одинаковых POST запроса с миллисекундным интервалом, вызывая дублирование записей о платеже.

## Архитектура: Двухуровневая Идемпотентность

```
[Stripe Webhook POST]
         │
    1. Signature Verification (HMAC-SHA256)
         │
    2. Redis SETNX "stripe:webhook:{eventId}" (Fast Layer)
         ├── FALSE -> 200 OK (Дубликат, пропуск)
         └── TRUE  -> Продолжить
                  │
             3. PostgreSQL @Transactional (Persistent Layer)
                  ├── Проверка INSERT INTO stripe_webhook_events (event_id UNIQUE)
                  ├── Обновление User (plan = PRO, expires_at = current_period_end)
                  ├── Инвалидация кэша плана: DEL user_plan:{userId}
                  └── Запись в Audit Log
```

### 1. DDL Идемпотентности (Flyway V29)
```sql
CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    id BIGSERIAL PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL UNIQUE,
    event_type VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_event_id ON stripe_webhook_events (event_id);
```

### 2. Синхронизация по `current_period_end`
```java
if (subscription != null && subscription.getCurrentPeriodEnd() != null) {
    long periodEndSeconds = subscription.getCurrentPeriodEnd();
    LocalDateTime expiresAt = LocalDateTime.ofInstant(
        Instant.ofEpochSecond(periodEndSeconds), 
        ZoneOffset.UTC
    );
    user.setSubscriptionExpiresAt(expiresAt);
} else {
    user.setSubscriptionExpiresAt(LocalDateTime.now().plusMonths(1)); // Fallback
}
```

## Правило для продакшена
Никогда не полагаться только на Redis для дедупликации финансовых транзакций. База данных PostgreSQL с `UNIQUE CONSTRAINT` на `event_id` является единственным надежным источником истины.
