# Концепция: Мультитенантность и Изоляция Данных (Multi-Tenancy)

## Типы Мультитенантности:
1. **Discriminator Column (Single Table)**: Каждая таблица содержит `tenant_id`. Фильтрация через Hibernate `@Filter` или JPA Specification. Подходит для B2B SaaS с тысячами мелких клиентов (JF-1C, Valeur).
2. **Schema-per-Tenant**: Отдельная схема PostgreSQL для каждого тенанта. Высокая изоляция, простота резервного копирования и миграций.
3. **Database-per-Tenant**: Отдельный инстанс БД. Применяется для Enterprise и банковских требований.

## Механизм `TenantContext` через `ThreadLocal`
Входящий HTTP запрос через Gateway или Security Filter перехватывает заголовок `X-Tenant-Id` или извлекает его из JWT-клейма:
```java
public final class TenantContext {
    private static final ThreadLocal<String> CURRENT_TENANT = new ThreadLocal<>();

    public static void setTenantId(String tenantId) { CURRENT_TENANT.set(tenantId); }
    public static String getTenantId() { return CURRENT_TENANT.get(); }
    public static void clear() { CURRENT_TENANT.remove(); } // Критично в пуле потоков!
}
```
**Важное правило**: Всегда очищать `ThreadLocal` в блоке `finally` фильтра сервлета во избежание утечки данных между пользователями в пуле потоков Tomcat/Netty.
