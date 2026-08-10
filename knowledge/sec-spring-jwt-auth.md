# Spring Security JWT Setup & Authorization

## JWT Authentication Flow
- **Access Tokens**: Contain user info (id, email, roles) and have a short expiration time (1 hour). Sent in the `Authorization: Bearer <token>` header.
- **Refresh Tokens**: Used to obtain a new access token without re-authenticating. Stored securely in an `httpOnly` cookie with `SameSite=strict` to protect against XSS and CSRF attacks. Lifetime is 7 days.

## Implementation Details
- `JwtAuthenticationFilter` intercepts requests, extracts the Bearer token, validates it via `JwtService`, and sets the `SecurityContext`.
- **Rate Limiting**: `Bucket4j` limits authentication attempts (e.g., 5 logins per minute) via `AuthRateLimitFilter`.
- **Refresh Token Race Condition Fix**: To handle bursts of 401 errors effectively, the frontend HTTP client (`http.ts`) implements a `refreshPromise` deduplicator.

## Row-Level Security (RLS)
Beyond role-based access control (`@PreAuthorize("hasRole('EMPLOYEE')")`), data access is restricted at the row level using `CrmAccessService`. 
- **Example**: Before updating a task, the system checks if the current user has the right to access that specific task entity based on their ownership or assignments.
- **Batch Operations**: IDOR protection is applied by validating access to each item individually within batch operations.
