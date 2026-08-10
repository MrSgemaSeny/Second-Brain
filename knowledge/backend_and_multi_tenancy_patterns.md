# Backend Architecture & Multi-Tenancy Patterns

Extracted from the "Sklad" (Enterprise) and "Envie" (Solo/Local) projects.

## 1. Multi-Tenant Architecture (Schema-per-Tenant)
For enterprise SaaS requiring absolute data isolation (like "Sklad"), the **Schema-per-Tenant** paradigm in PostgreSQL is preferred over the Shared Table (`tenant_id` column) approach.
- **Benefits:** Complete physical data isolation. Facilitates immediate GDPR compliance (`DROP SCHEMA tenant_xyz CASCADE`). Eliminates IDOR (Insecure Direct Object Reference) risks entirely since the application switches the database schema context before executing any SQL.
- **Spring Boot Implementation:**
  - Utilize `AbstractRoutingDataSource`.
  - Use a `TenantInterceptor` to intercept HTTP requests, extract the `X-Tenant-ID` (from headers or JWT), validate the subscription, and set it in a `TenantContextHolder` (ThreadLocal).
  - Configure Hibernate/JPA to use `MultiTenantConnectionProvider` and `CurrentTenantIdentifierResolver`.

## 2. Infrastructure & Orchestration
- **Kubernetes (K8s):** Enterprise projects are packaged into Helm charts from day one.
- **Service Mesh:** Istio is utilized for mTLS encryption between microservices, Canary Deployments, and Circuit Breaking.
- **Ingress:** NGINX Ingress Controller.
- **GitOps (CI/CD):** Docker images built via GitHub Actions. Deployments orchestrated via ArgoCD, which watches a separate manifest repository and syncs the cluster state (Single Source of Truth).

## 3. Database & Migrations
- **Flyway:** Strict versioning of all database schema changes in `db/migration/`.
- **UUIDs:** Utilizing `uuid-ossp` extension to generate UUID v4 natively on the PostgreSQL side for primary keys, enhancing security and distribution.
- **Role-Based Restrictions:** For advanced features like AI Text-to-SQL, queries are executed under a heavily restricted Read-Only database role confined to the specific tenant schema, parsing out potentially destructive commands (DROP/UPDATE/INSERT).
