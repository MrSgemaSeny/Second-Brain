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
