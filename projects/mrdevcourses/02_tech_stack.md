# 2. Технологический стек MrDevCourses

### 2.1 Backend
- **Java 17 + Spring Boot 3.3.0** — модульный монолит.
- **Spring Security 6 + OAuth2 Client** — Google OAuth2, stateless JWT в `httpOnly` cookie (`mrdevcourses_token`).
- **PostgreSQL + Flyway (V1..V5)** — строгий версионированный контроль схемы.
- **Чистый SQL/Service Drip logic** — расчет `(NOW() - enrolled_at) >= ((day_number - 1) * INTERVAL '1 day')` без лишних cron/фоновых джобов.

### 2.2 Frontend
- **React 19 + TypeScript + Vite**
- **Feature-Sliced Design (FSD)**
- **Tailwind CSS v4** — GitHub dark aesthetic (`#0d1117`, `#161b22`, `#30363d`).
- **TanStack React Query v5** — серверный стейт и кэширование.
- **Vitest + React Testing Library** — компонентные тесты.

### 2.3 Сознательные архитектурные исключения для MVP
- Нет Redis (stateless сессия в httpOnly cookie, нет тяжелого кэша).
- Нет платежек на старте (бесплатные курсы и ручной аппрув).
- Нет YouTube API парсеров (клиентский iframe embed).
