# Caffeine Cache Per-Region Policy

## Overview
In-memory caching is implemented using `Caffeine` to reduce database load and improve response times for frequently accessed data.

## Implementation Details & ADR (Architecture Decision Record)
- **Per-Region Caching**: Caches are divided into logical regions (e.g., `pipelines` for CRM, `documents` for templates). 
- **Configuration**: Each region (`CacheConfig`) defines its own rules for maximum size, expiration time (TTL), and eviction policies.

### L1 (Caffeine) vs L2 (Redis) Cache
При проектировании отказоустойчивых систем (особенно под DDoS или Spike-нагрузки вроде 500 RPS) выбор между локальным и распределенным кэшем критичен:
- **Redis (L2):** Распределенный кэш. Спасает БД, но имеет сетевую задержку (1-5 мс). Идеален для горизонтального масштабирования (несколько инстансов Spring Boot).
- **Caffeine (L1):** Локальный кэш внутри самой JVM (Heap). Скорость отдачи — **наносекунды (0.0001 мс)**. Сетевых походов нет вообще.

**ADR:** Для single-instance деплоев (MVP, бесплатные тарифы вроде Render 0.1 CPU) и Read-Heavy публичных профилей паттерн **Caffeine L1 Cache** (как это было сделано в проекте JF-1C) является идеальным бронежилетом. Один слабый инстанс с настроенным Caffeine способен отдавать JSON из оперативной памяти тысячам пользователей, полностью минуя пул соединений к базе данных (HikariCP) и обходя узкие места сетевого I/O.
