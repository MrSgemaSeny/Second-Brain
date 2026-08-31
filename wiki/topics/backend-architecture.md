# Тема: Бэкенд Архитектура и Проектирование Систем

## Обзор
Бэкенд-экосистема проектов построена на базе Java 17, Spring Boot 3 и PostgreSQL 17 с акцентом на надежность, изоляцию данных и высокую производительность.

## Ключевые Концепции и Паттерны
- [[wiki/concepts/zero-n-plus-one-hibernate|Исключение N+1 Проблем в Hibernate]]
- [[wiki/concepts/transactional-outbox|Transactional Outbox Pattern]]
- [[wiki/concepts/rate-limiting-token-bucket|Token Bucket Rate Limiting]]
- [[wiki/concepts/multi-tenancy-isolation|Мультитенантность и TenantContext]]

## База Знаний и Статьи
- [[knowledge/arch-tiered-rate-limiting-bucket4j|Tiered Rate Limiting с Bucket4j и Caffeine]]
- [[knowledge/arch-transactional-outbox-event-automation|Transactional Outbox в монолите]]
- [[knowledge/arch-caffeine-cache|Локальное кэширование с Caffeine]]
- [[knowledge/arch-load-testing-hikari-cache|Тюнинг пулов HikariCP и нагрузочное тестирование]]
- [[knowledge/jvm-metaspace-tuning|Оптимизация памяти JVM (512MB RAM)]]
