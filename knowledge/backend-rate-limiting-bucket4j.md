# In-Memory Rate Limiting с Bucket4j

**Проект:** Valeur (ai-service)

Для защиты платных или тяжелых ресурсов (таких как API вызовы к LLM) необходимо ограничивать частоту запросов. В `ai-service` реализован Rate Limiting через библиотеку Bucket4j.

## Алгоритм Token Bucket

Представьте корзину (bucket), в которой лежат токены (например, 10 штук).
Каждый вызов API забирает один токен из корзины.
Корзина пополняется со скоростью N токенов в минуту/секунду.
Если корзина пуста, запрос отклоняется (429 Too Many Requests).

### Реализация (RateLimitingService.java)

Использует `ConcurrentHashMap` для хранения корзин в оперативной памяти (In-Memory). Для распределенного лимитинга (между репликами) потребуется интеграция Bucket4j с Redis, но для текущей архитектуры достаточно In-Memory.

```java
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RateLimitingService {

    // Храним корзины по Tenant ID или User ID
    private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    public Bucket resolveBucket(String key) {
        return cache.computeIfAbsent(key, this::newBucket);
    }

    private Bucket newBucket(String key) {
        // Конфигурация: 10 запросов в минуту максимум
        Bandwidth limit = Bandwidth.classic(10, Refill.greedy(10, Duration.ofMinutes(1)));
        return Bucket.builder()
                .addLimit(limit)
                .build();
    }
}
```

### Применение в Контроллере

```java
@PostMapping("/summary")
public ResponseEntity<?> generateSummary(@RequestBody SummaryRequest request,
                                         @RequestHeader(value = "X-Tenant-Id", required = false) String tenantId) {
                                         
    // В B2B системе часто лимитируют не пользователя, а целую компанию (тенанта)
    String rateLimitKey = (tenantId != null) ? tenantId : "anonymous";
    Bucket bucket = rateLimitingService.resolveBucket(rateLimitKey);

    if (bucket.tryConsume(1)) {
        // Разрешено (Токен забрали)
        SummaryResponse response = aiService.generateSummary(request);
        return ResponseEntity.ok(response);
    } else {
        // Лимит исчерпан
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .body("Rate limit exceeded. Try again later.");
    }
}
```
