# Инфраструктура, гибридный деплой и CI/CD (Infrastructure & DevOps)

Практика развёртывания, эксплуатации и автоматизации веб-платформ в облачных средах.

---

## 1. Развёртывание на Fly.io: JVM Tuning, fly.toml и Health Checks

### 1.1. Конфигурация `fly.toml`
```toml
app = "zhanfinance"
primary_region = "fra"

[build]
  dockerfile = "Dockerfile"

[env]
  SPRING_PROFILES_ACTIVE = "prod"
  JAVA_OPTS = "-Xmx384m -Xms256m -XX:MaxMetaspaceSize=256m -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

[[http_service.checks]]
  interval = "15s"
  timeout = "3s"
  grace_period = "30s"
  method = "GET"
  path = "/api/actuator/health"
```

### 1.2. Ключевые параметры стабильности
- `grace_period = "30s"`: Даёт Spring Boot время на инициализацию Hibernate и применение миграций Flyway до того, как оркестратор начнет убивать контейнер по таймауту проверки доступности.
- `-XX:+ExitOnOutOfMemoryError`: Гарантирует немедленный перезапуск контейнера при исчерпании памяти вместо зависания в состоянии зомби.

---

## 2. Развёртывание на Render: Docker Web Service

- Сборка на базе многоэтапного Dockerfile (Multi-stage build):
  1. `gradle:8-jdk17` для сборки JAR.
  2. `eclipse-temurin:17-jre-jammy` для финального минималистичного образа.
- Переменные окружения и секреты передаются через панель управления сервисом.
- Подключение управляемой базы данных PostgreSQL 17 и Valkey Redis 8.

---

## 3. Фронтенд: GitHub Pages vs Vercel

| Параметр | GitHub Pages | Vercel |
|---|---|---|
| **Назначение** | Публичные статические SPA, открытые платформы | Продакшен веб-сервисы с кастомными доменами, Edge Functions |
| **Маршрутизация** | `spa-github-pages` или редирект через 404.html | `vercel.json` с правилом `"rewrites": [{ "source": "/(.*)", "destination": "/" }]` |
| **Заголовки безопасности** | Ограничены | Полная настройка `headers` в `vercel.json` (CSP, HSTS, X-Frame) |
| **Сборка** | GitHub Actions Workflow (`deploy-pages`) | Автоматический Git Hook при push в main |

---

## 4. Непрерывная интеграция и доставка (GitHub Actions CI/CD)

### 4.1. Пайплайн валидации и тестирования
Перед слиянием или деплоем в обязательном порядке выполняются шаги контроля качества:
1. `gradle test --no-daemon` — выполнение всех unit и integration тестов бэкенда.
2. `npm run test -- --run` — запуск Vitest тестов фронтенда.
3. `npm run build` — проверка отсутствия ошибок типизации TypeScript и успешная компиляция бандла Vite.

### 4.2. Автоматизированный ночной бэкап базы данных (Nightly DB Backup)
```yaml
name: Nightly Database Backup

on:
  schedule:
    - cron: '0 3 * * *' # Каждый день в 03:00 UTC
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Install Flyctl
        uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Run pg_dump via Fly SSH
        run: |
          flyctl ssh console -a zhanfinance-db --command "pg_dump -U postgres -d zhanfinance -Fc" > backup_$(date +%Y%m%d).dump
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

      - name: Send Telegram Alert
        run: |
          curl -s -X POST "https://api.telegram.org/bot${{ secrets.TG_BOT_TOKEN }}/sendMessage" \
            -d chat_id="${{ secrets.TG_CHAT_ID }}" \
            -d text="Nightly DB backup completed successfully for ZhanFinance."
```
