# Паттерн: Tiered Rate Limiting с Bucket4j и Caffeine

## Суть
Ограничение частоты запросов на уровне Java Servlet Filter с разделением эндпоинтов на функциональные уровни (Tiers) с разными лимитами и ключами идентификации.

## Архитектура
```
HTTP Request 
   │
   ▼
OncePerRequestFilter (RateLimitingFilter)
   ├── 1. Извлечение пути (extractNormalizedPath)
   ├── 2. Определение Tier:
   │      ├── /v1/auth/** ──► AUTH (10 req/15m per IP)
   │      ├── /v1/ai/**   ──► AI (5 req/min per User)
   │      └── /v1/**      ──► GENERAL (60 req/min per User/IP)
   ├── 3. Формирование ключа (resolveKey): "ip:192.168.1.1" или "user:42"
   ├── 4. Получение Bucket из Caffeine кэша
   └── 5. probe = bucket.tryConsumeAndReturnRemaining(1)
          ├── isConsumed == true:
          │      Заголовок: X-RateLimit-Remaining: {N}
          │      Пропуск дальше по FilterChain
          └── isConsumed == false:
                 Заголовки: Retry-After: {seconds}, X-RateLimit-Remaining: 0
                 Ответ: HTTP 429 Too Many Requests (JSON ErrorResponse)
```

## Важные нюансы реализации
1. **Refill Strategy:** Использовать `refillIntervally(tokens, duration)`, а не `refillGreedy`, когда требуются строгие дискретные лимиты на весь интервал без непрерывного помиллисекундного подсыпания токенов.
2. **Caffeine Cache:** `expireAfterAccess(1, TimeUnit.HOURS)` и `maximumSize(50_000)` предотвращают утечки памяти при большом числе уникальных IP.
3. **CORS Safe:** Фильтр обязан пропускать HTTP метод `OPTIONS` без проверки токенов во избежание блокировки CORS pre-flight запросов.
