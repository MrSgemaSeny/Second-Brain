# ADR-007: Использование RestClient для межсервисного взаимодействия

**Дата:** 2026-08-17
**Статус:** Принято
**Проект:** Valeur

## Контекст
В микросервисной архитектуре сервисам (например, `application-service`) необходимо синхронно запрашивать данные у других сервисов (например, проверить существование вакансии в `vacancy-service`).
В экосистеме Spring есть несколько вариантов: `RestTemplate` (legacy), `WebClient` (reactive), `FeignClient` (declarative) и новый `RestClient` (введен в Spring 6.1). Кроме того, можно использовать gRPC.

## Решение
Для синхронного межсервисного HTTP-взаимодействия использовать исключительно `RestClient` от Spring Framework 6.1. Отказаться от gRPC и Kafka на старте ради снижения оверхеда на инфраструктуру, в соответствии с принципом модульного монолита / прагматичных микросервисов.

### Паттерн
```java
@Configuration
public class RestClientConfig {
    @Bean
    public RestClient restClient() {
        return RestClient.create();
    }
}

// Пример использования с Internal Token
@Service
public class VacancyServiceClient {
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

## Последствия (Trade-offs)
- **Плюсы:** 
  - Современный fluent API (в отличие от громоздкого `RestTemplate`).
  - Синхронный и простой код (в отличие от `WebClient`, который тянет реактивные зависимости WebFlux).
  - Отсутствие "магии" и проблем с контекстами безопасности (в отличие от `FeignClient`).
- **Минусы:** 
  - Синхронные блокирующие вызовы (могут стать узким местом при высоких нагрузках, тогда потребуется переход на асинхронный паттерн с RabbitMQ/Kafka).
