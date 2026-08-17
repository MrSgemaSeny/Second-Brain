# Мультитенантность через ThreadLocal (TenantContext)

**Проект:** Valeur

Для обеспечения изоляции данных B2B клиентов (тенантов) используется подход Shared Database / Shared Schema (все данные лежат в одних таблицах, но имеют колонку `tenant_id`).
Для того чтобы каждый раз вручную не передавать `tenant_id` во все методы сервисов и репозиториев, используется паттерн `ThreadLocal` контекста, совмещенный с Hibernate Filters.

## Как это работает

1. **API Gateway** валидирует JWT токен и достает из него `tenantId`.
2. Gateway пробрасывает `tenantId` в заголовок `X-Tenant-Id`.
3. **Микросервис** с помощью `TenantContextFilter` считывает этот заголовок и помещает в `TenantContext` (ThreadLocal).
4. **Spring Data JPA** / **Hibernate Aspect** читает `TenantContext` и автоматически добавляет `WHERE tenant_id = ?` ко всем запросам к БД.

### 1. TenantContext.java

Утилитный класс для безопасного хранения данных в рамках потока выполнения.

```java
public class TenantContext {
    private static final ThreadLocal<UUID> currentTenant = new InheritableThreadLocal<>();

    public static void setTenantId(UUID tenantId) {
        currentTenant.set(tenantId);
    }

    public static UUID getTenantId() {
        return currentTenant.get();
    }

    public static void clear() {
        currentTenant.remove();
    }
}
```

### 2. TenantContextFilter.java

Фильтр, который читает заголовки, устанавливает Spring Security Auth и TenantContext.

```java
@Component
public class TenantContextFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws IOException, ServletException {
        
        String tenantIdStr = request.getHeader("X-Tenant-Id");

        try {
            if (tenantIdStr != null && !tenantIdStr.isEmpty()) {
                TenantContext.setTenantId(UUID.fromString(tenantIdStr));
            }
            
            // ... (установка SecurityContextHolder из X-User-Id) ...

            chain.doFilter(request, response);
        } finally {
            // КРИТИЧНО ВАЖНО: Всегда очищать ThreadLocal, иначе данные могут утечь в другой поток Tomcat!
            TenantContext.clear();
            SecurityContextHolder.clearContext();
        }
    }
}
```

> [!CAUTION]
> Использование `ThreadLocal` в реактивных приложениях (Spring WebFlux) строго запрещено! Там контекст потока не привязан к одному запросу. В реактивном стеке нужно использовать `Reactor Context`. Но в рамках Valeur мы используем стандартный Servlet-based (Tomcat) подход (кроме API Gateway).
