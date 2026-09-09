# Проект testCinema (INSIGHT) — Паспорт и Архитектурный профиль

## 1. Паспорт проекта
- **Название:** testCinema (INSIGHT)
- **Тип системы:** Мультимедийная стриминговая платформа с гибридными AI-рекомендациями и конвейером локализации субтитров на казахский язык.
- **Статус:** Завершенный дипломный квалификационный проект (оценка государственной комиссии «Отлично» / A+).
- **Команда:** 2 инженера (Мурат Орынбасар & Дамир).
- **Стек ядра:** Java 17, Spring Boot 3.5.6, Spring Security, Spring Data JPA, Flyway (29 миграций).
- **Стек ИИ и данных:** Python 3.10+, FastAPI, Scikit-learn (TF-IDF), Sentence-Transformers (384-dim), OpenAI Batch API, Google Gemini Flash.
- **Стек клиента:** React 18, Vite, Feature-Sliced Design (FSD), TanStack Query v5, Zustand, Chart.js 4.
- **Инфраструктура:** PostgreSQL 16, Redis 7.2 (ZSET Leaderboards), MinIO S3 Object Storage, Docker Compose (6 сервисов).

---

## 2. Ключевые архитектурные решения и ADR
- [ADR-018: Архитектура медиа-стриминга, Presigned URLs и WebVTT CORS Proxy](../../decisions/ADR-018-multimedia-streaming-cors-and-presigned-urls.md)
- [ADR-019: Гибридный рекомендательный движок и культурный бустинг (REC-AI)](../../decisions/ADR-019-hybrid-recommendations-and-cultural-boosting.md)
- [ADR-020: Конвейер локализации субтитров через LLM и алгоритм TagPreservator](../../decisions/ADR-020-llm-subtitle-localization-tag-preservation.md)

---

## 3. Статьи в базе знаний (Knowledge Base)
- [Архитектура медиа-стриминга и WebVTT CORS Proxy](../../knowledge/arch-streaming-media-and-cors-proxy.md)
- [Рекомендательные системы: TF-IDF, Коллаборативные профили и Бустинг](../../knowledge/arch-recommendation-engine-tfidf-collaborative.md)
- [Промышленный конвейер локализации субтитров через LLM](../../knowledge/arch-llm-subtitle-localization-pipeline.md)
- [Фронтенд-инженерия медиа: Кастомный плеер и RAF Scroll Restoration](../../knowledge/frontend-custom-player-and-raf-scroll.md)

---

## 4. Сводная статистика кодовой базы
- **Сущности JPA:** 19 моделей со сложными связями (`Movie`, `Genre`, `User`, `Role`, `RefreshToken`, `UserProfile`, `UserSettings`, `WatchHistory`, `Rating`, `Review`, `ReviewReaction`, `Comment`, `CommentReaction`, `Watchlist`, `MovieSubtitle`, `MovieClick`, `SearchLog`, `SubtitleEvent`, `RecommendationImpression`).
- **Миграции Flyway:** 29 последовательных DDL-скриптов (`V1` – `V29`).
- **REST API:** Более 45 документированных эндпоинтов (OpenAPI 3.0 / Swagger UI).
- **Внешние клиенты:** Kinopoisk Dev API (500 req/day), TMDB API (обогащение ID), OpenSubtitles API (20 downloads/day с Quota Backoff).

---

## 5. Главные инженерные уроки
1. **Не пропускать тяжелые медиа через Spring Boot:** Только генерация Presigned URL на стороне S3/MinIO.
2. **Токенизация перед LLM:** Все теги и разметку субтитров необходимо заменять на токены `<N>` до отправки в модель и восстанавливать после.
3. **Diversity Guard:** Любая рекомендательная система с повышающими коэффициентами (бустингом) обязана иметь жесткий лимит (например, не более 35% локального контента), иначе лента деградирует в пузырь фильтрации.
4. **RAF Scroll Restoration:** В SPA с отложенным асинхронным рендерингом стандартный браузерный скролл ломается; решение — удержание позиции через `requestAnimationFrame` до завершения рендера.
