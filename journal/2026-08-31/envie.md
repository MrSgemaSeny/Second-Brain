# Envie — 31.08.2026

## Что изменено / добавлено / исправлено

### 1. Архитектурный рефакторинг README.md в Senior-инженерном стиле
- **Сравнение с JF-1C**: Применён строгий enterprise/senior формат документации по образцу `JF-1C/README.md`.
- **Структура и разделы**:
  - Полный архитектурный манифест проекта: «Без облаков. Без чужой авторизации. Без лишнего шума».
  - Раздел документации со ссылками на архитектурные спецификации (`ENVIE_ARCHITECTURE_AND_LOGIC.md`, `EMIL_DESIGN_SKILL.md`, `ENVIE_DESIGN.md`).
  - Детализированный стек Backend (Spring Boot 3, Java 17, Flyway, PostgreSQL, RFC 7807, Media Storage Engine) и Frontend (React, FSD 2.1, Tailwind v4, Geist typography, Canvas 2D / Three.js, TanStack Query v5, Emil Kowalski motion rules).
  - Подробный обзор всех 8 ключевых модулей (Landing, Dashboard 3D, Notes, Board, Ideas, Templates, Wallpaper, For You).
  - Схема проекта с актуальной структурой директорий FSD и модулей бэкенда.
  - Цепочка миграций Flyway (V1–V7) с описанием неизменяемости.
  - **Границы Продукта и Архитектурный Скоуп (Product Scope & Intentional Boundaries)**: Чёткая фиксация In-Scope (Zero-latency flow, суверенитет данных, строгая персистентность, универсальная 2D/3D графика без сбоев) и Out-of-Scope (отказ от многопользовательского RBAC, внешней телеметрии, SaaS-лока и AI-оверинжиниринга на CRUD-путях).
  - **Варианты Развёртывания в Production**: Добавлены сценарии Homelab/Docker, персонального Cloud VPS и гибридного деплоя (GitHub Pages + Backend).
  - Инструкция по быстрому запуску (Docker, Gradle, Vite) с актуальными портами и тестами.
  - Свод инженерных стандартов (Zero Any, Motion Guardrails, Zero Emojis, Second Brain Protocol).

## Проверка и статус
- `npm run build` — успешно (0 ошибок).
- `./gradlew check -x test` — успешно (`BUILD SUCCESSFUL in 12s`).
- Git: закоммичено и отправлено в `origin/master`.
