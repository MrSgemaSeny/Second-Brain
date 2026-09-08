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

2. **Комплексное E2E и нагрузочное тестирование боевого сервера (Playwright + Artillery)**:
   - **Artillery Load Testing (Каталог и публичный API `https://zhanfinance.fly.dev`)**:
     - 1114 запросов за 56 секунд (~36 RPS).
     - 669 успешных ответов HTTP 200, 443 ответа HTTP 429 (срабатывание Bucket4j защиты при превышении лимита 100 req/min).
     - 0 ошибок 5xx (полная стабильность Spring Boot под конкурентной нагрузкой).
     - Задержки: медиана 125.2 ms, P95 = 368.8 ms, P99 = 415.8 ms.
   - **Artillery Stress Testing (Rate Limiting Boundary Check)**:
     - 30 запросов залпом за 5 секунд на эндпоинт `/api/v1/auth/check-email`.
     - Лимитер отработал точно по спецификации: 10 запросов пропущены (HTTP 200), 20 запросов отсечены со статусом HTTP 429 за 104 ms (без утечек соединений и нагрузки на базу).
   - **Artillery Frontend CDN (GitHub Pages `https://mrsgemaseny.github.io/JF-1C/`)**:
     - 950 запросов за 36 секунд (~32 RPS).
     - Медианная задержка отдачи статики и SPA: 70.1 ms.
   - **Playwright Browser E2E (`tests/e2e/frontend-live.mjs`)**:
     - 16 тестов в реальном браузере Chromium/Chrome на живом сайте.
     - Успешно проверены: заголовок и метатеги, баннер CookieConsent (запись в `localStorage`), переключение тем и языков (RU/KZ/EN), страницы `/services`, `/about`, юридический блок (Privacy, Terms, Refund, Cookie), формы входа, сброса пароля и регистрации.
   - **Live Backend API E2E (`tests/e2e/api-live.mjs`, 34 эндпоинта)**:
     - Проверены Actuator Health (`UP`), каталог услуг, заголовки безопасности (HSTS, CSP, nosniff, frame-options), проверка email, создание заявок (`/api/v1/contact-requests`), fail-closed изоляция 22 защищенных маршрутов (строго 401/403).
     - Устранен недочет в `GlobalExceptionHandler.java`: добавлен обработчик `HttpRequestMethodNotSupportedException` (возвращает статус 405 Method Not Allowed вместо падения в 500 при неподдерживаемых HTTP-методах).
   - Все 191 тест бэкенда (`./gradlew.bat test`) успешно пройдены.

3. **Углубление архитектурных паттернов и тестов (Caffeine TTL Expiry & Bucket4j Spoofing)**:
   - **`knowledge/arch-caffeine-cache.md`**:
     - Разобрана природа Stale Data: различие между явным `@CacheEvict` (мутации) и истечением срока жизни ключа (TTL Expiry).
     - Документирована механика ленивой очистки (Lazy Maintenance) Caffeine: отсутствие фоновых потоков на каждый ключ, очистка при вызовах `get`/`put` и через амортизированный `ForkJoinPool.commonPool()`.
     - Зафиксирован шаблон детерминированного тестирования TTL без `Thread.sleep`: внедрение `Ticker` (`FakeTicker`), метод `cache.cleanUp()`, проверка протухания записи и реального повторного похода в БД (`verify(repository, times(2))`).
   - **`knowledge/arch-tiered-rate-limiting-bucket4j.md`**:
     - Сравнение алгоритмов: Fixed Window Counter (дефект Boundary Burst со всплеском 2x на стыке минут), Sliding Window Log/Counter и Token Bucket (Bucket4j, burst allowance и плавное пополнение `refillIntervally` vs `refillGreedy`).
     - Векторы атак: `X-Forwarded-For` spoofing и эксплуатация `CF-Connecting-IP` до подключения Cloudflare. Описана архитектура безопасного извлечения IP (Rightmost Untrusted IP) с доверием заголовкам только от верифицированных прокси (`getRemoteAddr()`).
     - Тестовые сценарии: тест на исчерпание лимита, тест на попытку обхода через поддельные заголовки IP и тест на пропуск CORS `OPTIONS` pre-flight без расходования токенов.
   - **`knowledge/qa-testing-classification-and-strategies.md`**:
     - Разделы 3.3 (Rate Limit Testing) и 5.2 (Cache Invalidation & TTL Expiry) обновлены с учетом этих архитектурных нюансов.

