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

---

## Проблема Stale Data: @CacheEvict vs TTL Expiry

Кэш может отдавать устаревшие данные (Stale Data) в двух сценариях:
1. **Отсутствие или ошибка `@CacheEvict`:** Сущность изменилась в БД через прямой SQL, фоновый джоб или сторонний сервис, но событие инвалидации не очистило ключ.
2. **Истечение TTL без принудительной очистки:** Запись должна была протухнуть, но из-за ленивого механизма очистки или неверной настройки политик времени отдается потребителю.

### Механика очистки Caffeine: Ленивая инвалидация (Lazy Maintenance)
Caffeine **не создает отдельный системный поток на каждый ключ** для отслеживания истечения миллисекунд. Это фундаментальное архитектурное решение для минимизации оверхеда памяти и CPU:
- Проверка протухания записи происходит **в момент обращения** (`get`) или при последующих записях (`put`).
- Амортизированная очистка устаревших записей запускается пакетами через `ForkJoinPool.commonPool()`.
- **Следствие:** При тестировании нельзя просто проверять `cache.asMap().size()`, так как протухшие ключи могут физически оставаться в Map до первого цикла обслуживания или прямого обращения.

---

## Стратегия тестирования TTL Expiry (Без Thread.sleep)

Использование `Thread.sleep(TTL + delta)` в тестах запрещено: это делает сборку медленной, нестабильной (flaky) и зависимой от загрузки процессора в CI/CD пайплайне.

### 1. Внедрение виртуального времени через Caffeine `Ticker`
Для детерминированного тестирования TTL в конфигурацию Caffeine внедряется интерфейс `com.github.benmanes.caffeine.cache.Ticker`:

```java
// Production config
@Bean
public Ticker caffeineTicker() {
    return Ticker.systemTicker();
}

@Bean
public Cache<String, Object> crmCache(Ticker ticker) {
    return Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(15))
            .maximumSize(10_000)
            .ticker(ticker)
            .build();
}
```

### 2. Тестовый сценарий с контролируемым временем (FakeTicker)
В тестах подставляется управляемый Ticker (например, `FakeTicker` из Guava / кастомный атомарный наносекундный генератор):

```java
@Test
void shouldExpireDataAfterTtlWithoutExplicitEvict() {
    TestTicker testTicker = new TestTicker();
    Cache<String, PipelineDto> cache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(15))
            .ticker(testTicker::read)
            .build();

    // 1. Кладем данные в кэш
    cache.put("pipeline:1", new PipelineDto(1L, "Sales"));
    assertThat(cache.getIfPresent("pipeline:1")).isNotNull();

    // 2. Сдвигаем виртуальное время на 14 минут (данные обязаны быть валидны)
    testTicker.advance(Duration.ofMinutes(14));
    assertThat(cache.getIfPresent("pipeline:1")).isNotNull();

    // 3. Сдвигаем еще на 2 минуты (суммарно 16 мин > TTL 15 мин)
    testTicker.advance(Duration.ofMinutes(2));

    // 4. Принудительная синхронизация буферов (при необходимости строгой проверки размера)
    cache.cleanUp();

    // 5. Проверяем, что кэш отдает null и форсирует повторное чтение из БД/сервиса
    assertThat(cache.getIfPresent("pipeline:1")).isNull();
}
```

### 3. Тестирование сквозного Spring `@Cacheable` сервиса
При тестировании сервисного слоя проверяется количество реальных обращений к репозиторию:
1. Первый вызов `service.getById(1L)` -> `verify(repository, times(1)).findById(1L)`.
2. Второй вызов до истечения TTL -> результат берется из кэша, `verify(repository, times(1)).findById(1L)`.
3. Сдвиг виртуального времени `ticker.advance(TTL + 1s)` и вызов `cache.cleanUp()`.
4. Третий вызов `service.getById(1L)` -> фиксация протухания кэша, повторный поход в базу: `verify(repository, times(2)).findById(1L)`.

