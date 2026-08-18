# Incident-02: management.server.port=8081 crashed backend on Fly.io

**Date:** 2026-08-18
**Project:** JF-1C (ZhanFinance)
**Severity:** CRITICAL (full backend outage, ~10 min)
**Commit that broke:** ddceb67
**Hotfix commit:** 28a48fe

---

## Symptoms (what was seen)

- CORS blocked: `No Access-Control-Allow-Origin header` on `/api/v1/auth/me`
- 502 Bad Gateway on all endpoints
- Grafana alert: `DatasourceNoData` on `metaspace-near-limit` rule (backend unreachable, not actually Metaspace)
- Frontend: blank screen, infinite loading for all authenticated users

## Root Cause

One line changed in `application.properties` as part of a security audit:

```diff
-management.server.port=${MANAGEMENT_SERVER_PORT:8080}
+management.server.port=${MANAGEMENT_SERVER_PORT:8081}
```

## Failure Mechanism

```
management.server.port != server.port
        |
        v
Spring Boot creates a SECOND WebApplicationContext for management
        |
        v
Hibernate 7 (Spring Boot 4.x) registers entity event listeners PER context
        |
        v
EventListenerRegistrationException: Duplicate event listener found
        |
        v
Application run failed --> Fly.io restarts machine --> same crash loop
```

## Why CORS looked like the cause (misdirection)

When backend is down, Fly.io proxy returns 502 with no body and no CORS headers.
Browser interprets missing `Access-Control-Allow-Origin` as a CORS violation.
The real error was one level below -- the backend never started.

## Why the security goal was wrong for Fly.io

The intent was to isolate Actuator on a port unreachable from outside.
But on Fly.io:
- Only `internal_port = 8080` is in `fly.toml` -- port 8081 is never exposed anyway
- Actuator was already protected by `hasRole("ADMIN")` in `SecurityConfig`
- The separate port added zero security but broke the app

## Fix

Revert to same port:
```properties
management.server.port=${MANAGEMENT_SERVER_PORT:8080}
```

Actuator security is handled by Spring Security, not by port isolation.

## Rule for Fly.io + Spring Boot 4.x + Hibernate 7

**NEVER set `management.server.port` to a different value than `server.port`
unless that port is explicitly declared in `fly.toml` as a second `[services]` entry.**

If you need Actuator isolation on Fly.io: use `management.endpoint.health.show-details=when-authorized`
and `hasRole("ADMIN")` -- both already in place in JF-1C.

## Diagnostic commands used

```powershell
# Check if backend is alive
Invoke-RestMethod -Uri "https://zhanfinance.fly.dev/api/v1/actuator/health"
# --> 502 = backend down

# Check Fly.io machine state
flyctl status --app zhanfinance
# --> state: started (misleading -- machine running but app inside crashed)

# Read real crash logs
flyctl logs --app zhanfinance --no-tail
# --> EventListenerRegistrationException: Duplicate event listener found
# --> Caused by: java.net.ConnectException: HTTP connect timed out (OTLP at startup)
```

## Related

- [[jvm-metaspace-tuning]] -- Fly.io overrides JAVA_TOOL_OPTIONS: real MaxMetaspaceSize=160m not 256m
- [[incident-01-flyway-github-actions-desync]] -- previous production incident
- [[arch-hibernate-pitfalls]] -- Hibernate 7 behavioral changes vs Hibernate 6
