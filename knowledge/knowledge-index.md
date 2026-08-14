# Индекс Базы Знаний (Zettelkasten)

Здесь собраны архитектурные паттерны, решения и хаки, экстрагированные из всех наших проектов. Эти знания можно переиспользовать в новых проектах для экономии времени и избежания старых граблей.

## Архитектура и Системный Дизайн
- [[arch-caffeine-cache]] - Локальное кеширование (Caffeine) для одноузловых серверов.
- [[arch-realtime-chat-websocket]] - Архитектура высоконагруженных реалтайм-чатов (STOMP, Pub/Sub).
- [[arch-tg-bot-patterns]] - Паттерны проектирования Telegram-ботов (FSM, Dispatchers).
- [[arch-webhooks-vs-polling]] - Сравнение Webhooks и Long Polling для интеграций.
- [[backend_and_multi_tenancy_patterns]] - Паттерны бэкенда и архитектура Multi-Tenancy (мультитенантность).
- [[career_portal_and_ats_design]] - Проектирование карьерных порталов и систем ATS.
- [[warehouse_management_and_logistics_architecture]] - Архитектура логистики и управления складом.
- [[jvm-metaspace-tuning]] - Правильная настройка JVM (Metaspace, Heap) для маленьких серверов (512MB RAM).

## Фронтенд (React, FSD)
- [[arch-fsd-react]] - Базовое применение Feature-Sliced Design.
- [[frontend-architecture-fsd-dnd]] - FSD архитектура в связке с Drag-and-Drop (dnd-kit) и Zustand.
- [[frontend_fsd_and_ui_ux_patterns]] - UI/UX паттерны и продвинутое использование FSD.
- [[zustand-persist-access-token]] - Решение проблемы с logout при рефреше в Zustand persist.

## Бэкенд и Базы Данных
- [[db-trigger-audit-logs]] - Реализация неизменяемых Audit-логов через триггеры PostgreSQL.
- [[pdf-generation-thymeleaf-flying-saucer]] - Генерация PDF (Thymeleaf + Flying Saucer).
- [[hack-thymeleaf-pdf]] - Альтернативный стек генерации (Thymeleaf + OpenHTMLtoPDF) с поддержкой кириллицы.
- [[hack-websockets-stomp]] - Практические хаки для стабильной работы WebSockets.
- [[pdf-flying-saucer-constraints]] - Строгие правила и ограничения для Flying Saucer (шрифты, CSS, page-break).

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
