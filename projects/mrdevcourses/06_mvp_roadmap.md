# 6. Roadmap (Фазы реализации) MrDevCourses

- [x] **Фаза 0 — Инициализация**: Монорепо, Spring Boot 3.3.0, React 19 + Vite + FSD, Flyway V1-V5, Dark theme, 100% green baseline tests.
- [x] **Фаза 1 — Auth & Rate Limiting**: Google OAuth2 + Email/Password через Spring Security 6, JWT в httpOnly cookie, SecurityUtils (Row-Level Security), 3-уровневый Bucket4j Rate Limiter.
- [x] **Фаза 2 — Курсы, Уроки и Интерактивный Контент**: Drip-логика в SQL/JPA, YouTube embed плеер, Lesson Materials (PDF, Cheatsheet, Code), Quiz Assessment Engine с подсчётом баллов и маскировкой ответов.
- [x] **Фаза 3 — Прогресс, AI Тьютор и Сертификаты**: RAG Hybrid Search (pgvector HNSW + FTS RRF), AI Code Grader & Reviewer, автоматическая генерация PDF-сертификатов (Thymeleaf + OpenHTMLtoPDF) с верификацией по коду.
- [x] **Фаза 4 — Admin Suite & Telemetry Console**: Изолированный AdminLayout, Curriculum Drag-and-Drop Tree, Student Console с ручным энроллом и переключением ролей, Telemetry & Audit Logs.
- [ ] **Фаза 5 — B2C Discovery & Course Landing Experience**: Витрина /courses с фильтр-баром и hover-трейлерами, двухколоночный B2C-лендинг /courses/:slug с аккордеоном модулей, Sticky Card записи, блоками навыков и FAQ.
- [ ] **Фаза 6 — Деплой и финальная полировка**: Fly.io, Vercel/GitHub Pages, CI/CD GitHub Actions.
