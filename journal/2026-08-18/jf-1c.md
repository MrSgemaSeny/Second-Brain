# ������ 2026-08-18

## ��� ���� �������
1. ���������� ����������: Path Traversal (DatabaseStorageService), IP Spoofing (DocumentController), IDOR (CourseMediaController), DoS (ContactRequestService), Token Race Condition (RefreshTokenService), CSV Injection (ExportController).
2. ��� ������� � ����������� (������ de7c86f).
3. ������������� ������� ����� (enforce-workflow, reminder) �� ������� Valeur.

## �������������� ����� (Phase 2)
1. CRIT-3: ������ JWT ����� �� URL ���������� � JwtAuthenticationFilter.
2. WARN-2: ��������� Content-Disposition ������ ������������ ��������� ����� Spring ContentDisposition builder.
3. CRIT-1: �������� ������� Rate Limit (10 �������� � ��� �� IP) ��� �������� ������ � ApiRateLimitFilter.
4. WARN-1: Actuator ��������� �� ���� 8081 � application.properties, ����� ������ ������� �� ���������� �������.
5. CRIT-2: ��������� ��������� MIME-���� ����� Apache Tika (tika-core) ������ ������� ����������� ��������� Content-Type.

## �������� ���������
- ������������, ��� �������� ��� ���������� ���� /api/v1/*. ���� 4 �������� ��� [DONE] � AGENTS.md.

## [HOTFIX] Incident: Backend crash after security audit commit

### Root cause
Commit ddceb67 (security audit Phase 2) changed management.server.port from 8080 to 8081.
On Fly.io, port 8081 is not exposed. Spring Boot creates a second WebApplicationContext for the management port.
Hibernate 7 (Spring Boot 4.x) registers entity event listeners per ApplicationContext -- with two contexts, listeners are registered twice.
Result: EventListenerRegistrationException: Duplicate event listener found -- Application run failed.

Symptoms seen by user:
- CORS blocked on /api/v1/auth/me (backend was down, no CORS headers on 502)
- Grafana alert: DatasourceNoData (metaspace-near-limit -- no data because backend was down)
- 502 Bad Gateway on all endpoints

### Fix
Hotfix commit 28a48fe: reverted management.server.port to 8080.
Actuator is already secured via hasRole("ADMIN") in SecurityConfig -- separate port on Fly.io was security theater (8081 not in fly.toml, never exposed).

### Lesson learned
See [[knowledge/jvm-metaspace-tuning]] -- Fly.io overrides JAVA_TOOL_OPTIONS.
Real MaxMetaspaceSize on Fly.io free tier = 160m (not 256m from fly.toml).
Never set management.server.port != server.port on single-port Fly.io deployments with Hibernate 7.

### Tests
BUILD SUCCESSFUL -- all security filter tests passed.
