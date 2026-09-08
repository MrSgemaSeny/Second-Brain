# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-08

## Выполненные задачи:
1. **Систематизация и сохранение таксономии тестирования в Базе Знаний (Second Brain)**:
   - Создана фундаментальная архитектурная заметка `knowledge/qa-testing-classification-and-strategies.md` с детальным разбором всех уровней и типов тестирования ПО:
     - **Функциональные**: Unit (JUnit/Mockito, Vitest), Integration (@SpringBootTest, Testcontainers, Spring Context), E2E (Playwright, Cypress, RestAssured), Contract (OpenAPI Spec Validator, Pact).
     - **Нагрузочные**: Smoke (базовый healthcheck), Load (пиковые RPS, SLA P95/P99), Stress (точка отказа, Graceful Degradation), Spike (резкие скачки трафика, буферы и лимитеры), Soak/Endurance (долговременная нагрузка, поиск утечек памяти и HikariCP соединений).
     - **Безопасности**: OWASP ZAP / Burp Suite (DAST-сканирование), Auth bypass (матрицы RBAC/ABAC, защита от IDOR/BOLA), Rate limit (проверка блокировки 429 и заголовков Retry-After).
     - **Регрессионные**: Snapshot (контроль контрактов и UI-рендера), Mutation (PITest/Stryker, проверка качества и убиваемости мутантов в тестах).
     - **Специфичные**: Flyway migration (валидация цепочек V1..V121 на чистой БД), Cache invalidation (Caffeine/Redis evicted state), WebSocket (STOMP subscription security, изоляция очередей).
   - Обновлен центральный каталог Zettelkasten `knowledge/knowledge-index.md` — добавлен профильный раздел «Тестирование, QA и Обеспечение Качества».
