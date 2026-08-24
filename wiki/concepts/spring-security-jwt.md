# Spring Security 6 & JWT Architecture
_Связи: [[fsd-architecture]]_

## Суть
Stateless авторизация в Spring Boot 3 на базе пары токенов: короткоживущий Access JWT (15–60 мин) + долгоживущий Refresh Token в Redis или базе данных (7–30 дней).

## Ключевые компоненты
- `JwtAuthenticationFilter` — перехват `Authorization: Bearer <token>`, валидация подписи, установка `SecurityContextHolder`.
- `InternalTokenFilter` — защита межсервисных вызовов через `X-Internal-Token`.
- `TenantContextFilter` — извлечение `tenant_id` из claims токена и установка в `ThreadLocal` для изоляции данных.
- `@EnableMethodSecurity` — ролевая защита методов через `@PreAuthorize("hasRole('ADMIN')")`.
