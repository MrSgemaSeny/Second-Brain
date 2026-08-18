# ADR-008: Вектор совместимости для слабых ПК и старых браузеров
_Дата: 2026-08-18_
_Статус: принято_
_Проект: JF-1C_

## Контекст

Целевая аудитория JF-1C — бухгалтеры казахстанских компаний. Рабочие места: офисные ПК и ноутбуки
на Windows 7/10, Chrome 109 (последняя версия с поддержкой Win7), Firefox ESR 115, офисные сети
с прокси. Характеристики машин: 4-8 GB RAM, Pentium/Core i3, встроенная графика.

Инцидент 2026-08-18 показал: без явного `build.target` в Vite 8 сборка идёт в `esnext`,
что не гарантирует совместимость с Chrome 109.

## Решение

Принят вектор "работает на Chrome 109 / Firefox 115, деградирует gracefully на IE 11".

### Правила сборки

- `build.target: ['chrome109', 'firefox115']` в `vite.config.ts` — обязательно
- IE 11: показываем `<noscript>` / `nomodule` fallback с сообщением об обновлении браузера,
  полная поддержка не цель
- Autoprefixer подключён для CSS-совместимости

### Правила производительности

- Framer Motion: все анимации оборачиваются в проверку `prefers-reduced-motion`.
  На слабых ПК пользователи часто включают этот режим, или его включает Windows 7 по умолчанию
  при слабом железе. Если активен — анимации отключаются полностью (`duration: 0`)
- Чанки: разделены по ролям (chunk-admin, chunk-employee, chunk-client, chunk-learner) —
  бухгалтер грузит только свой чанк, не весь бандл
- Lazy loading: все страницы через `lazyWithRetry` (уже реализовано)
- Google Fonts: `display=swap` + системный fallback шрифт в CSS чтобы контент был читаем
  пока шрифт грузится или если fonts.googleapis.com заблокирован корпоративным прокси

### Правила совместимости браузеров

- Не использовать API новее Chrome 109: `Array.at()` — ок, `Array.toSorted()` — нет (Chrome 110+)
- `localStorage` / `sessionStorage` — допустимо (поддержка с IE8)
- `fetch` — допустимо (Chrome 42+, полифилл не нужен)
- `WebSocket` — допустимо, SockJS даёт fallback на long-polling для корпоративных прокси
  которые блокируют WS-апгрейды
- `crypto.subtle` — не использовать на клиенте (нет в IE11, ограничен в Win7 Chrome)
- Google OAuth (GSI/FedCM) — не единственный способ входа, local auth обязателен как fallback

## Причины

- Аудит 2026-08-18: без явного target Vite 8 может генерировать синтаксис несовместимый с Chrome 109
- Реальные пользователи не контролируют версию браузера — это корпоративная политика IT-отдела
- `prefers-reduced-motion` решает сразу две проблемы: производительность + accessibility
- SockJS уже в стеке — WS-fallback бесплатный

- Нельзя использовать фичи новее Chrome 109 без полифилла
- При добавлении новых зависимостей проверять их browser support на caniuse.com
- IE 11 официально не поддерживается, но белого экрана быть не должно — только сообщение
- Google OAuth остаётся как удобный способ для тех у кого Chrome актуальный, не как единственный

---

## Матрица поддержки браузеров (полная)

### Desktop

| Браузер | Совместимость | Примечания |
|---------|---------------|------------|
| Chrome 109+ | Полная | Целевой браузер Win7 |
| Edge 79+ | Полная | Chromium под капотом, паритет с Chrome |
| Firefox 115+ | Полная | Второй целевой браузер |
| Yandex Browser | Полная | Форк Chromium, отстаёт на 1-2 версии — некритично |
| Opera | Полная | Аналогично Yandex |
| Safari 16+ (macOS) | Частичная | WebKit quirks: даты требуют ISO-формата, COOP может блокировать OAuth popup |
| IE 11 | Не поддерживается | ES modules не работают. Показываем `nomodule` fallback с сообщением |

### Mobile

| Браузер | Совместимость | Примечания |
|---------|---------------|------------|
| Android Chrome 109+ | Полная | Основной мобильный браузер |
| iOS Safari 16+ | Частичная | Уже зафиксировано: ITP bypass (Bearer вместо cookie), OAuth через JSON capture |
| Chrome iOS / Firefox iOS | Частичная | На iOS все браузеры = WebKit обёртка, поведение как iOS Safari |
| Samsung Internet | Хорошая | Chromium-форк, отстаёт на ~2 версии |
| Huawei Browser | Хорошая | Аналогично Samsung Internet |
| UC Browser | Рискованная | Нестандартный fetch и WebSocket в старых версиях. Не тестируется |

### In-App / WebView

| Контекст | Совместимость | Примечания |
|----------|---------------|------------|
| Gmail (Android) — Chrome Custom Tab | Полная | Фактически Chrome |
| Telegram WebApp | Хорошая | Chromium WebView, но нет `window.open()` для OAuth popup |
| WhatsApp / VK / Instagram ссылки | Средняя | Android System WebView — версия зависит от устройства |
| Facebook in-app | Плохая | Блокирует сторонние cookie, OAuth popup не работает |
| Kaspi / другие KZ приложения | Средняя | Android WebView, может быть устаревшим на старых Android |

## Известные дыры и митигации

| Проблема | Статус | Митигация |
|----------|--------|-----------|
| Google OAuth в in-app браузерах | Открыта | Переключить на `ux_mode: 'redirect'` вместо popup. Redirect работает везде — in-app, WebView, Safari. Скрывать кнопку — НЕВЕРНОЕ решение. |
| COOP блокирует postMessage у Google GSI | Открыта | Решается тем же `ux_mode: 'redirect'` — postMessage не нужен при redirect-флоу. |
| Android WebView < Chrome 67 | Маловероятна | Local auth как fallback покрывает кейс |
| iOS ITP блокирует HttpOnly cookie | Закрыта | Зафиксировано: Bearer токен в JSON response + in-memory storage |
| OAuth popup на iOS Safari | Закрыта | Зафиксировано: accessToken в AuthResponse не @JsonIgnore |
| Корпоративный прокси блокирует WebSocket | Открыта | SockJS даёт автоматический fallback на XHR-streaming |
| Google Fonts заблокированы прокси | Открыта | `display=swap` + системный fallback шрифт — контент читаем |

