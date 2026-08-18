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
- [[warehouse_management_and_logistics_architecture]] - Архитектура логистики и управления складом.
- [[jvm-metaspace-tuning]] - Правильная настройка JVM (Metaspace, Heap) для маленьких серверов (512MB RAM).
- [[arch-api-gateway-jwt-injection]] - Инъекция JWT Claims на уровне API Gateway.
- [[backend-threadlocal-tenant-context]] - Мультитенантность через ThreadLocal (TenantContext).

## Фронтенд (React, FSD)
- [[arch-fsd-react]] - Базовое применение Feature-Sliced Design.
- [[frontend-architecture-fsd-dnd]] - FSD архитектура в связке с Drag-and-Drop (dnd-kit) и Zustand.
- [[frontend_fsd_and_ui_ux_patterns]] - UI/UX паттерны и продвинутое использование FSD.
- [[zustand-persist-access-token]] - Решение проблемы с logout при рефреше в Zustand persist.
- [[frontend-native-fetch-interceptor]] - Нативный Fetch с перехватом 401 (Refresh Token).

## Бэкенд и Базы Данных
- [[db-trigger-audit-logs]] - Реализация неизменяемых Audit-логов через триггеры PostgreSQL.
- [[pdf-generation-thymeleaf-flying-saucer]] - Генерация PDF (Thymeleaf + Flying Saucer).
- [[hack-thymeleaf-pdf]] - Альтернативный стек генерации (Thymeleaf + OpenHTMLtoPDF) с поддержкой кириллицы.
- [[hack-websockets-stomp]] - Практические хаки для стабильной работы WebSockets.
- [[pdf-flying-saucer-constraints]] - Строгие правила и ограничения для Flying Saucer (шрифты, CSS, page-break).
- [[arch-hibernate-pitfalls]] - Опасности Hibernate (N+1 с MapStruct, orphanRemoval конфликты).
- [[backend-rate-limiting-bucket4j]] - In-Memory Rate Limiting с Bucket4j.

## Интеграции и AI
- [[api-github-integration]] - Интеграция с GitHub API (парсинг, рейтрейт, кеширование Redis).
- [[arch-ai-chat-integrations]] - Интеграция LLM в чаты (асинхронные воркеры, streaming, RAG).
- [[arch-ai-smart-merge]] - Паттерн умного слияния данных из нескольких источников (API + PDF) через LLM.
- [[arch-ai-structured-generation]] - Использование LLM для генерации строгих JSON DTO (json_object, Graceful Degradation).
- [[resume-pdf-parsing]] - Парсинг PDF-резюме (Apache Tika/PDFBox) и работа с неточными данными.
- [[llm-json-mode-prompts]] - Правила промптинга при работе с json_object режимом в LLM (Groq/OpenAI).

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

## Инциденты (Production Post-Mortems)
- [[incident-01-flyway-github-actions-desync]] - Расхождение Flyway-миграций между локальной и prod БД через GitHub Actions.
- [[incident-02-management-port-hibernate-crash]] - `management.server.port=8081` на Fly.io → Spring создаёт 2-й контекст → Hibernate 7 дублирует event listeners → crash. Фикс: держать порт на 8080, безопасность через Spring Security.

