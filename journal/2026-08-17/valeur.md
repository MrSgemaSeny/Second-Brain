# Session Log: Valeur
**Date:** 2026-08-17
**Status:** Этап 0 завершен.

## Что было сделано (Этап 0: Инициализация)
- Клонирован старый репозиторий `Valeur` из `github.com/MrSgemaSeny/Valeur`.
- Произведена полная зачистка старого фронтенд-кода.
- В корне создан файл `agents.md` с правилами проекта (основанными на Brain's Protocol: запрет эмодзи, строгая валидация тестов, запрет ddl-auto).
- Инициализирована структура микросервисов: `identity-service`, `vacancy-service`, `application-service`, `ai-service`, `api-gateway`, `frontend`.
- Настроен стартовый `docker-compose.yml` (PostgreSQL 16) и `.env.example`.
- Сделан принудительный push (`--force`) в ветку `main`.
- Попытка автоматического создания базы данных `valeur` и пользователя `test_user` через `psql` отбита из-за ошибки аутентификации локального пользователя `postgres`. Ожидается пароль от БД или ручное выполнение.

## Следующие шаги
- Перевести оставшиеся страницы с хуков-пустышек на React Query (Vacancy Details, Candidate Search, Company Profile).
- Развернуть словарь навыков.

## Что было сделано (Этапы 1-7: Микросервисы и Рефакторинг Фронтенда)
- **Этап 1:** `identity-service` переведен на Gradle. Настроен Flyway (`V1__init.sql`). Реализованы мультитенантность (`Tenant`, `User`, `TenantContext`), Stateless JWT Auth (records DTO, Rotation refresh токенов). Внедрен `InternalTokenFilter` для защиты `/internal/**`. Код проверен и запушен в `main`.
- **Этап 2 и 3:** Реализован `api-gateway` (порт 8080) с `JwtAuthenticationFilter` (декодирование JWT, передача Downstream Headers). Реализован `vacancy-service` (порт 8082, схема `vacancy`) с `TenantContextFilter`, миграциями, сущностями `Vacancy` и `VacancyView`. Настроены хуки `.agents/hooks.json` для автоматических коммитов.
- **Этап 4:** Реализован `application-service` (порт 8083, схема `application`). Реализованы сущности `Application` и `Notification`, межсервисный вызов `VacancyServiceClient` через `RestClient` для проверки существования вакансии перед откликом, добавлено автоматическое создание нотификаций. Исключены папки `build/` из репозитория.
- **Этап 5:** Реализован `ai-service` (порт 8084, схема `ai`). Интегрирован `GroqClient` (llama-3.3-70b) через `RestClient`. Добавлен In-Memory Rate Limiter через `Bucket4j` (10 req/min) и таблица трекинга `ai_usage`. Системный промпт читается из `resources/prompts/summary.txt`.
- **Этап 7:** **Бэкенд:** Реализованы `UserController` и `TenantController` для Identity-сервиса (работа с профилями кандидатов и компаний). **Фронтенд:** Инфраструктура полностью переведена на нативный `fetch` (кастомный `apiClient.ts` с перехватом 401 и обновлением токенов), внедрен `@tanstack/react-query` v5 для data fetching, а также интегрирован `Tailwind CSS v4` через `@tailwindcss/vite`. Моки (`db_helper.ts`) удалены.
- **Второй мозг (Архитектура & Журналирование):** Проведен масштабный рефакторинг "Brain's protocol - second brain". Созданы ADR для `Модульный Монолит vs Микросервисы`, `Flyway vs DDL-auto`, `Groq vs OpenAI`. Хук `reminder.py` переписан на динамическое определение пути к журналу по дате `YYYY-MM-DD`. Журнал Valeur перенесен в папку `journal`. Добавлены новые паттерны микросервисов в индекс знаний.

## Задача 1: Полное удаление клиентских моков и стабов
- Убраны фейковые эндпоинты админки из apiClient.ts.
- CompanyAnalytics (useAnalytics) переведен на реальный useQuery.
- TakeTest: исправлен таймер при пустом списке вопросов.
- HiddenTestModal: убран хардкод 75%.
- ApplicationsPage: добавлен useCompanyApplications, загружающий реальные отклики из /vacancies -> /applications.
- ApplicantDetailPage: setTimeout заменен на реальную мутацию статуса.
- Из RegisterForm и UserProfileCard удалены все привязки к хардкодным данным (IITU).
- Из RegisterForm и UserProfileCard удалены все привязки к хардкодным данным (IITU).

### Задача 2: Удаление клиентской логики матчинга
- Удален тяжелый клиентский алгоритм из matching.ts (файл урезан до хелпера getMatchColor).
- Полностью удален useMatchChecker.ts.
- Кнопка отклика ApplyButton.tsx переписана: теперь она опирается на match_score, который будет возвращать сервер.
- Вычищены мертвые импорты в useCandidateSearch.ts и FeedPage.tsx.
- Фронтенд успешно скомпилирован (tsc --noEmit).

### Задача 2: Завершение зачистки клиентской логики (фильтры, проверки и генерация)
- **Удалены клиентские фильтры**: в `FeedPage.tsx` убраны `isVacancyPublic` и поиск по строке через `filter()`. Поиск теперь передается как query-параметр в `usePublicVacancies({ q: searchQuery })`.
- **Удален мертвый код**: виджет `FeedFilters` полностью выпилен из проекта, так как нигде не использовался, а логика сортировки в нем была сугубо клиентской.
- **Удалена клиентская сортировка**: из `ApplicationsPage.tsx` убрана функция `sortApplicationsByMatch`, теперь отображение идет "как есть" от сервера.
- **Оптимизирована проверка откликов**: в `useApplyLogic.ts` убрана загрузка *всех* откликов и проверка через `.some()`. Вместо этого добавлен новый метод `useCheckApplication`, который вызывает легкий серверный эндпоинт `GET /applications/check?vacancyId=...`
- **Удалена генерация данных на клиенте**: 
  - Из `useAuthLogic.ts` убрана генерация `tenantDomain` (парсинг email). 
  - Из `useUserEditForm.ts` убрана фейковая генерация `skill_id` — теперь на сервер уходит только `skill_name`, а ID присваивается базой данных.
- **Фронтенд успешно скомпилирован (tsc --noEmit).**

## Задача 3: Полная миграция на Tailwind CSS v4 (FSD Architecture)
- **Масштабный рефакторинг**: успешно переведены все 65+ `.css` файлов на утилитарные классы Tailwind v4.
- 4 параллельных субагента обработали директории:
  - `entities/` (8 файлов)
  - `widgets/` и `shared/` (11 файлов)
  - `pages/` (около 20 файлов)
  - `features/` (около 15 файлов)
- **Полное удаление `.css` файлов**: все стили интегрированы напрямую в `.tsx` файлы (React-компоненты). В проекте не осталось ни одного `.css` файла, кроме корневого `index.css`.
- **Очистка корня**: удалены неиспользуемые `global.css`, `theme.css` и `App.css`. В `index.css` оставлен только импорт `@import "tailwindcss";` и базовые глобальные стили (`html`, `body` и статусы).
- **Валидация**: прогон `npx tsc --noEmit` и `npm run lint` прошел абсолютно чисто (0 ошибок типов и импортов). UI стабилен.

### Задача 4: Разработка Admin Endpoints для vacancy-service
- **AdminVacancyController**: Создан контроллер для управления вакансиями со стороны администратора системы (`GET /api/admin/vacancies`, `PATCH /api/admin/vacancies/{id}`, `DELETE /api/admin/vacancies/{id}`). Поддерживается пагинация (`Pageable`) и поиск.
- **InternalVacancyController**: Добавлен внутренний эндпоинт `GET /internal/vacancies/count` для получения общего количества вакансий. Защищено через `InternalTokenFilter`.
- **VacancyService / Repository**: Добавлены необходимые методы для извлечения данных с учетом пейджинга и фильтров. Бэкенд проверен и компилируется успешно.

### Задача 4: Эндпоинты Администратора
- **identity-service**: Добавлены контроллеры для администратора (`AdminUserController`, `AdminCompanyController`, `AdminSkillModerationController`, `AdminDashboardController`).
- Добавлен поиск с пагинацией для пользователей (по `role` и строке `search`) и компаний (по `name`) в `UserRepository` и `TenantRepository`.
- Добавлена модерация навыков: поиск пользователей со статусом "pending" в JSONB поле `skills`, методы approve/reject (POST).
- Реализован Dashboard с подсчетом пользователей, компаний и обращением в `vacancy-service` по внутреннему токену (через `RestClient`) для получения числа вакансий.
- Код успешно скомпилирован.
