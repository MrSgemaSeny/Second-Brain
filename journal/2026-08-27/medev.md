# Сессия: 2026-08-27 (MeDev Deployment & Architecture Sync)

## Выполненные задачи:

1. **GitHub Pages & Vercel Dual Deployment Support**:
   - Диагностирована и решена проблема с 404 для ассетов на GitHub Pages (`https://mrsgemaseny.github.io/MeDev/`):
     - В `frontend/vite.config.ts` настроена динамическая база (`base: isGitHubPages ? '/MeDev/' : '/'`) через флаги `mode === 'github'` или `process.env.GITHUB_PAGES === 'true'`.
     - В `frontend/package.json` добавлен скрипт `"build:github": "tsc -b && vite build --mode github"`.
     - В `.github/workflows/deploy.yml` заменен устаревший Fly.io API URL на актуальный `https://medev-backend.onrender.com/api/v1` и подключена сборка через `npm run build:github`.
     - Исправлен путь к `favicon.svg` в `index.html` на относительный `./favicon.svg`.
     - Исправлен fallback-редирект в `axios.ts` на `import.meta.env.BASE_URL`.

2. **L1 Caffeine Cache & Transaction Synchronization**:
   - Внедрена конфигурация L1 Caffeine-кэша (`CacheConfig.java`) для регионов `profiles` (5m, 500) и `public-profiles` (10m, 1000).
   - `@Cacheable(value = "public-profiles", key = "#username.toLowerCase()")` на `PortfolioService.getPublicProfile`.
   - Устранен race condition в `ProfileService`: публикация `ProfileUpdatedEvent` переведена на `TransactionSynchronizationManager.afterCommit()` (`publishAfterCommit()`), чтобы async-инвалидация не затирала кэш старыми данными до завершения транзакции в БД.
   - Добавлен `PublicProfileCacheEvictListener` и `PublicRateLimiter` (60 req/min) на публичном эндпоинте портфолио.

3. **HikariCP & Tomcat Fail-Fast Tuning**:
   - В `application-prod.yml` установлен `connection-timeout: 10000` (10s) и `maximum-pool-size: 10` (для безопасной работы с Render Free PostgreSQL).
   - Ограничен пул потоков Tomcat `threads.max: 25` для предотвращения перегрузки CPU.

4. **Тесты**:
   - Backend: 253/253 тестов прошли (`BUILD SUCCESSFUL`).
   - Frontend: 37/37 тестов прошли (`vitest run`).
   - Проверены обе сборки фронтенда: `npm run build` (Vercel, root path `/`) и `npm run build:github` (GitHub Pages, subpath `/MeDev/`).
