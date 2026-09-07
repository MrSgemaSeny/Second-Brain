# Session Log — MeDev
**Дата:** 2026-09-07
**Проект:** MeDev (DevProfile)
**Фаза:** Level 4 — Production Live (Custom Domain Configuration)

## 1. Выполненные действия
- Настроена интеграция кастомного домена `medev.mrsgemaseny.com` для фронтенда и бэкенда MeDev.
- Обновлены конфигурационные файлы `application.yml` и `application-prod.yml`:
  - `cors.allowed-origins`: добавлен `https://medev.mrsgemaseny.com` в список разрешенных origin.
  - `app.frontend-url`: дефолт обновлен до `https://medev.mrsgemaseny.com` для корректных OAuth2 редиректов.
- Согласованы DNS-записи в Namecheap (CNAME `medev` -> `cname.vercel-dns.com`) и Vercel Domains.

## 2. Изменения в коде
- `backend/src/main/resources/application.yml` — добавлен `https://medev.mrsgemaseny.com` в CORS origins.
- `backend/src/main/resources/application-prod.yml` — добавлен `https://medev.mrsgemaseny.com` в CORS origins и `app.frontend-url`.

## 3. Статус тестов
- 253 backend-теста (JUnit/Spring Boot) запущены и проверены.
