# Microservices Architecture Patterns

Extracted from modern platforms like "Valeur" (Spring Boot 3 + Spring Cloud).

## 1. API Gateway Pattern
- **Component**: Spring Cloud Gateway.
- **Responsibility**: Single entry point for all frontend traffic. Handles cross-cutting concerns:
  - **CORS**: Configured globally at the Gateway level.
  - **Auth Validation**: A global `JwtAuthenticationFilter` intercepts requests, validates the JWT signature, and checks expiration.
  - **Header Injection (Downstream)**: After validating the JWT, it parses claims (`userId`, `tenantId`, `role`) and injects them as HTTP headers (`X-User-Id`, `X-Tenant-Id`, `X-User-Role`) before routing the request to downstream microservices. This makes downstream services completely stateless and agnostic of JWT logic.

## 2. Inter-Service Communication
- **Synchronous**: Spring `RestClient` (introduced in Spring 6.1). Preferable over `RestTemplate` or `WebClient` for simple, blocking inter-service calls when reactive streams aren't needed.
- **Security**: 
  - Internal endpoints (`/api/internal/**`) are secured using an `X-Internal-Token` header.
  - Downstream services implement an `InternalTokenFilter` to block external access to these routes.
  - Example: `application-service` checking if a vacancy exists in `vacancy-service` before creating an application.

## 3. Database per Service
- Each microservice owns its data schema. 
- In smaller projects or cost-sensitive environments, services can share the same physical PostgreSQL instance, but operate on logically isolated schemas (e.g. `CREATE SCHEMA identity;`, `CREATE SCHEMA vacancy;`).
- Cross-service joins are forbidden. Data must be joined at the API Gateway level, BFF (Backend-For-Frontend) level, or resolved asynchronously.

## 4. Rate Limiting (In-Memory)
- **Bucket4j**: Used for lightweight, localized rate limiting (e.g., limiting AI text generation to 10 requests per minute).
- If horizontal scaling is required, Bucket4j can be backed by Redis (using JCache/Lettuce).
