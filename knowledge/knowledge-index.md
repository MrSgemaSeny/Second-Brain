# Индекс Базы Знаний (Zettelkasten)

Здесь собраны архитектурные паттерны, решения и хаки, экстрагированные из всех наших проектов. Эти знания можно переиспользовать в новых проектах для экономии времени и избежания старых граблей.

## Архитектура и Системный Дизайн
- [[arch-caffeine-cache]] - Локальное кеширование (Caffeine) для одноузловых серверов.
- [[arch-realtime-chat-websocket]] - Архитектура высоконагруженных реалтайм-чатов (STOMP, Pub/Sub).
- [[arch-tg-bot-patterns]] - Паттерны проектирования Telegram-ботов (FSM, Dispatchers).
- [[arch-webhooks-vs-polling]] - Сравнение Webhooks и Long Polling для интеграций.
- [[backend_and_multi_tenancy_patterns]] - Паттерны бэкенда и архитектура Multi-Tenancy (мультитенантность).
- [[microservices_patterns]] - Архитектура микросервисов, API Gateway, межсервисная аутентификация.
- [[career_portal_and_ats_design]] - Проектирование карьерных порталов и систем ATS.
- [[warehouse_management_and_logistics_architecture]] - Архитектура систем управления складом (WMS).
- [[jvm-metaspace-tuning]] - Оптимизация памяти JVM (Metaspace, Heap) для малых инстансов (512MB RAM).
- [[arch-load-testing-hikari-cache]] - Chaos Engineering, базовое нагрузочное тестирование (заметка 1).
- [[arch-production-resilience-and-load-testing]] - Проектирование отказоустойчивых систем и детальный анализ причин падения серверов (Connection Pools, OOM, Spike-тесты).
- [[arch-api-gateway-jwt-injection]] - Инъекция JWT Claims на уровне API Gateway.
- [[backend-threadlocal-tenant-context]] - Мультитенантность через ThreadLocal (TenantContext).
- [[ats-kanban-sla-state-machine]] - Интерактивный Kanban найма с контролем SLA и конечным автоматом.
- [[ats-funnel-analytics-and-talent-pool]] - Сквозная воронка найма (Time-to-Hire, конверсия стадий) и база талантов (Talent Pool CRM).
- [[antigravity_hooks]] - Архитектура .agents Lifecycle Hooks (PreInvocation, Safety Gate, Enforce Workflow, Stop Check).
- [[antigravity-hooks-and-guardrails-evolution]] - История и эволюция хуков (архив reminder.ps1, git-reminder.ps1 и переход к hard guardrails).
- [[agent-token-efficiency-and-vertical-troubleshooting]] - Анализ эффективности токенов: вертикальный целевой срез (Vertical Slice), PowerShell-операторы и Scoped Prompting.
- [[observability-tracing-mdc-and-structured-logging]] - Observability First: Сквозной трейсинг (OpenTelemetry + Micrometer Tracing), Correlation ID (X-Request-ID), MDC и структурированное JSON-логирование (Logstash / Grafana Loki).

## Фронтенд (React, FSD, UI Deslop)
- [[arch-fsd-react]] - Базовое применение Feature-Sliced Design.
- [[frontend-architecture-fsd-dnd]] - FSD архитектура в связке с Drag-and-Drop (dnd-kit) и Zustand.
- [[frontend_fsd_and_ui_ux_patterns]] - UI/UX паттерны и продвинутое использование FSD.
- [[zustand-persist-access-token]] - Решение проблемы с logout при рефреше в Zustand persist.
- [[frontend-native-fetch-interceptor]] - Нативный Fetch с перехватом 401 (Refresh Token).
- [[arch-contextual-quick-nav-drawer]] - Контекстная навигация (Quick-Nav Drawer) без размонтирования плеера.
- [[ai-deslop-strategy-tokens-audit]] - Стратегия → Токены (DESIGN.md) → Аудит. 4 уровня шрифтов, функциональный layout.
- [[ai-deslop-tools-and-skills]] - Инструменты и скиллы для борьбы с шаблонным AI-кодом и дефолтным UI-дизайном (Deslop).
- [[b2c-lms-course-discovery-and-video-preview]] - B2C витрина курсов, Hover-трейлеры и анатомия двухколоночного лендинга.
- [[frontend-distinctive-design-and-anti-slop]] - Отличительный дизайн интерфейсов: борьба со стереотипами AI-генерации (Claude palette, SaaS card kit, типографический шум).

## Бэкенд и Базы Данных
- [[db-trigger-audit-logs]] - Реализация неизменяемых Audit-логов через триггеры PostgreSQL.
- [[arch-transactional-outbox-event-automation]] - Transactional Outbox Pattern в монолите без внешних брокеров.
- [[pdf-generation-thymeleaf-flying-saucer]] - Генерация PDF (Thymeleaf + Flying Saucer).
- [[hack-thymeleaf-pdf]] - Альтернативный стек генерации (Thymeleaf + OpenHTMLtoPDF) с поддержкой кириллицы.
- [[arch-pdf-openhtmltopdf-thymeleaf]] - Векторная генерация PDF через Thymeleaf и OpenHTMLtoPDF с регистрацией шрифтов.
- [[hack-websockets-stomp]] - Практические хаки для стабильной работы WebSockets.
- [[pdf-flying-saucer-constraints]] - Строгие правила и ограничения для Flying Saucer (шрифты, CSS, page-break).
- [[arch-hibernate-pitfalls]] - Опасности Hibernate (N+1 с MapStruct, orphanRemoval конфликты).
- [[backend-rate-limiting-bucket4j]] - In-Memory Rate Limiting с Bucket4j.
- [[arch-tiered-rate-limiting-bucket4j]] - Tiered Rate Limiting с Bucket4j и Caffeine (Auth, AI, General).
- [[arch-quiz-assessment-engine-anti-cheat]] - Движок интерактивных квизов, раздельные DTO и защита от списывания.

## Интеграции и AI
- [[api-github-integration]] - Интеграция с GitHub API (парсинг, рейтрейт, кеширование Redis).
- [[arch-ai-chat-integrations]] - Интеграция LLM в чаты (асинхронные воркеры, streaming, RAG).
- [[arch-ai-smart-merge]] - Паттерн умного слияния данных из нескольких источников (API + PDF) через LLM.
- [[arch-ai-structured-generation]] - Использование LLM для генерации строгих JSON DTO (json_object, Graceful Degradation).
- [[arch-ai-tutor-lesson-grounding]] - AI-наставник с заземлением в контекст урока (Lesson Grounding) и защитой от инъекций.
- [[arch-hybrid-rag-dense-sparse-rrf]] - Гибридный RAG-поиск: pgvector HNSW (Dense) + tsvector (Sparse FTS) через Reciprocal Rank Fusion.
- [[arch-ai-code-grader-and-security-scanner]] - Автоматический AI-грейдер кода со статическим AST-сканером безопасности.
- [[arch-rag-indexing-vs-retrieval]] - RAG архитектура: разница между Indexing Pipeline (запись) и Retrieval (поиск).
- [[resume-pdf-parsing]] - Парсинг PDF-резюме (Apache Tika/PDFBox) и работа с неточными данными.
- [[llm-json-mode-prompts]] - Правила промптинга при работе с json_object режимом в LLM (Groq/OpenAI).
- [[arch-groq-models-policy]] - Политика выбора LLM-моделей Groq (GPT-20B как единственный рабочий стандарт, запрет Llama).
- [[ats-ai-resume-scoring-groq]] - AI-скоринг резюме и Smart Match на базе LLM (Groq).
- [[pedagogy-and-automation-split-for-vibe-coding]] - Педагогика вайбкодинга: трансформация идентичности, дофаминовый win на Уроке 1, Error-Loop и разделение зон LMS / Ментор.

## Безопасность и Авторизация
- [[sec-spring-jwt-auth]] - Настройка Spring Security (JWT, Refresh токени, дедупликация).
- [[security-idor-rls]] - Защита от IDOR (Insecure Direct Object Reference) и Row-Level Security в БД.
- [[sec-docker-redis-exposure]] - Защита внутренних сервисов Docker от публичного доступа.
- [[sec-pii-llm-compliance]] - Юридическая безопасность, PII анонимизация и LLM ToS (Groq, OpenAI).
- [[sec-prompt-injection-xml]] - Защита от Prompt Injection с помощью XML тегов в LLM.
- [[sec-file-upload-magic-bytes]] - Безопасная валидация загружаемых файлов (Magic Bytes).
- [[sec-oauth2-stateless-cookies]] - Реализация OAuth2 в STATELESS архитектуре без сессий.
- [[sec-mvp-to-prod-checklist]] - Переход от MVP к Production: Чек-лист безопасности и типичные компромиссы.
- [[sec-internal-service-token]] - Защита межсервисного взаимодействия (X-Internal-Token).

## Управление памятью, токенами и контекстом LLM (Letta / MemGPT / StreamingLLM)
- [[llm-memory-and-context-optimization]] - Трёхуровневая модель виртуальной памяти агента (L1 Working Memory, L2 Archival, L3 Telemetry), Attention Sinks (StreamingLLM) и адаптивная компрессия токенов.

## Инциденты (Production Post-Mortems)
- [[incident-01-flyway-github-actions-desync]] - Расхождение Flyway-миграций между локальной и prod БД через GitHub Actions.
- [[incident-02-management-port-hibernate-crash]] - `management.server.port=8081` на Fly.io → Spring создаёт 2-й контекст → Hibernate 7 дублирует event listeners → crash. Фикс: держать порт на 8080, безопасность через Spring Security.

