# Warehouse Management & Logistics Architecture

Based on the architectural specifications from the "Sklad" (Warehouse) project.

## 1. Key Business Domains
- **Inbound Logistics:** Managing incoming shipments, cross-docking, and bin allocation.
- **Inventory Management:** Serial number tracking, batch management (FIFO/LIFO/FEFO), expiration date control.
- **Outbound Logistics:** Wave picking, picker routing, packaging, generating shipping manifests.
- **Topology:** Modeling warehouses down to the level of zones, aisles, racks, tiers, and bins (2D/3D).

## 2. Microservice Landscape & Domain-Driven Design (DDD)
The system is divided into Bounded Contexts, each with its own isolated database:
- **Identity Service:** Authentication (OAuth2/OIDC), tenant and role management (Keycloak + Spring Boot).
- **Inventory Service:** The core of operations. Designed for ultra-high load (Spring WebFlux, R2DBC, PostgreSQL).
- **Topology Service:** Manages physical layouts and routing. Uses a Graph Database (Neo4j) for optimizing picker paths.
- **Gateway & BFF:** Spring Cloud Gateway acting as the single entry point (GraphQL aggregation).

## 3. Event-Driven Architecture (EDA)
- **Saga Pattern (Choreography):** Used for distributed transactions. E.g., `OrderService` emits `OrderCreated`. `InventoryService` listens, reserves stock (soft allocation), and emits `InventoryReserved`. `OrderService` then confirms the order.
- **Event Sourcing & CQRS:** Implemented for critical services like Inventory. The database stores an append-only log of all movements rather than just the current state. The current stock is calculated as a projection, ensuring 100% auditability without systemic stock loss.

## 4. LLM and AI Integration
- **Text-to-SQL (Database Chat):** Users can query stock via natural language. Generated SQL is parsed strictly (preventing DROP/UPDATE/INSERT) and executed under a Read-Only role constrained to the specific tenant's schema.
- **Vision API for Receiving:** Workers photograph supplier invoices. Vision LLMs extract tabular data, and vector search (FAISS) maps fuzzy invoice descriptions to standard master data.
