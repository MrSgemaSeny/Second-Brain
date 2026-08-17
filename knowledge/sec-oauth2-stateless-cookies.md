# Реализация OAuth2 в STATELESS архитектуре (Cookies)

## Суть проблемы
По умолчанию Spring Security `oauth2Login()` ожидает, что приложение использует серверные сессии (`JSESSIONID`). Во время редиректа на провайдера (Google/GitHub), Spring сохраняет параметры запроса (включая `state` для защиты от CSRF) в сессию с помощью `HttpSessionOAuth2AuthorizationRequestRepository`.

Если ваше приложение сконфигурировано как `STATELESS` (REST API с JWT), сессии не используются. В итоге Spring будет создавать новые сессии только для OAuth2, которые не будут очищаться, что приведет к **утечке памяти** (Memory Leak) и засорению сервера. Вдобавок, при горизонтальном масштабировании балансировщик может кинуть юзера на другой инстанс, где этой сессии нет, и OAuth2 авторизация упадет с ошибкой `authorization_request_not_found`.

## Как чинить (CookieOAuth2AuthorizationRequestRepository)
Необходимо переопределить способ хранения временных данных OAuth2 (состояния), сохраняя их не в памяти сервера, а на клиенте — во временных зашифрованных (или сериализованных) куках.

### 1. Создаем кастомный Repository
Нужно имплементировать интерфейс `AuthorizationRequestRepository<OAuth2AuthorizationRequest>`.
При методе `saveAuthorizationRequest` мы сериализуем объект запроса в Base64 (или шифруем) и кладем в `Cookie` с `HttpOnly` и `Max-Age` (например, 3 минуты). При `loadAuthorizationRequest` или `removeAuthorizationRequest` мы читаем куку и удаляем её.

### 2. Подключаем в SecurityConfig
```java
@Autowired
private CookieOAuth2AuthorizationRequestRepository cookieRepository;

// ...
.oauth2Login(oauth2 -> oauth2
    .authorizationEndpoint(a -> a.authorizationRequestRepository(cookieRepository))
    // ...
)
```

## Когда применять
Абсолютно во всех проектах со Spring Security, где используется JWT (или иные stateless токены) и одновременно включен `.oauth2Login()`.
