# Атомарный Rate Limiting на Redis + Lua (Устранение TOCTOU Race Conditions)

## Проблема: Time-of-Check to Time-of-Use (TOCTOU)
При раздельных операциях `GET -> CHECK -> INCR` в распределенном кэше параллельные потоки считывают одинаковое состояние счетчика до его инкремента:

```
Поток 1: GET ai_limit:user:1 -> "9" (проверка: 9 < 10 -> OK)
Поток 2: GET ai_limit:user:1 -> "9" (проверка: 9 < 10 -> OK)
Поток 1: INCR ai_limit:user:1 -> 10
Поток 2: INCR ai_limit:user:1 -> 11 (Лимит превышен!)
```

В результате пользователи с параллельными вкладками или боты тратят в 2–5 раз больше квот дорогостоящих API (LLM, Embeddings, SMS).

## Решение: Атомарный Lua-скрипт в Redis

Redis исполняет Lua-скрипты в едином однопоточном контексте атомарно — ни один другой запрос не может вклиниться между чтением и записью.

### 1. Lua Скрипт
```lua
local current = redis.call('get', KEYS[1])
local limit = tonumber(ARGV[1])
local ttl = tonumber(ARGV[2])

if current and tonumber(current) >= limit then
    return -1
end

local newVal = redis.call('incr', KEYS[1])
if newVal == 1 then
    redis.call('expire', KEYS[1], ttl)
end
return newVal
```

### 2. Реализация на Spring Boot (StringRedisTemplate)
```java
@Component
public class AiRateLimiter {

    private final StringRedisTemplate redisTemplate;
    private final RedisScript<Long> rateLimitScript;

    public AiRateLimiter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        DefaultRedisScript<Long> script = new DefaultRedisScript<>();
        script.setScriptText(
            "local current = redis.call('get', KEYS[1]) " +
            "local limit = tonumber(ARGV[1]) " +
            "local ttl = tonumber(ARGV[2]) " +
            "if current and tonumber(current) >= limit then return -1 end " +
            "local newVal = redis.call('incr', KEYS[1]) " +
            "if newVal == 1 then redis.call('expire', KEYS[1], ttl) end " +
            "return newVal"
        );
        script.setResultType(Long.class);
        this.rateLimitScript = script;
    }

    public boolean tryConsume(Long userId, int limit) {
        String key = "ai_limit:" + userId + ":" + LocalDate.now();
        long ttlSeconds = Duration.between(LocalDateTime.now(), LocalDate.now().plusDays(1).atStartOfDay()).toSeconds();
        
        Long result = redisTemplate.execute(
            rateLimitScript,
            List.of(key),
            String.valueOf(limit),
            String.valueOf(ttlSeconds)
        );
        
        return result != null && result != -1L;
    }
}
```

## Тестирование конкурентности
Для доказательства отсутствия race condition используется `CountDownLatch` с пулом потоков:
```java
@Test
void concurrentRequests_strictlyEnforceLimit() throws Exception {
    int threads = 20;
    int limit = 5;
    ExecutorService executor = Executors.newFixedThreadPool(threads);
    CountDownLatch startGate = new CountDownLatch(1);
    CountDownLatch endGate = new CountDownLatch(threads);
    AtomicInteger successCount = new AtomicInteger(0);

    for (int i = 0; i < threads; i++) {
        executor.submit(() -> {
            try {
                startGate.await();
                if (limiter.tryConsume(userId, limit)) {
                    successCount.incrementAndGet();
                }
            } finally {
                endGate.countDown();
            }
        });
    }

    startGate.countDown();
    endGate.await(5, TimeUnit.SECONDS);
    
    assertThat(successCount.get()).isEqualTo(limit); // Ровно 5 успехов, 15 отказов
}
```
