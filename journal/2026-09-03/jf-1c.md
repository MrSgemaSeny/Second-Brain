# Журнал разработки JF-1C (ZhanFinance) — 2026-09-03

## 1. Задачи и прогресс

### 1.1. Активация GitHub Pages и исправление CI/CD Deployment (404 Not Found)

- **Проблема**:
  - При выполнении шага ctions/deploy-pages@v4 пайплайн ci.yml падал с ошибкой:
    Error: Failed to create deployment (status: 404) with build version 027bbc393a0d39156cbecdcb1645cb7d59fea204. Ensure GitHub Pages has been enabled: https://github.com/MrSgemaSeny/JF-1C/settings/pages.
  - Причина: в настройках репозитория GitHub Pages не был активирован для источника GitHub Actions (uild_type: workflow).
- **Решение**:
  - Активирован GitHub Pages через GitHub REST API: POST /repos/MrSgemaSeny/JF-1C/pages с параметром uild_type: workflow.
  - Перезапущен упавший ран 33631801416 (gh run rerun 33631801416).
  - Успешно собран артефакт github-pages и выполнен деплой за 11 секунд.
  - Сайт опубликован и доступен по адресу: https://mrsgemaseny.github.io/JF-1C/.
- **Контекст и синхронизация**:
  - Обновлен .agents/CONTEXT.md в JF-1C.
  - Выполнен коммит и пуш в main.

### 1.2. Исправление ошибки 409 "Конфликт данных" при регистрации
- **Проблема**: При попытке регистрации с уже существующим email (если он не привязан к Google) фронтенд ошибочно пускал пользователя на второй шаг, а бэкенд возвращал ConflictException (EMAIL_ALREADY_REGISTERED), который GlobalExceptionHandler маскировал под универсальную ошибку "error.conflict" ("Конфликт данных").
- **Решение**:
  - В zhan-finance-frontend/src/pages/auth/register/RegisterPage.tsx добавлена проверка es.exists для локальных аккаунтов. Теперь форма блокируется и показывает локализованную ошибку.
  - В zhan-finance-backend/.../GlobalExceptionHandler.java исправлена логика обработки ConflictException. Теперь ошибка EMAIL_ALREADY_REGISTERED корректно транслируется.
- **Статус**: Исправления закоммичены.

### 1.3. Оптимизация сборки Docker (уменьшение build context)
- **Проблема**: Контекст сборки на Fly.io весил 146 MB, что сильно замедляло каждый деплой.
- **Решение**: Добавлен файл zhan-finance-backend/.dockerignore, исключающий папки uild/, .gradle/, .git/ и временные файлы. Контекст сокращен до ~2 MB.
- **Статус**: Изменения закоммичены и отправлены в main.
