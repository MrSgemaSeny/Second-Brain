# Защита межсервисного взаимодействия (X-Internal-Token)

**Проект:** Valeur

В микросервисах часто появляются эндпоинты, которые предназначены только для вызова из других микросервисов (например, проверить, существует ли вакансия, чтобы создать отклик). Эти эндпоинты не должны быть доступны извне (через фронтенд).

## Паттерн X-Internal-Token

Мы выделяем все внутренние API в префикс `/internal/**`.
API Gateway настроен пропускать запросы к `/internal/**` без проверки JWT, либо блокировать их.
Сами микросервисы проверяют наличие секретного статического токена `X-Internal-Token` в заголовке, чтобы убедиться, что запрос пришел от доверенного сервиса.

### 1. Фильтр в микросервисе (InternalTokenFilter)

Этот фильтр ставится в каждом микросервисе.

```java
@Component
@RequiredArgsConstructor
public class InternalTokenFilter extends OncePerRequestFilter {

    @Value("${internal.service.token}")
    private String expectedToken;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws IOException, ServletException {
        // Защищаем только префикс /internal/
        if (request.getRequestURI().startsWith("/internal/")) {
            String token = request.getHeader("X-Internal-Token");
            if (!expectedToken.equals(token)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
```

### 2. Вызов из другого сервиса (RestClient)

```java
@Service
public class VacancyServiceClient {

    @Value("${internal.service.token}")
    private String internalToken;

    public boolean checkVacancyExists(UUID vacancyId) {
        try {
            restClient.get()
                .uri("http://localhost:8081/internal/vacancies/" + vacancyId + "/exists")
                .header("X-Internal-Token", internalToken)
                .retrieve()
                .toBodilessEntity();
            return true;
        } catch (HttpClientErrorException.NotFound e) {
            return false;
        }
    }
}
```

> [!WARNING]
> Главное ограничение: этот паттерн подходит для простых систем и внутренних контуров (где трафик между сервисами изолирован). При росте системы может потребоваться mTLS (Service Mesh) или передача клиентского JWT по цепочке (Token Relay).
