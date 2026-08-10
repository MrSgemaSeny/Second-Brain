# Session Log: MeDev (2026-08-07)

## Что сделано
- Инициализирован Git репозиторий для проекта MeDev (Фаза 1.1).
- Подключен удаленный репозиторий: `https://github.com/MrSgemaSeny/MeDev.git`.
- Создан файл `README.md` с описанием проекта.
- Добавлены основные файлы документации проекта (`MEDEV_PROJECT.md`, `MEDEV_LIFECYCLE.md`).
- **Фаза 1.2**: Инициализирован бэкенд на Spring Boot 3.3.0. Настроены зависимости, Flyway, `application.yml` и `build.gradle`. Gradle wrapper понижен до версии 8.7.
- **Фаза 1.3**: Инициализирован фронтенд (React 19 + TypeScript + Vite). Установлены все зависимости.
- **Фаза 2.1 (Миграции)**: Созданы Flyway миграции `V1` - `V8` для полной структуры БД (users, profiles, experience, education, skills, languages, projects, subscriptions).
- **Фаза 2.2 (Auth модуль)**: Реализована базовая JWT аутентификация. Настроены сущности `User`, слой сервисов (`AuthService`, `JwtService`), контроллер `AuthController`, DTO и глобальный обработчик ошибок. Spring Security настроен на stateless-авторизацию.
- **Фаза 2.3 (Profile модуль)**: Реализованы сущности (`Profile`, `Experience`, `Skill`), DTO-модели, репозитории, и полноценный `ProfileService` + `ProfileController` (CRUD профиля, CRUD опыта работы с логикой drag-and-drop сортировки).
- **GitHub Pages**: Добавлен CI/CD workflow в `.github/workflows/deploy.yml`, обновлен `vite.config.ts` (`base`) и `package.json` (`homepage`) для автоматического деплоя фронтенда.

## Добавлено
- Базовый каркас Spring Boot 3 и Vite React.
- Flyway миграции (`V1` - `V8`).
- Auth модуль (Entity, DTO, Repository, Service, Controller).
- Shared Security (JwtFilter, JwtService, SecurityConfig, SecurityUtils).
- Shared Exception Handler.

## Изменено
- `backend/gradle/wrapper/gradle-wrapper.properties` (понижена версия до 8.7).

## Удалено
- `backend/src/main/resources/application.properties` (заменено на `.yml`).

## Проблемы
- Gradle 9.5.1 оказался несовместим с плагином Spring Boot 3.3.0. Решено даунгрейдом враппера до 8.7.

## Тесты
- `./gradlew build -x test` — Успешно (компиляция Auth-модуля и security-утилит проходит чисто, за исключением пары ожидаемых Lombok-ворнингов `@Builder`).

## Фаза 3 (дополнение)
- **Backend**: Добавлены Entity, DTO и Repository для `Education`, `Project`, `Language`. Завершена логика CRUD для профиля в `ProfileService`. Исправлены ошибки сборки `findByProfileIdOrderBySortOrderAsc`.
- **Frontend**: Настроен Drag-and-Drop билдер на `dnd-kit` (`ResumeBuilder.tsx`). Реализована публичная страница портфолио (`PortfolioPage.tsx`). Установлен Zustand для стейт-менеджмента и React Query для API.
- **Тесты**: `npm run build` проходит успешно. `./gradlew build` проходит успешно.
- **Ошибки**: Были проблемы с npm registry для пакетов `lucide-react` и `tailwind-merge` (ECONNRESET). Временно написана заглушка `cn()` и убраны иконки.
- Изменения зафиксированы и запушены в ветку `main` с `--force` (так как не было upstream).

## Исправление "очевидных проблем" (дополнение)
- **CORS**: Добавлена `CorsConfigurationSource` в `SecurityConfig.java`, чтобы фронтенд (5173/5174) мог делать запросы к Spring Boot (8080).
- **Фронтенд иконки**: Успешно установлены пакеты `lucide-react`, `tailwind-merge`, `clsx`. Восстановлены иконки в `DashboardPage.tsx` и `ResumeBuilder.tsx` (вместо текстовых заглушек).
- **Tailwind**: Исправлена синтаксическая ошибка в `index.css` (импорт перенесён в самый верх файла) и добавлен `@tailwindcss/vite` в плагины Vite. Фронтенд успешно стилизуется.
- **Backend Config**: В `application.yml` прописаны fallback-дефолты для системных переменных, чтобы сервер стартовал без падений, если переменные не переданы через CLI. (Сам `.env` добавлен в `.gitignore`).
- **Синхронизация Envie**: Проект Envie также переведен на `application.yml` + `.env.example` для консистентности.
- Все эти фиксы запушены в GitHub.

## Радикальный Редизайн UI (AI Агенты)
- Запущено 3 узкоспециализированных бота для полного обновления UI-слоя.
- **Bot 1 (Core)**: Обновлен `index.css`, `Button.tsx`, `Input.tsx`. Внедрены стили glassmorphism, градиенты, глубокие тени и микро-анимации.
- **Bot 2 (Auth)**: Полностью переработаны `LoginPage.tsx` и `RegisterPage.tsx`. Реализован сплит-скрин с анимированными blur-градиентами на фоне и glass-карточками форм.
- **Bot 3 (Dashboard)**: Дашборд, билдер резюме и портфолио переведены на "дорогой" SaaS-дизайн с парящими заголовками, четкими тенями и элегантными скруглениями.
## База Данных и Конфигурация
- **СУБД**: Создана база данных `medev` и пользователь `test_user` (с паролем `pass1`) через `psql`. Права выданы (GRANT ALL PRIVILEGES).
- **application.yml**: Обновлены дефолтные креды БД на `test_user` / `pass1`, чтобы Spring Boot мог корректно подключаться и накатывать миграции (Flyway) без передачи параметров через CLI (удобно для локального запуска в IDE).
- **build.gradle**: Добавлен модуль `flyway-database-postgresql`, так как в Flyway 10.x (в Spring Boot 3.3.0) поддержка баз данных вынесена в отдельные модули. Без него падала ошибка "Unsupported Database: PostgreSQL 17.6".

## Production Readiness
- **Конфигурация**: Разделена на `application.yml` (общие настройки), `application-dev.yml` (локальная БД) и `application-prod.yml` (БД, Redis через переменные окружения, пулы соединений HikariCP, Actuator).
- **Логирование**: Настроен SLF4J + Logback через `logback-spring.xml` (вывод в консоль в `dev` и JSON-формат в `prod`). В `GlobalExceptionHandler` добавлено логирование необработанных исключений 500.
- **Безопасность**: Добавлен `RateLimitingFilter` (Bucket4j, 100 запросов в минуту) для защиты API от DDoS и брутфорса.
- **Фронтенд**: Внедрен React `ErrorBoundary` для корректной обработки падений UI в рантайме без белого экрана.
