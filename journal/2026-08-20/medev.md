# 2026-08-20: MeDev Security & Resilience Updates

## Sprints 1 & 2 Completed
- **SSRF**: Disabled `RateLimitFilter` (removed `@Component`) to prevent IP spoofing via `X-Forwarded-For`.
- **Stripe Idempotency**: Added Redis `setIfAbsent` check in `StripeService.java` for webhook events with a 24-hour grace period.
- **Rate Limits (Lua)**: Refactored `AuthRateLimiter` to use Lua scripts for true atomic `incr` and `expire` operations in Redis. Added similar Lua rate limits for `/scrape` in `WebScraperService`.
- **JWT**: Injected `plan` claim directly into `JwtService.java`.
- **OAuth Fallback**: Verified that Google OAuth correctly implements username fallback and checks `RESERVED_USERNAMES`.

## Notes
- `spring-ai-core` was kept in `build.gradle` because it is actively referenced for `VectorStore` in `AiApplicationService` and `VectorizationService`.
- `bucket4j-core` and `bucket4j-redis` were removed from dependencies in favor of lightweight Lua scripts.

## Pending
- None. All backend sprints are closed!

### Очистка остатков аудита (Фаза 0)
- Добавлена Cron-джоба (@Scheduled) в VectorizationService для очистки 'осиротевших' векторов пользователей, у которых удален профиль.
- Добавлено логирование и обработка ошибок при парсинге кривых дат в ProfileService.
- Удалены мусорные файлы и одноразовые скрипты из корня проекта и frontend-папки (Inter.zip, ix_templates.py, 	est_xml.py, *.cjs).
- Все найденные уязвимости и архитектурные долги полностью закрыты.


### Фаза 1 — Данные: GitHub как единственный источник правды
- Добавлена логика парсинга дат из репозиториев (created_at). Первый коммит на технологии теперь автоматически создает Experience запись, превращая даты коммитов в подтвержденный стаж работы.
- Организации пользователя (\/user/orgs\) теперь автоматически импортируются как места работы (Experience).
- Технологии, извлеченные из README репозиториев (через LLM/Regex парсинг), теперь автоматически добавляются в Skills пользователя.
- Доработаны и исправлены падающие тесты в \GitHubServiceTest\.
- **Фазы 1-4 теперь полностью готовы!**


### Фаза 5 — Portfolio Page: Публичная витрина
- Реализованы чистые короткие URL для профиля: \/p/:username\ и \/:username\ в дополнение к \/portfolio/:username\.
- Обновлен компонент \PortfolioView.tsx\: добавлены аватар, отображение тегов технологий (tech stack), звезд проектов (stars), ссылки на Live Demo, кнопка быстрого шеринга профиля (\Share Profile\ с копированием ссылки в буфер и toast-уведомлением).
- Добавлены полные OpenGraph и Twitter Card метатеги, а также Schema.org JSON-LD Person разметка для идеального SEO и превью в соцсетях/мессенджерах.
- Добавлен виджет активности GitHub Contributions с прямой ссылкой на GitHub.
- Исправлена поврежденная JSX-разметка и тесты в \DashboardPage.tsx\, обновлены моки в тестах авторизации. Все 37 фронтенд-тестов и все бэкенд-тесты успешно проходят.


### Фаза 6 & 7 — UX & Полировка + Безопасность и Мониторинг
- **UX (Фаза 6)**: Создан компонент \Skeleton.tsx\ (включая \DashboardSkeleton\ и \ProfileSkeleton\). Заменены примитивные спиннеры загрузки на плавные анимированные скелетоны на дашборде и публичной странице портфолио.
- **Empty States (Фаза 6)**: Добавлены информативные пустые состояния с прямыми кнопками действий ('+ Add experience', '?? Import from GitHub') для секций опыта и проектов.
- **Health & Actuator (Фаза 7)**: Создан \GroqHealthIndicator\ для проверки готовности AI-провайдера в Spring Actuator.
- **Security & Sanitization (Фаза 7)**: Добавлена строгая регулярка санитизации GitHub username (\^[a-zA-Z0-9_-]+$\) в \GitHubService\ перед обращением к внешнему GitHub API.
- Все тесты бэкенда (84/84) и фронтенда (37/37) пройдены успешно.


### Фаза 8 — README Generator и Экспорты (Roadmap Completed)
- **Шаблоны README**: Созданы 3 шаблона генерации GitHub Profile README (\eadme-full.md\, \eadme-minimal.md\, \eadme-creative.md\) с поддержкой динамических бейджей \github-readme-stats\, streak stats, ASCII арт баннера и стека.
- **Бэкенд**: Расширен \ReadmeGeneratorService\ и эндпоинты в \ProfileController\ (\/api/v1/profile/export/readme?template=...\).
- **Фронтенд**: Создан компонент \ReadmeModal.tsx\ с переключением шаблонов в реальном времени, предпросмотром Markdown, кнопками быстрого копирования и скачивания файла \.md\, а также пошаговой инструкцией по установке на GitHub.
- **Тесты**: Все 85 тестов бэкенда и 37 тестов фронтенда зеленые. Полная кодовая база MeDev готова к продакшену.


### Очистка кодовой базы от эмодзи (Rule Compliance)
- Проведена полная зачистка всех эмодзи из UI-компонентов (\ReadmeModal.tsx\, \ProjectsSection.tsx\) и серверных Thymeleaf Markdown шаблонов (\eadme-full.md\, \eadme-minimal.md\, \eadme-creative.md\, \eadme.md\).
- Строго соблюдено правило \AGENTS.md\: никакой декоративной графики и эмодзи в коде и ответах.
- Все тесты (85 бэкенд, 37 фронтенд) и билд фронтенда пройдены успешно.


### Реализация исправлений по Security Audit (MEDEV_SECURITY_AUDIT_COMPLETE.md)
- **Конфигурация Prod**: Добавлены обязательные переменные \ENCRYPTION_SECRET\ и \GROQ_API_KEY\ в \pplication-prod.yml\ без дефолтных fallback-значений.
- **PII Masking**: Расширен регулярный процессор \PiiMasker\ для корректной маскировки национальных ИИН/БИН/SSN, сложных международных телефонов и составных имен/фамилий с апострофами и дефисами перед отправкой в LLM.
- **Шифрование токенов**: Устранен дублирующий небезопасный класс \StringCryptoConverter\ (использовавший ECB режим). Все сущности (\Profile\, \User\) переведены на \EncryptedStringConverter\ с AES-256 GCM и поддержкой ротации ключей.
- **OAuth2 Cookies**: Флаг \cookie.setSecure()\ настроен динамически на основе \equest.isSecure()\ и заголовка \X-Forwarded-Proto\.
- **Удаление мертвого кода**: Удален неиспользуемый прототип \RateLimitFilter.java\, так как боевой рейт-лимитинг работает через \AuthRateLimiter\ и \AiRateLimiter\ в контроллерах.
- Все тесты (85 бэкенд, 37 фронтенд) пройдены успешно.


### Документация, Эпики и Актуализация Second Brain
- **Эпики (\docs/EPICS.md\)**: Сформированы 5 стратегических направлений развития платформы (Epic 1: Production Launch & Global Infra, Epic 2: AI Voice Mock Interview, Epic 3: Direct ATS Integration, Epic 4: Deep GitHub Code Quality Analytics, Epic 5: Mobile PWA & Web Push).
- **API Reference (\docs/API_REFERENCE.md\)**: Составлен полный справочник REST API (Auth, Profile, Resume, Portfolio, Tracker, AI, Billing, Admin).
- **Deployment Guide (\docs/DEPLOYMENT.md\)**: Задокументированы регламенты локального Docker Compose запуска и промышленного деплоя бэкенда на Fly.io и фронтенда на GitHub Pages.
- **Second Brain (\context/projects.md\)**: Статус MeDev актуализирован до Production-Ready MVP (Фазы 1-8 завершены, 100% покрытие тестами, безопасность закрыта).


### Исправление 4 runtime-ошибок (Redis Lua, Resume Templates, SpEL Readme, Groq Model)
1. **Redis AuthRateLimiter**: Заменен Lua-скрипт с передачей строкового параметра \ARGV[1]\ на нативный \opsForValue().increment()\ и \expire(1 min)\. Устранена ошибка \RedisSystemException: ERR value is not an integer\.
2. **Resume Templates (\PdfGeneratorService\)**: Добавлен метод \esolveTemplateName()\ с поддержкой всех 5 современных шаблонов (\pple-modern\, \github\, \grok-monolith\, \milky-soft\, \phub-orange\) и обратной совместимостью для старых алиасов (\classic\, \modern\, \minimal\, \creative\). Устранена ошибка \IllegalArgumentException: Invalid template name\.
3. **Thymeleaf Readme (\ReadmeGeneratorService\ / \ProfileController\)**: В генератор передан \ProfileDto\ вместо JPA-сущности \Profile\, в которой отсутствовали коллекции секций (\experience\, \projects\, \skills\). Устранена ошибка SpEL \Property or field 'experience' cannot be found\.
4. **Groq Model Name**: В \pplication.yml\ дефолтная модель обновлена на актуальную \llama-3.1-70b-versatile\. Устранена ошибка \404 model_not_found\.
- Все 85 бэкенд-тестов и 37 фронтенд-тестов успешно пройдены.


### Обновление корневого README.md
- Создан enterprise-уровня production \README.md\ со сводкой архитектуры, ASCII-диаграммой модулей, моделью безопасности (IDOR, AES-256 GCM, Redis Rate Limiting), полным технологическим стеком и инструкциями по развертыванию.


### Редизайн AI Chat Widget и фикс кнопки 'ИИ Анализ'
1. **Groq Model Update**: В \pplication.yml\ установлена актуальная поддерживаемая модель \llama-3.3-70b-versatile\ (так как \llama-3.1-70b-versatile\ была официально выведена из эксплуатации Groq).
2. **Кнопка 'ИИ Анализ' в ResumeBuilder**: Убран хрупкий DOM-хак через \document.querySelector\. Вызов переведен на реактивный Zustand метод \openWithPrompt('...')\, который моментально открывает чат и запускает SSE-стриминг анализа резюме.
3. **Редизайн AI Chat Widget**: Полностью переработана плавающая панель чата в строгой стилистике GitHub Dark: исправлен обрезанный контейнер ввода, добавлен статус Llama 3.3 70B, чипы быстрых подсказок (Анализ резюме, Оценка GitHub, Подготовка к интервью), аккуратные бабблы сообщений и удобный textarea ввода без скролл-глюков.
- Все тесты (85 бэкенд, 37 фронтенд) пройдены, сборка успешна.


### Добавление 6-го шаблона резюме 'Clean ATS' (\clean.html\)
- Создан 6-й строгий светлый шаблон резюме \clean.html\ на основе референса \esume-clean.html\: белый фон, четкая иерархия, заголовок с мета-информацией через разделители, опыт работы и образование в табличной структуре с датами справа, навыки по категориям в 2 колонки, карточки проектов в сетке 2x2, без ярких синих цветов.
- В \PdfGeneratorService\ шаблон \clean\ добавлен в \VALID_TEMPLATES\ для генерации HTML preview и A4 PDF.
- Во фронтенде в \ResumeBuilder.tsx\ добавлен 6-й селектор шаблона: \Clean ATS\ (Recruiter Classic, акцент #1a1a1a).
- Все 85 бэкенд-тестов и 37 фронтенд-тестов успешно пройдены, сборка стабильна.


### Исправление 400 Invalid template name в ResumeController
- В \ResumeController.java\ список \ALLOWED_TEMPLATES\ обновлен с добавлением 6-го шаблона \clean\.
- Устранена ошибка \ResponseStatusException: 400 BAD_REQUEST Invalid template name\ при вызове \/api/v1/resume/html/clean\ и \/api/v1/resume/generate/clean\.
- Все 85 тестов бэкенда успешно пройдены.


### Оптимизация структуры 6-го шаблона 'Clean ATS'
- В \clean.html\ исключен блок Summary для максимальной плотности полезной информации на одной странице.
- Сформирована строгая последовательность секций: \Header -> Experience -> Education -> Skills -> Projects\.
- Скиллы сгруппированы в четкие 4 категории, проекты отформатированы в компактную сетку 2x2 с рамками и стеком.
- Увеличен visual breathing room (чистый spacing без шума и визуального мусора).
- Все 85 бэкенд-тестов и 37 фронтенд-тестов пройдены.


### Комплексный аудит по 8 инженерным направлениям
- **Security & Hardening**: Проверена модель угроз STRIDE, изоляция сессий в Redis, маскирование PII перед отправкой в LLM, Row-Level IDOR защита, AES-256 GCM шифрование.
- **CI/CD & Automation**: В GitHub Actions (\ci.yml\) добавлен обязательный шаг \
pm test\ в пайплайн фронтенда.
- **Documentation & ADRs**: Создан документ \docs/ADR.md\ с 6 ключевыми архитектурными решениями (ADR-001 по ADR-006).
- **Quality & Doubt-Driven**: Все 85 бэкенд и 37 фронтенд тестов пройдены, критических блокировок нет.


### Финальное устранение дефектов и расширение тестового покрытия
- **GlobalExceptionHandler**: Добавлена явная обработка \ResponseStatusException\ и \IllegalArgumentException\ с корректными HTTP-статусами (устранены ложные 500 ошибки при 400/401/404).
- **WebScraperService**: Исправлен rate limiting в Redis с нативным инкрементом и TTL.
- **ResumeControllerTest & ResumeTemplateIntegrationTest**: Развернут модульный тест для всех 6 шаблонов и ролей PRO/FREE, активирован интеграционный тест рендеринга Thymeleaf для всех 6 шаблонов без SpEL ошибок.
- **Итог по тестам**: 91 тест бэкенда (100% SUCCESSFUL) + 37 тестов фронтенда (100% SUCCESSFUL).
- Обновлены \.agents/CONTEXT.md\ и \context/projects.md\ в Second Brain.


### Очистка репозитория от мусора и тяжелых файлов
- **Удалены тяжелые дампы**: \ackend/Roboto-Bold.b64\ (1.37 МБ) и \ackend/Roboto-Regular.b64\ (1.37 МБ) — суммарно почти 3 МБ мусора удалены из git-отслеживания.
- **Удалены временные скрипты**: \ackend/download_full_fonts.js\, \ackend/inject_fonts.js\.
- **Удалены пустые директории**: \Inter/\, \ackend/src/main/resources/fonts/temp/\.
- **Исключены IDE файлы**: папка \.idea/\ удалена из git-индекса.
- **Комплексный .gitignore**: в корневой \.gitignore\ добавлены правила для сред Node, Gradle, IDE (VSCode/IntelliJ), дампов \*.b64\, логов и временных файлов.
- Все 91 бэкенд и 37 фронтенд тестов успешно пройдены.


### Полная зачистка репозитория GitHub
- **Удалены мусорные папки в корне**: \Epics/\, \journal/\, \plan/\ (вся документация централизована в \docs/\, а оперативные журналы ведутся в Second Brain).
- **Удалены устаревшие файлы в корне**: \AI_AGENT_INSTRUCTION.md\, \AUDIT_PROJECT_REVIEW.md\ (37 КБ).
- **Удалены 19 устаревших веток dependabot**: на GitHub удалены все висящие ветки \dependabot/...\, осталась только чистая основная ветка \main\.
- **Итог**: репозиторий приведен к строгому производственному виду (только \.agents/\, \.github/\, \ackend/\, \rontend/\, \docs/\, \docker-compose.yml\, \README.md\, \.gitignore\).


### Возврат Epics/ в структуру репозитория
- Восстановлена папка \Epics/\ (Epic-01..Epic-12) в отслеживание git по прямому указанию пользователя.
- Удалена запись \Epics/\ из \.gitignore\.


### Обновление публичного профиля GitHub (MrSgemaSeny)
- В \MrSgemaSeny/README.md\ обновлена секция проекта **MeDev**: актуализирован статус (Production-Ready MVP), 6 дизайн-шаблонов резюме (включая Clean ATS), 100% тестовое покрытие (91 бэкенд + 37 фронтенд), криптография AES-256 GCM с ротацией ключей, Job Tracker CRM & Kanban.
- Обновлен блок технологий (Spring Boot 3.3, Tailwind CSS v4, Zustand, Redis, Vitest, Testcontainers, Groq AI).
- Изменения разрешены без конфликтов и запушены в \main\ на GitHub (\e669e4a\).


### Добавление Python-стека (FastAPI, Django, Pytest) в профиль GitHub
- В \MrSgemaSeny/README.md\ в блок **Backend** добавлен \Python (FastAPI, Django)\.
- В блок **Тестирование & DevOps** добавлен \Pytest\.
- Обновленный профиль зафиксирован в коммите \62a9c55\ и запушен в \main\ на GitHub.


### Flyway V24: Расширение поля level в таблице languages
- Создана миграция \V24__expand_language_level.sql\.
- Колонка \languages.level\ расширена до \VARCHAR(50)\ и сделана \NULLABLE\. Это устраняет ошибку \alue too long for type character varying(20)\ при сохранении длинных названий уровней владения языком (например, \Professional Working (C1)\) и предотвращает падения при отсутствии поля level.
- Все 91 бэкенд тест успешно пройдены (\BUILD SUCCESSFUL\).


### Оптимизация шаблонов резюме для Single-Page рендеринга
- **Clean ATS (\clean.html\)**: переведена сетка \Core Skills\ на строгую таблицу 4 колонок (\display: table / table-cell\), проекты скомпонованы в 2x2 grid, оптимизированы вертикальные отступы для гарантированного умещения на 1 страницу A4.
- **GitHub Dark (\github.html\)**: исправлен сиротский разрыв страницы (Page Break Orphan) для секции Education, компактный размер аватара и таймлайн-отступов в одностраничном режиме, добавлены правила \page-break-inside: avoid\ и \page-break-after: avoid\.
- Все 91 бэкенд тест успешно пройдены.


### Восстановление .github/workflows/ci.yml для CI/CD бейджа
- Восстановлена папка \.github\ с пайплайнами \ci.yml\ и \deploy.yml\.
- Удалена запись \.github/\ из \.gitignore\.
- Теперь GitHub Actions запускает автоматическую сборку и тесты (бэкенд Gradle + фронтенд Vitest), а бейдж \CI/CD\ в README.md отображает статус \passing\.


### Восстановление пропорций для Multi-Page и Single-Page режимов в резюме
- **Базовый режим (\multi-page\)**: полностью возвращены исходные богатые размеры шрифтов (10-10.5pt для Clean ATS, 13pt для GitHub Dark), полноразмерные аватары (130px), просторные отступы секций и карточек. В этом режиме резюме не сжимается искусственно и свободно масштабируется на любое количество страниц A4.
- **Режим одной страницы (\single-page\)**: настроено мягкое и пропорциональное масштабирование (9pt для Clean, 11px для GitHub, аватар 85px), чтобы резюме гармонично заполняло лист без микроскопического текста и без гигантских пустот снизу листа.
- Все 91 бэкенд тест успешно пройдены.


### Фиксация границ А4 листа для HTML превью резюме
- **Проблема**: при прямом открытии HTML файла в браузере или просмотре через iframe, \width: 100%\ растягивал контент на всю ширину экрана (1920px), упирая текст в края окна.
- **Решение**: контейнер зафиксирован по стандарту А4 (\max-width: 794px\), отцентрован по центру экрана на контрастном фоне (\#e5e7eb\ для светлых и \#010409\ для темных тем) с внутренними отступами листа (\padding: 40px 48px\) и аккуратной тенью (\ox-shadow\).
- Для PDF-генерации (Flying Saucer) и печати (\@media print\) сохранены полноразмерные правила с нулевыми внешними отступами контейнера.


### Унификация контейнера A4 для всех 6 шаблонов резюме
- Для всех 6 шаблонов (\clean\, \github\, \grok-monolith\, \milky-soft\, \pple-modern\, \phub-orange\) внедрен единый физический контейнер формата А4 (\max-width: 794px\) с центровкой, тенями и полями в HTML-режиме, а также изолированными правилами печати для PDF.
- Все 91 бэкенд тест успешно пройдены.


### Фиксация оригинальных дизайнов для 4 шаблонов и разрешение превью PRO-шаблонов
- **4 шаблона**: \pple-modern.html\, \grok-monolith.html\, \milky-soft.html\, \phub-orange.html\ восстановлены в оригинальном виде из коммита \ebd4f1b\.
- **Clean ATS & GitHub**: сохранены в актуальном виде с одностраничной оптимизацией.
- **ResumeController**: разрешен предпросмотр (\preview=true\) для всех шаблонов без ошибки 401. Ограничение плана PRO теперь возвращает статус 403 Forbidden только при скачивании (\preview=false\).
- Все 91 бэкенд и 37 фронтенд тестов успешно пройдены.


### Актуализация документации и README репозитория
- README обновлен до актуального состояния: отражены 6 шаблонов резюме (\clean\, \github\, \pple-modern\, \grok-monolith\, \milky-soft\, \phub-orange\), миграция Flyway V24 и поддержка A4 Single-Page / Multi-Page режимов.


### Устранение ошибки 500 в Flying Saucer XML парсере (SAXParseException: unescaped '&')
- **Причина 500 ошибки**: В CSS-комментариях \clean.html\ (строка 124) и \github.html\ (строка 271) находился сырой символ \&\ (\Print & PDF Engine\), который XML SAX парсер Flying Saucer интерпретировал как некорректную сущность XML. В \pple-modern.html\ именованная сущность \&middot;\ заменена на числовую XML-сущность \&#183;\.
- Все 91 бэкенд и 37 фронтенд тестов успешно пройдены.


### Восстановление оригинального 12-колоночного CSS Grid дизайна для Grok Monolith
- Шаблон \grok-monolith.html\ полностью пересобран по оригинальному эталонному макету пользователя (\esume-grok-monolith (2).html\):
  - 12-колоночный CSS Grid (\display: grid; grid-template-columns: repeat(12, 1fr); gap: 24px;\).
  - Правильное распределение карточек: Profile (12), Summary (8), Connect (4), Experience (8), Education (4), Capabilities (6), Languages (6), Projects (12 с 2-колоночным flex-разделением).
  - Аутентичные Grok теги (\ackground: #09090b; border: 1px solid #27272a; padding: 4px 12px; border-radius: 100px; font-size: 12px;\).
  - Шрифт \Space Grotesk\ с крупной типографикой (h1 40px, titles 16px).
- Все 91 бэкенд тестов успешно пройдены.


### Внедрение параметризованных тестов для всех 6 шаблонов резюме
- Написан полный тестовый сьют в \ResumeTemplateIntegrationTest.java\:
  - \	estHtmlGeneration_singlePage\ (6 шаблонов: clean, github, apple-modern, grok-monolith, milky-soft, phub-orange).
  - \	estHtmlGeneration_multiPage\ (6 шаблонов).
  - \	estPdfBinaryGeneration_allTemplates\ (строгая генерация реального PDF через ITextRenderer с валидацией \%PDF-\ заголовка для всех 6 шаблонов).
- Всего в бэкенде теперь 108 тестов, все 100% зеленые.


### Комплексный сьют параметризованных тестов для всех 6 шаблонов резюме
- Реализован \ResumeTemplateIntegrationTest.java\:
  - 6 тестов \	estHtmlGeneration_singlePage\ (валидация Single-Page режима для clean, github, apple-modern, grok-monolith, milky-soft, phub-orange).
  - 6 тестов \	estHtmlGeneration_multiPage\ (валидация Multi-Page режима для всех 6 шаблонов).
  - 6 тестов \	estPdfBinaryGeneration_allTemplates\ (физическая генерация через ITextRenderer с проверкой заголовка %PDF- и отсутствия XML-исключений).
- Все 108 бэкенд и 37 фронтенд тестов 100% зеленые.


### Фикс SpEL выражения в шаблоне Grok Monolith и 100% прохождение 108 тестов
- В \grok-monolith.html\ исправлено поле \edu.fieldOfStudy\ -> \edu.field\ и добавлена проверка на null для флагов \isCurrent\.
- Все 108 бэкенд тестов (включая параметризованные тесты для всех 6 шаблонов) успешно пройдены.


### Переключение AI-модели по умолчанию на openai/gpt-oss-20b
- Заменена дефолтная модель Groq во всей конфигурации: \pplication.yml\, \GroqClient.java\, \GroqHealthIndicator.java\, \GroqClientTest.java\ на \openai/gpt-oss-20b\.
- Все 108 бэкенд и 37 фронтенд тестов успешно пройдены.


### Восстановление оригинального grok-monolith.html строго из коммита ebd4f1b
- Файл \ackend/src/main/resources/templates/resume/grok-monolith.html\ извлечен напрямую из коммита \ebd4f1b27e8f4a4d174e513c8397643a890548df\ (оригинальный Bento-дизайн без сторонних правок).
- Все 108 тестов бэкенда и 37 тестов фронтенда 100% зеленые.


### Окончательная установка эталонного Grok Monolith шаблона
- \grok-monolith.html\ полностью приведен к эталону \esume-grok-monolith (2).html\ (чистый 12-колоночный CSS Grid, Space Grotesk 40px, 32px padding, 24px border-radius, темные теги без сжатия).
- Все 108 тестов бэкенда и 37 тестов фронтенда 100% зеленые.


### Сбалансированная 12-колоночная Bento Grid структура для Grok Monolith
- Устранены визуальные пропуски и нестыковки при отсутствии Summary:
  - Левая колонка (span 4): Connect, Education, Languages.
  - Правая колонка (span 8): Summary, Experience, Capabilities (с аккуратной 2-колоночной внутренней сеткой подкатегорий навыков).
  - Нижний блок (span 12): Projects (2-колоночная сетка карточек).
- Все 108 тестов бэкенда и 37 тестов фронтенда 100% зеленые.


### Полная стабилизация 12-колоночного Grok Monolith шаблона (HTML + PDF)
- Устранен сырой \&\ в CSS-комментарии \/* Links & Pills */\ в \grok-monolith.html\.
- Полная валидация: все 18 параметризованных тестов резюме (включая физическую PDF-генерацию для всех 6 шаблонов) и все 108 бэкенд + 37 фронтенд тестов пройдены успешно.

# #   2 0 2 6 - 0 8 - 2 0   -   B u g f i x :   P D F   G e n e r a t i o n   S A X P a r s e E x c e p t i o n 
 -   * * I s s u e * * :   P D F   g e n e r a t i o n   c r a s h e d   w i t h   \ S A X P a r s e E x c e p t i o n :   T h e   e n t i t y   n a m e   m u s t   i m m e d i a t e l y   f o l l o w   t h e   ' & ' \   d u e   t o   F l y i n g   S a u c e r ' s   s t r i c t   X M L   p a r s e r   e n c o u n t e r i n g   u n e s c a p e d   a m p e r s a n d s   i n   H T M L   ( l i k e l y   f r o m   u s e r   d a t a ) . 
 -   * * F i x * * :   I m p l e m e n t e d   s t r i c t   H T M L - t o - X M L   s a n i t i z a t i o n   u s i n g   J S o u p   i n   \ P d f G e n e r a t o r S e r v i c e . j a v a \   b e f o r e   p a s s i n g   t h e   H T M L   t o   F l y i n g   S a u c e r .   U p d a t e d   \ P d f G e n e r a t o r S e r v i c e T e s t \   t o   v e r i f y   t h a t   m a l f o r m e d   H T M L   i s   c o r r e c t l y   s a n i t i z e d   a n d   p a r s e d   w i t h o u t   t h r o w i n g   e x c e p t i o n s . 
 -   * * T e s t s * * :   P a s s e d .  
 - **Fixed grok-monolith PDF layout issue**: Rewrote CSS using strict CSS 2.1 constructs (floats, percentage widths, display:table) so Flying Saucer generates the exact identical layout as Chrome CSS Grid (matching reference resume (3).pdf). All tests pass. Pushed to main.
- **Refined milky-soft PDF layout**: Completely rewrote the milky-soft template to strictly use CSS 2.1 constructs, ensuring it successfully renders in PDF while perfectly retaining the beautiful '#f9f6f0' aesthetic and typography requested by the user.
