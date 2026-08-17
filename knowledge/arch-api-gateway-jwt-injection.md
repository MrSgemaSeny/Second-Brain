# Инъекция JWT Claims на уровне API Gateway

**Проект:** Valeur

В микросервисной архитектуре одна из главных проблем — как каждый микросервис будет авторизовывать запросы. Если каждый сервис будет сам парсить JWT, мы получаем дублирование кода, необходимость шарить секретный ключ (`jwt.secret`) между всеми сервисами и лишние вычисления.

## Решение: API Gateway как единая точка проверки

Паттерн заключается в том, что Spring Cloud Gateway полностью берет на себя валидацию JWT токена, расшифровывает его (Claims) и передает полезную нагрузку в нижестоящие сервисы в виде HTTP-заголовков. Нижестоящие сервисы больше не нуждаются в зависимости от `jjwt` и просто читают безопасные заголовки.

### Код: JwtAuthenticationFilter.java (API Gateway)

```java
@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    @Value("${jwt.secret}")
    private String secretKey;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // ... (пропуски для краткости, проверка наличия токена) ...

        String token = authHeader.substring(7);
        try {
            SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            // ПРОБРОС CLAIMS В ЗАГОЛОВКИ
            ServerHttpRequest.Builder requestBuilder = request.mutate()
                    .header("X-User-Id", claims.getSubject())
                    .header("X-User-Role", claims.get("role", String.class));
            
            String tenantId = claims.get("tenantId", String.class);
            if (tenantId != null) {
                requestBuilder.header("X-Tenant-Id", tenantId);
            }

            // Передача модифицированного реквеста вниз
            return chain.filter(exchange.mutate().request(requestBuilder.build()).build());
        } catch (Exception e) {
            return onError(exchange, "JWT token validation failed", HttpStatus.UNAUTHORIZED);
        }
    }
}
```

### Безопасность
Ключевой момент: мы должны доверять заголовкам `X-User-Id`, пришедшим снаружи? НЕТ!
Gateway должен очищать эти заголовки, если запрос идет извне (или, по крайней мере, перезаписывать их из токена). В Valeur Gateway полностью перезаписывает эти заголовки на основе надежной подписи JWT, поэтому клиент не может "подделать" `X-User-Id` в обход токена.
