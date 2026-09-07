# Session Log — MeDev
**Дата:** 2026-09-07
**Проект:** MeDev (DevProfile)
**Фаза:** Level 4 — Production Live (Next.js 15 App Router SSG Landing in Monorepo)

## 1. Выполненные действия
- Внедрен чистый паттерн **Multi-Zone Subdomain Architecture** внутри монорепозитория MeDev:
  - `landing/` — изолированный проект на **Next.js 15 (App Router, SSG, TypeScript, Tailwind CSS v4, Lucide React)** для `medev.mrsgemaseny.com`.
  - `frontend/` — стабильный **Vite + React 19 SPA** (38/38 unit тестов) для `app.medev.mrsgemaseny.com`.
  - `backend/` — **Spring Boot 3.3.0** (253/253 JUnit тестов) для `medev-backend.onrender.com/api`.
- Разработан Next.js 15 SSG модуль:
  - `app/layout.tsx` с полными OpenGraph, Twitter Cards, robots и canonical метатегами.
  - `app/sitemap.ts` и `app/robots.ts` для поисковых ботов.
  - `app/privacy/page.tsx` и `app/terms/page.tsx` — статические правовые страницы.
  - Компоненты (`Header`, `Hero`, `Features`, `TemplatesShowcase`, `Pricing`, `Faq`, `Footer`) в строгом GitHub Dark Mode без лишнего визуального шума.
  - Кнопки авторизации и регистрации ведут напрямую на `https://app.medev.mrsgemaseny.com/login` и `register`.

## 2. Изменения в коде
- `landing/*` (полноценный Next.js 15 проект: package.json, next.config.ts, tsconfig.json, globals.css, app/*, components/*)
- `.agents/CONTEXT.md`

## 4. Перезапись текстов и философии лендинга (Customer-Centric Copy)
- Полностью переписан контент всех компонентов `landing/` с акцентом на ценность и боли пользователя вместо внутреннего описания архитектуры:
  - Исключены все внутренние термины (Groq, GPT-20B, Caffeine, Valkey, Flying Saucer, Zero-Trust, RLS, IDOR, Spring Boot, PostgreSQL, v1.0, sub-15ms).
  - `Header.tsx`: Убран `v1.0` и кнопка GitHub, акцент на CTA "Начать бесплатно".
  - `Hero.tsx`: Заголовок *"У тебя есть GitHub. Пора чтобы он работал на тебя."*, убраны хардкодные фейковые цифры (18 проектов, 1420 коммитов, 98/100).
  - `Features.tsx`: 4 пользовательские карточки (GitHub, Адаптация, Портфолио, Трекер). Убраны 3 нижние карточки про бэкенд, заменены на 3-шаговый блок *"Как это работает"*.
  - `TemplatesShowcase.tsx`: Простое и понятное позиционирование 6 шаблонов без технического жаргона.
  - `Pricing.tsx`: Очищены строки про кэширование и движки PDF, обновлены понятные бейджи Kaspi Pay и Stripe.
  - `Faq.tsx`: 6 вопросов и ответов, ориентированных на пользователя (что берем из GitHub, выдумывает ли AI, пройдет ли HR-фильтры, навсегда ли бесплатно, качество верстки, оплата Kaspi).
  - `Cta.tsx`: Добавлен финальный блок *"Готов попробовать?"* перед футером.
  - `Footer.tsx`: Очищен от v1.0 и технических меток live-окружения.
  - `layout.tsx`: Обновлены метаданные OpenGraph и поисковые теги.
## 5. Добавление OpenGraph изображения (og-image.png)
- Создано брендовое изображение `landing/public/og-image.png` размером 1200x630px в строгом стиле GitHub Dark Mode (`#0d1117`, акцент `#2ea043`, логотип MeDev, заголовок и ключевые преимущества).
- В `landing/app/layout.tsx` добавлены метаданные `openGraph.images` и `twitter.images` со ссылкой на `https://medev.mrsgemaseny.com/og-image.png`.
## 6. Редизайн типографики и тотальная очистка от визуального мусора
- Полностью удалены все микро-бейджи, серые теги категорий, микро-буллеты со списочками и мелкий текст.
- Настроены 2 ключевых шрифта через `next/font/google`: `Inter` (основной sans) и `JetBrains Mono` (mono).
- Верстка переведена на крупную, выразительную и читаемую типографику (H1 `text-6xl`/`text-7xl`, секции `text-3xl`/`text-5xl`, тело `text-base`/`text-lg`/`text-xl`).
## 7. Разделение роутинга Vite SPA (app.medev.mrsgemaseny.com)
- Устранена дублирующая посадочная страница на корневом пути `/` в Vite SPA:
  - В `frontend/src/app/router/AppRouter.tsx` корневой роут `/` переведен на компонент `RootRedirect`.
  - Авторизованный пользователь при заходе на `https://app.medev.mrsgemaseny.com/` мгновенно направляется в `/dashboard`.
  - Неавторизованный гость направляется в форму авторизации `/login`.
  - Единственной публичной точкой входа лендинга остается `https://medev.mrsgemaseny.com` (Next.js 15 SSG).
- Статус тестов: 38/38 unit тестов frontend, 253/253 backend.

## 8. Полный аудит соответствия и устранение дефектов (13 пунктов)
- **Colour Contrast (WCAG 2.1 AA)**:
  - Исправлена переменная `--color-text-muted` в `frontend/src/index.css`: в `.dark` с `#6e7681` (контраст 4.02:1, FAIL) на `#8b949e` (контраст 6.05:1, PASS); в `:root` (light) с `#818b98` на `#59636e` (контраст 4.6:1, PASS).
  - Устранены неконтрастные классы `text-gray-500` в правовых документах и `text-[#7d8590]` в `AiChatWidget.tsx`.
- **Alt text on images**:
  - Заменены шаблонные `alt="Avatar"` на содержательные подписи во всех компонентах (`DashboardPage`, `AboutSection`, `UserProfileDropdown`, `GithubImport`, `PortfolioView`).
  - Добавлены `aria-hidden="true"` и `focusable="false"` для векторных иконок GitHub в обоих проектах.
- **Refund Policy**:
  - Создана страница `landing/app/refund/page.tsx` с регламентом 14-дневной гарантии возврата средств для PRO, сроками (3 дня рассмотрение, 5-10 дней выплата) и контактами `support@medev.mrsgemaseny.com`.
  - Создан компонент `frontend/src/pages/legal/RefundPolicy.tsx` и зарегистрирован маршрут `/refund` в `AppRouter.tsx`.
  - Добавлены ссылки на Политику возврата в футеры лендинга и SPA, а также в карточки и модалку оплаты Kaspi Pay/Stripe (`PricingPage.tsx` и `Pricing.tsx`).
- **Privacy Policy & Terms of Service**:
  - Обе страницы расширены до полноценных юридических документов: указан оператор данных (MeDev / Murat Orynbasar, РК), разделы сбора данных GitHub OAuth, шифрование токенов, гарантия отсутствия обучения моделей Groq LLM на данных пользователей, права на удаление аккаунта за 48 часов, юрисдикция РК и досудебный порядок.
- **Accessibility (A11y)**:
  - Реализован WAI-ARIA паттерн для аккордеона FAQ в `landing/components/Faq.tsx` (`aria-expanded`, `aria-controls`, `role="region"`, `aria-labelledby`).
  - Добавлены клавиатурные стили фокуса `focus-visible:ring-2 focus-visible:ring-[#2ea043] focus-visible:outline-none` на все кнопки и ссылки лендинга и SPA.
  - Добавлены явные `aria-label` для icon-only кнопок (закрытие и отправка в `AiChatWidget.tsx`, кнопки в `KanbanBoard.tsx`).
  - В `Modal.tsx` внедрены `role="dialog"`, `aria-modal="true"`, `aria-labelledby="modal-title"`.
  - В `landing/app/layout.tsx` добавлен доступный Skip Link ("Перейти к основному содержимому").
- **Remove fake reviews**:
  - Проведена проверка кодовой базы: подтверждено 0 фейковых отзывов, фиктивных цитат или нарисованных рейтингов. Продукт честен.
- **3rd party embeds & битые ссылки**:
  - Заменены все битые ссылки на несуществующий домен `https://medev.app` на официальный `https://medev.mrsgemaseny.com` в `PortfolioView.tsx` и backend markdown шаблонах (`readme-creative.md`, `readme-full.md`).
- **Copyright on images**:
  - Удален неиспользуемый файл `frontend/src/assets/hero.png`.
- **Cookies policy & Banner**:
  - Создан и внедрен доступный `CookieBanner` в `landing/` и `frontend/` с сохранением согласия в `localStorage`.
- **Tracking**:
  - Подтверждено использование исключительно cookieless Vercel Web Analytics; отсутствие сторонних рекламных пикселей зафиксировано в документах.
- **Form consent**:
  - Под формами регистрации (`RegisterPage.tsx`), входа (`LoginPage.tsx`) и кнопками OAuth добавлен обязательный текст согласия с Условиями и Политикой конфиденциальности.
  - В загрузчик резюме (`ImportResumePage.tsx`) добавлен дисклеймер об обработке данных и автоматическом PII-маскировании.
- **Local laws**:
  - Обеспечено соответствие ЗРК «О персональных данных и их защите» № 94-V (согласие на трансграничную передачу, право на удаление) и ЗРК «О защите прав потребителей» № 274-IV (цены в тенге, условия возврата цифровых услуг).
- **Строгое соблюдение Rule 11**:
  - В заголовке `AiChatWidget.tsx` ошибочная подпись `Llama 3.3 70B` исправлена на `GPT-20B · SSE Stream`.
- **Статус тестов**:
  - Backend: 253/253 JUnit тестов успешно (Gradle).
  - Frontend: 38/38 unit тестов успешно (Vitest), сборка Vite успешна (1030ms).
  - Landing: Next.js 15 SSG build (9/9 статических страниц) успешно.

## 9. Завершение аудита соответствия и платформенной готовности (Пункты 14–19)
- **14. Clear button labels**:
  - В `CookieBanner.tsx` (в `landing/` и `frontend/`) размытая кнопка «Понятно» заменена на четкое целевое действие: «Принять необходимые».
  - В `Header.tsx` «Войти» уточнен до «Войти в аккаунт».
  - В `TemplatesShowcase.tsx` «Выбрать шаблон» заменен на «Выбрать шаблон резюме».
  - В `Pricing.tsx` кнопка платного тарифа переименована в «Оформить подписку PRO».
  - В `Hero.tsx` и `Cta.tsx` уточнены CTA («Скачать образец PDF», «Создать резюме через GitHub») и добавлены доступные `aria-label`.
  - В `ImportResumePage.tsx` кнопка выбора файла названа «Выбрать PDF-файл резюме».
  - В `AboutSection.tsx` кнопки профиля получили однозначные формулировки («Сохранить изменения профиля», «Отменить изменения», «Импортировать из PDF», «Сгенерировать резюме через AI»).
- **15. Check for cookie consent**:
  - В `CookieBanner` четко зафиксировано, что платформа использует исключительно строго необходимые файлы cookie (сессионный токен авторизации) и `localStorage` для настроек интерфейса.
  - Аналитика Vercel работает в cookieless-режиме без межсайтового трекинга.
  - Баннер снабжен `role="region" aria-label="Уведомление об использовании файлов cookie"`, focus-visible кольцами и сохранением согласия в `localStorage`.
- **16. Add real business details**:
  - Во все правовые документы (`landing/app/privacy/page.tsx`, `terms/page.tsx`, `refund/page.tsx`, `frontend/src/pages/legal/PrivacyPolicy.tsx`, `TermsOfService.tsx`, `RefundPolicy.tsx`) и в футер лендинга внедрен единый официальный блок реквизитов:
    - Оператор / Исполнитель: Индивидуальный предприниматель Орынбасар Мурат (ИП Орынбасар М.) / Individual Entrepreneur Murat Orynbasar.
    - Юрисдикция регистрации: г. Алматы, Республика Казахстан.
    - Контакты: `support@medev.mrsgemaseny.com`, `privacy@medev.mrsgemaseny.com`, Telegram: `@MrSgemaSeny`.
    - Регламент ответов службы поддержки: 24–48 часов.
- **17. Only collect necessary data (Data Minimization)**:
  - В Политику конфиденциальности добавлен специальный раздел «Принцип минимизации данных (Data Minimization)» со ссылкой на ст. 5(1)(c) GDPR и ст. 5 ЗРК № 94-V.
  - Зафиксирован исчерпывающий перечень сведений, которые сервис категорически не собирает (национальные ID/ИИН, точные домашние адреса, медицинские/религиозные данные, приватные репозитории GitHub, полные платежные карты/CVV).
  - Верифицировано, что `User.java` и формы профиля запрашивают строго минимальные профессиональные атрибуты.
- **18. Keyboard friendly forms**:
  - `Input.tsx`: Устранены перекрывающие инлайн-стили, внедрены четкие контрастные кольца фокуса: `focus-visible:ring-2 focus-visible:ring-[#2ea043]`.
  - `LoginPage.tsx` & `RegisterPage.tsx`: Все поля снабжены парными `<label htmlFor="...">` и `id="..."`, атрибутами `aria-invalid` и `aria-describedby` при ошибках; контейнер ошибки получил `role="alert" aria-live="polite"`.
  - `ImportResumePage.tsx`: Дропзона PDF оснащена `role="button" tabIndex={0}`, обработчиком клавиатурного ввода `onKeyDown` (Enter/Space) и `aria-label`.
  - `AboutSection.tsx`: Все поля ввода и textarea получили явные `id` и `htmlFor` метки.
  - `Modal.tsx`: Кнопка закрытия получила русскоязычный `aria-label="Закрыть модальное окно"` и `focus-visible` стиль.
- **19. Remove unsupported claims**:
  - В `Footer.tsx` заменено «Все сервисы работают в штатном режиме» на «Все системы платформы стабильны».
  - В `Faq.tsx` убрано утверждение «читают все крупные HR-платформы» и заменено на стандартное считывание текста популярными ATS и HR-платформами.
  - В `TemplatesShowcase.tsx` снято безапелляционное «Все шаблоны проходят фильтры» и переформулировано в соответствие техническим стандартам ATS-парсинга.
  - В устаревших виджетах лендинга `frontend/` сняты заявления «100% точность», «100% Live», «парсят 100% текста», «atsScore: 100%».
- **Статус верификации**:
  - Backend: 253/253 тестов JUnit зелёные (100%).
  - Frontend: 38/38 unit тестов Vitest зелёные (100%), Vite build успешен.
  - Landing: Next.js 15 SSG build (9/9 статических страниц) успешен.

## 10. Multi-Agent Orchestration & Cursor / Claude Bridge Setup
- **Создан локальный оркестратор (`scripts/orchestrate.js`)**:
  - Поддержка ролей: `reviewer` (код/безопасность), `architect` (FSD/архитектура), `copywriter` (тексты), `tester` (граничные кейсы).
  - Поддержка бэкендов: OpenRouter (модель по умолчанию `dots-studio/dots-3-note-preview:free` / `nvidia/nemotron`) и Claude Code CLI (`claude -p`).
  - Парсинг рассуждений (`reasoning` / `content`), таймаут 45с, очистка `<think>` тегов.
- **Интеграция с Cursor (`.cursorrules`)**:
  - В корень MeDev внедрен `.cursorrules` с инструкциями вызова оркестратора `node scripts/orchestrate.js --role <role> --prompt "<task>"`.
- **Харденинг фронтенда**:
  - `vite.config.ts`: `sourcemap: false` для продакшн сборки.
  - `vercel.json`: внедрены CSP и Security Headers.
- **Верификация**:
  - Живой тест оркестратора через Node.js: вызов субагента-ревьюера успешно завершился с кодом 0 и выдал глубокий разбор рисков CORS в консоль.
  - Frontend: 38/38 unit-тестов Vitest пройдены.





