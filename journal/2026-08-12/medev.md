# Session Log - MeDev - 2026-08-12

## Добавлено
- Внедрен `AuthRateLimiter` (Bucket4j) для защиты эндпоинтов `/v1/auth/**` от брутфорса и спама (лимит 20 запросов в минуту по IP).

## Изменено
- Устранена уязвимость Account Takeover via Pre-Account Creation в `CustomOAuth2UserService` (при привязке OAuth к неподтвержденному аккаунту с паролем старый пароль инвалидируется генерацией случайного хеша).
- Исправлено отсутствие пробелов при стриминге ответов AI в `GroqClient.java` (исключение `isBlank()` заменено на `isEmpty()`, так как токены-пробелы удалялись).
- Устранена ошибка `FileNotFoundException` при вызове AI (убрано лишнее `.txt` в `AiAnalysisService.java`).
- Добавлена передача `username` и `plan` в `OAuth2LoginSuccessHandler` для корректного отображения профиля и хедера на фронтенде после логина через GitHub/Google.
- Жестко прописан темный режим (`class="dark"`) в `index.html` согласно требованиям дизайна (Strict GitHub Dark Mode aesthetic).
- Исправлен баг в `axios.ts` при установке заголовков для Axios v1.x (заменено прямое присваивание `config.headers.Authorization` на `config.headers.set()`), который приводил к циклическому вылету пользователя на страницу логина при перезагрузке страницы.
- Полностью переписан системный промпт ИИ (`assistant_system_v1.txt`): убрано роботизированное поведение, жесткая привязка к имени профиля (теперь разрешены никнеймы), а также запрещено прямое перечисление доступов и ограничений системы в угоду естественному общению.
- Обновлен дизайн компонента `AppHeader.tsx`: добавлена адаптивная строка поиска (Search Bar) в левой части хедера, гармонирующая с GitHub Dark Mode, для обеспечения симметрии с правым меню профиля.
- Обновлен дизайн компонента `AppHeader.tsx`: добавлена адаптивная строка поиска (Search Bar) в левой части хедера, гармонирующая с GitHub Dark Mode, для обеспечения симметрии с правым меню профиля.
- **Исправлен критический баг с бесконечным редиректом на `/login` при перезагрузке страницы:** добавлено ожидание гидратации хранилища `useAuthStore.persist` в компоненты `PrivateRoute` и `PublicRoute` (`AppRouter.tsx`), предотвращающее ложное срабатывание редиректа до загрузки токена из `localStorage`.
- **Масштабный UI редизайн (Стиль GitHub):** Восстановлен `AppHeader.tsx` в черном цвете (`#010409`) для создания T-образного макета, как в GitHub. Боковой `AppSidebar.tsx` и карточки на дашборде переведены в строгий черный цвет с бордерами для резкого контраста на фоне серого канваса (`#0d1117`).
- **Очистка стилей и макет AboutSection:** Восстановлены строгие токены GitHub Dark Mode в `index.css`. Форма настроена по жесткому правилу 4px grid (никаких отступов в 10px). Компонент `AboutSection.tsx` полностью переписан под новый HTML-макет с использованием 3-колоночной сетки и минималистичных инпутов цвета `surface-inset`.
- **Исправлен UX-баг в навигации:** В `AppSidebar.tsx` устранена проблема ложной подсветки активной секции (раньше всегда подсвечивался "About"). Теперь активная секция вычисляется динамически на основе `location.hash`.

- **Уязвимости безопасности (Auth & JWT):** Закрыты критические дыры из аудита.
  1. OAuth2 больше не передает токены в URL. Реализован механизм одноразового кода (`oauth2_code`), который сохраняется в Redis (на 5 минут) и обменивается фронтендом на токены через новый эндпоинт `/v1/auth/oauth2/exchange`.
  2. Устранен баг с подменой типов токенов: теперь JWT явно содержат claim `type` (`access` или `refresh`). `JwtFilter` строго блокирует refresh-токены.
  3. Исправлен баг в Rate Limiter, который слепо доверял `X-Forwarded-For`. Теперь используется `request.getRemoteAddr()`.
  4. Закрыто состояние гонки (Race Condition) при регистрации — теперь корректно перехватывается `DataIntegrityViolationException`.
- **Исправления Billing (Stripe):** Добавлен обработчик вебхуков на отмену и неоплату (`customer.subscription.deleted`, `customer.subscription.updated`, `invoice.payment_failed`), который автоматически переводит пользователя на `FREE` план. Фронтенд (`SuccessPage.tsx`) больше не верит URL-у, а безопасно опрашивает новый эндпоинт `/v1/billing/status`.
- **Удаление мертвого кода:** Вырезаны старые и сломанные эндпоинты `/parse` и `/import` из `ResumeController.java`, а также `PdfParserService.java`.
- **UI/UX (Дизайн-фиксы):** 
  - Темная тема теперь работает по умолчанию благодаря блокирующему скрипту в `index.html`. 
  - Создан и подключен глобальный хедер `AppHeader.tsx`. 
  - `UserProfileDropdown.tsx` полностью переписан (умеет якориться по-разному в хедере и сайдбаре, отображает скелетон, пока нет юзернейма, реально сохраняет выбор темы в `localStorage`).
  - В сайдбаре кнопка Settings "выключена" (серая), а навигация по секциям корректно подхватывает `#hash` из URL.
- **Баг редиректа на Login (после F5):** Устранены 3 причины разрыва сессии:
  1. Фронтенд (`axios.ts`): Интерцептор больше не выкидывает юзера при `429 Rate Limit` или `500` на `/auth/refresh`. Теперь логаут происходит строго при статусе `401`.
  2. Бэкенд (`CorsConfig.java`): Удален конфликтующий бин, который дублировал `Access-Control-Allow-Origin` заголовки из `SecurityConfig` и вызывал CORS Error.
  3. Докер (`docker-compose.yml`): Redis-контейнеру добавлен volume (`redis_data`) и флаг `--save`, чтобы refresh-токены не стирались при перезапуске (Dev-окружение).

## Проблемы (Решено)
- **Уязвимости безопасности:** Отсутствие защиты от перебора паролей и возможность угона аккаунта при привязке OAuth. Обе уязвимости успешно закрыты.
- **UI/UX Баги:** Отсутствие шапки (хедера) и белая тема по умолчанию устранены. Баг с вылетом пользователя на страницу логина (непередача JWT токена фронтендом) исправлен.
- **Баги AI:** Проблема со слиянием слов (удаление пробелов) и сбоем загрузки промпта `/v1/ai/parse-resume` решена.

## Тесты
- Юнит тесты бэкенда успешно прошли (BUILD SUCCESSFUL, ./gradlew test).
- Бэкенд и фронтенд успешно скомпилированы.


- **Premium Landing Page**: Integrated standalone medev.html as the primary / route for unauthenticated users.
- **Enterprise Job Tracker**: Removed @dnd-kit completely. Replaced drag-and-drop Kanban board with a dense Enterprise CRM table view featuring top metric cards, filters, and a GitHub Dark Mode aesthetic.
- **Dedicated Import Route**: Moved 'Zero-Input Onboarding' PDF parsing logic out of the wizard into a dedicated /import route accessible from the Sidebar.
- **Dashboard Redesign**: ��������� ��������� ��������� \DashboardPage.tsx\ � �������������� ������� ������ �� ������ \medev.html\. ��������� �������� \.glow-dot\ � \.fade-in\, �������� Quick Actions � ������ Portfolio Preview. ������ ��� ������� ������.
- **Frontend Tests**: ������� ������ Vitest-���� \DashboardPage.test.tsx\ ��� �������� ���������� ������� ������. ����� (\
pm test\) ������� �������� (7/7 ������ � 2 ������).
- **AI Resume Parser Upgrade**: ��������� ��������� �������� ������ �������.
  - ������ \esume_parser_v1.txt\ �������� ��� ���������� ��������� �������� JSON (skills, experience, education, languages). �������� strict JSON �����.
  - ������� ����� DTO (\AiParsedResumeDto\, \AiExperienceDto\, \AiEducationDto\, \AiSkillDto\, \AiLanguageDto\).
  - \ProfileService.importParsedResume\ ������ ��������� ��������� JSON � � ����� ���������� ��������� �������� (clear and insert) ������ ��������� �� �����.
  - \AiController\ ������ ����� ���������� \ProfileDto\ �� �������� ��� ����������� ���������� UI ����� �������.
- **UI �����������**: ��������� ������������ ������ �� GitHub � ����� Stats �� \DashboardPage.tsx\.
- **������� AI ������� � JPA**:
  - ��������� ��������� \@JsonIgnoreProperties(ignoreUnknown = true)\ �� ��� \Ai...Dto\, ����� Jackson �� ����� ��� ������������� Groq.
  - ���������� ������ ���������� JPA \ConcurrentModificationException\/orphanRemoval: �������� \deleteByProfileId\ �� \profile.getSkills().clear()\ � ����������� \saveAndFlush\.
- **UI Dashboard Live Preview**:
  - ������� ������ ����������� �������� ������ ������� ������������ �� ������������ JSON: ��������, ������ �������� (Github, LinkedIn, Telegram, Web), ����� ��������, ��������� ����� ������ � �����������, � ����� ��������������� ���� �������.
- **UI Fix**: ������ ����� 'Live Dashboard' �� �������.
- **Hotfix**: ���������� ������ ���������� � ProfileService (������������ �������� �������� ���������). ����� ����� ������� ������.
- **UI Fix**: ��������� URL ��� GitHub OAuth � ���������� GithubImport (�������� ������� /api).
- **UI Redesign**: ������ �������� Job Tracker CRM. ���������� ������� � ������� ������� �������� �� ���������� ������ � ������ � ����� GitHub Issues (���������, ������ ��������, ����) ��� ������������ GitHub Dark Mode aesthetic.
- **Backend Bugfix (Deduplication)**: ��������� ������ ������������ �������� � ProfileService.importProjects. ������ ��� ������� ������������� ���������� ������ �����, ��������� ��-�� race-condition'�, � ����� ���������� ��������� ��������� ��� � ������ ����������.
- **UI UX Fix**: � ���������� GithubImport ������ 'Connect GitHub' ������ ����������, ���� ������� ��� �������� � ������� (���� githubUsername). ��� �������� ����� ������ � ������ ������ ������ (��������, ���� �� �����), ����� �� ������� ������������.
- **AI Vectorization (RAG)**: ��������� ��������� pgvector ����� Spring AI � �������������� ��������� ������ spring-ai-transformers. ���������� VectorizationService ��� �������� ����������� �������� � �����. ��������� ���������������� ����� � ��������� ������ ������ ���������� RAG (Retrieval-Augmented Generation) ��� ������������ ������ ����� ����������� �������� ��� ��������. �� ��������� � Job Tracker ��������� ������ � ������� ��� ��������� Cover Letter ����� RAG.
- **Frontend UI**: ����������� ����� ���������� GitHub. ������ ��� ������������� �������� ������������ �������� �������� � ��������, ���������� � �������� Connected, ������ ������ ������ � �������� ������������.
- **Admin Panel**: �������� �������� ��� �����-������ (Dashboard, Users, Audit).
- **Testing**: ��������� ������ ������� ����� ��� AuthService � AiAnalysisService, ��������������� � ����������.

## Enterprise Polish: Admin Dashboard, RBAC, Audit Logs (Session 2)
- Создан модуль udit (Entity, Repository, Service) для логирования критических действий.
- Flyway миграция V19__create_audit_logs.sql для таблицы аудита с индексами.
- Создан модуль dmin (AdminController, AdminService, AdminDashboardDto).
- SecurityConfig УЖЕ содержал правило .requestMatchers("/v1/admin/**").hasRole("ADMIN").
- Frontend: AdminGuard (HOC), AdminDashboardPage, AdminUsersPage, AdminAuditPage.
- Роутинг: /admin/* защищен AdminGuard (проверка role === 'ADMIN').
- Кнопка "Админ-панель" добавлена в UserProfileDropdown (видна только ADMIN).
- Исправлен дублированный ключ spring: в pplication.yml (DuplicateKeyException).
- Исправлены тесты: AiAnalysisServiceTest (тип возврата), AuthServiceTest (extractType mock), JwtFilterTest (extractType mock), ProfileServiceTest (eventPublisher mock).
- Улучшен UI AiChatWidget: увеличен размер окна (480x650), добавлен leading-relaxed и word-break.

## GitHub Account Linking & OAuth Fixes
- **Backend (CustomOAuth2UserService)**: Внедрена логика безопасной привязки аккаунта через проверку cookie medev_link_jwt. Теперь при несовпадении email не создается дубликат, а обновляется githubId текущего пользователя.
- **Backend (OAuth2LoginSuccessHandler)**: Обработка _action=LINK_ACCOUNT — удаление временной куки и редирект обратно на /profile/edit?github_linked=true без подмены основного токена.
- **Frontend (GithubImport)**: Добавлена установка medev_link_jwt (на 60с) перед редиректом на OAuth2. Вычищены остатки старых Tailwind классов, UI переведен на переменные GitHub Dark Mode (ar(--color-bg-secondary) и т.д.).
- **Frontend (Auth)**: Исправлен критический баг хардкода. В LoginPage и RegisterPage ссылки /api/oauth2/authorization/github теперь собираются динамически через import.meta.env.VITE_API_URL.
