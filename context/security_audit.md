# Full Security & Architecture Audit Report
**Date**: 2026-08-17
**Scope**: Backend API Gateway, Microservices (Identity, Vacancy, Application, AI), Frontend (React/Vite).

## 1. Critical Security Vulnerabilities

### 1.1. Gateway Header Spoofing (Authentication Bypass)
- **Location**: `api-gateway` -> `JwtAuthenticationFilter.java`
- **Severity**: **[CRITICAL]**
- **Description**: The API Gateway does not strip `X-User-Id`, `X-User-Role`, `X-Tenant-Id` headers from incoming HTTP requests. Since it uses `request.mutate().header(...)`, it *appends* headers instead of overriding them. An external attacker can send a request with `X-User-Id: <ADMIN_UUID>` and bypass authentication, gaining admin privileges downstream.

### 1.2. Broken JWT Subject Claim (Application Crash / Logic Bug)
- **Location**: `api-gateway` -> `JwtAuthenticationFilter.java`
- **Severity**: **[CRITICAL]**
- **Description**: The filter reads `claims.getSubject()` to populate `X-User-Id`. In `identity-service/JwtService.java`, the subject is set to the user's *email address*. However, downstream services (like `application-service` and `ai-service`) expect a `UUID` and call `UUID.fromString(userIdStr)`, which crashes with an `IllegalArgumentException` on every request. The correct claim to use is `claims.get("userId")`.

### 1.3. Direct Access Authentication Bypass
- **Location**: Microservices (`vacancy-service`, `application-service`, `ai-service`) -> `TenantContextFilter.java` & `InternalTokenFilter.java`
- **Severity**: **[CRITICAL]**
- **Description**: `TenantContextFilter` trusts the `X-User-Id` header unconditionally. `InternalTokenFilter` only validates the `X-Internal-Token` for paths starting with `/internal/`. If an attacker reaches a microservice directly (bypassing the Gateway), or via an SSRF vulnerability, they can supply their own headers and access any `/api/**` endpoint as any user.

## 2. Architecture & Tech Debt

### 2.1. Residual Mock Data in Frontend
- **Severity**: **[WARNING]**
- **Description**: The frontend still heavily relies on `db_helper.js` in many core components:
  - Analytics (`useAnalytics.ts`)
  - Notifications (`useNotifications.ts`)
  - Applications management (`useApplyLogic.ts`, `useManageApplication.ts`)
  - Matching (`useMatchChecker.ts`, `useCandidateSearch.ts`)
  - Testing (`useTestSession.ts`)
  - Profile editing & Settings (`EditProfileForm.tsx`, `useUserEditForm.ts`, etc.)
  - Admin dictionaries (`HardSkillsManager`, `SoftSkillsManager`)
- **Impact**: Feature-Sliced Design (FSD) boundaries are polluted with mock implementations. No actual data flow for these features.

### 2.2. Incomplete API Implementations
- **Severity**: **[WARNING]**
- **Description**: To remove the mocks, the backend must support the missing endpoints. For example, endpoints for Analytics, Notification bells, Candidate search, Skill Management, and Applications tracking are either missing or have non-matching response shapes compared to the frontend's expectations.

## 3. Recommended Remediation Plan

1. **Fix Gateway Spoofing**: Add a `GlobalFilter` in API Gateway to explicitly strip `X-User-Id`, `X-User-Role`, `X-Tenant-Id`, and `X-Internal-Token` from incoming external requests.
2. **Fix Claim Extraction**: Update `JwtAuthenticationFilter.java` to extract `userId` via `claims.get("userId", String.class)`.
3. **Secure Internal Microservices**: 
   - Gateway must add `X-Internal-Token` to *every* request proxied downstream.
   - Microservices must update `InternalTokenFilter` to apply to `/**`, validating the token on all requests to ensure they originated from the Gateway or a trusted internal service.
4. **Purge Mock Data**: Systematically migrate all 20+ frontend features from `db_helper` to `TanStack Query` hooks connecting to the respective backend microservices.

---

## 4. JF-1C (ZhanFinance) — Senior Security & Threat Modeling Blueprint

### 4.1. Threat Modeling (STRIDE Analysis)
- **Spoofing**: Instant token revocation via `RefreshTokenService.revokeAll(user)` upon role change / dismissal. WebSocket handshake re-authentication.
- **Tampering**: Sequential IDs (`task.id`) protected by row-level `CrmAccessService`. DTOs must exclude administrative fields (`assignedEmployeeId`, `stageType`) to prevent Mass Assignment.
- **Repudiation**: `@TransactionalEventListener(phase = AFTER_COMMIT)` on `AuditService` logging IP, user, entity ID, and previous/new state.
- **Information Disclosure**: Elimination of raw stack traces via `GlobalExceptionHandler` with UUID `requestId`. Secure avatar/document downloads with ACL validation.
- **Denial of Service**: Two-layer rate limiting (`ApiRateLimitFilter` + `AuthRateLimitFilter`), removal of in-memory pagination (`TaskSpecification`), `@BatchSize(50)` on LMS collections.
- **Elevation of Privilege**: `@PreAuthorize` + `CrmAccessService` verification for all CRM, Billing, Document, and Course operations.

### 4.2. Secrets Management & Rotation Strategy
- Zero-downtime JWT key rotation (key versioning: `kid` in JWT header with graceful validation of active + previous key).
- Strict separation of staging vs production secrets (Fly.io secrets isolation).
- Secret leak prevention: automated git pre-commit hooks and CI scan.

### 4.3. Supply Chain Security Gate
- Automated daily dependency scanning (`./gradlew dependencyCheckAnalyze`, `npm audit`).
- Pinned dependency versions in `package.json` and `build.gradle`.

### 4.4. Runtime Security & Anomaly Detection
- Business-level rate limiting (max tasks/requests per client).
- Security event alerting: alerts on brute-force attempts, consecutive 401/403 spikes, anomalous batch downloads.

### 4.5. Cryptography & Data Integrity
- Passwords: BCrypt (cost 10+) / Argon2id for password hashing.
- 2FA TOTP backup codes: hashed via BCrypt / SHA-256 before storing in DB.
- Document integrity: SHA-256 checksums / digital signature on generated official PDFs and DOCX templates.

### 4.6. Frontend Defense-in-Depth
- Security Headers: `Content-Security-Policy` (CSP), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
- Subresource Integrity (SRI) on external assets.

### 4.7. Phased Implementation Roadmap & Product Parallelism

#### Этап 1: До первого платящего клиента (Дни)
- **Security Headers Middleware**: Spring Security / WebMvcConfigurer + `_headers` / Cloudflare:
  - `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'`
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy: camera=(), microphone=(), geolocation=()`
- **CI Dependency Audit**: `npm audit --audit-level=high` и `./gradlew dependencyCheckAnalyze` (gate на High/Critical).
- **HSTS**: Активация Strict-Transport-Security после подключения Cloudflare на `zhanfinance.kz`.

#### Этап 2: До 10 платящих клиентов (Недели)
- **Бизнес Rate Limiting (Bucket4j)**:
  - `/api/v1/tasks/**` (100 req/min на `userId`)
  - `/api/v1/documents/**` (контроль частоты скачиваний)
  - `/api/v1/search/**` (защита ресурсоемкого поиска)
- **Graceful JWT Key Rotation**: Заголовок `kid`, поддержка двух ключей (текущий + предыдущий с TTL 15 мин).
- **WebSocket Per-Message Authorization**: `ChannelInterceptor.preSend()` валидация `userId` в destination (`/topic/chat/user-{id}`).
- **Forced Logout / Token Revocation**: Механизм мгновенной инвалидации access-токенов при блокировке/увольнении.

#### Этап 3: Зрелость (Месяцы, после стабильного revenue)
- **OWASP ZAP в CI (Staging)**: Пассивное сканирование трафика тестов.
- **Юридическая целостность документов**: SHA-256 контрольная сумма генерируемых актов/АВР в БД и на бланке.
- **Ручной Penetration Test**: Аудит внешним security-инженером через Burp Suite.


