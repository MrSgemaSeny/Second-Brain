# Security Audit: MeDev — Полный отчёт

Структура: сначала критика, потом фиксы с кодом. Всё по приоритету Security > Correctness > остальное.

---

## [CRITICAL] #1 — SSRF: произвольный URL-scraping без валидации

**Файл:** `tracker/controller/JobApplicationController.java` → `GET /v1/tracker/applications/scrape?url=...`

`Jsoup.connect(url).get()` — подключается к **любому** хосту, включая AWS metadata, Redis, внутренние сервисы.

**Фикс — белый список хостов:**
Внедрить валидацию хостов и блокировку loopback/private IP адресов перед скрапингом в `WebScraperService.java`.

---

## [CRITICAL] #2 — Kaspi webhook: верификация подписи — заглушка

**Файл:** `KaspiPayService.java`

Любой POST с непустым хедером `X-Kaspi-Signature` выдает PRO-план.

**Фикс — реальный HMAC:**
Использовать `HmacSHA256` и `MessageDigest.isEqual` (constant-time comparison). До подключения API закрыть эндпоинт (`@Profile("!kaspi")`).

---

## [CRITICAL] #3 — AES/ECB шифрование GitHub токенов

**Файл:** `EncryptionUtils.java`

Используется `Cipher.getInstance("AES")` (ECB по умолчанию). ECB детерминирован и небезопасен.

**Фикс — AES-GCM:**
Перейти на `AES/GCM/NoPadding` со случайным IV (12 байт). Переписать методы `encrypt`/`decrypt`.

---

## [CRITICAL] #4 — Actuator `/actuator/health` в prod: `show-details: always` без авторизации

**Файл:** `application-prod.yml`

Открыт анонимам, выдает инфу о БД, Redis и диске.

**Фикс:**
Изменить на `show-details: when_authorized`. Разграничить доступ в `SecurityConfig.java`.

---

## [CRITICAL] #5 — RateLimitFilter: X-Forwarded-For spoofing

**Файл:** `config/RateLimitFilter.java`

Хедер `X-Forwarded-For` читается напрямую, что позволяет обойти лимиты. Дублирует функционал `AuthRateLimiter`.

**Фикс:**
Использовать `request.getRemoteAddr()`.

---

## [WARNING] #6 — Stripe webhook: эндпоинт требует авторизации JWT

**Файл:** `SecurityConfig.java`

`/v1/billing/webhook` не в `permitAll()`. Stripe не может его дернуть.

**Фикс:**
Добавить в `permitAll()` (проверка подписи уже реализована безопасно).

---

## [WARNING] #7 — frontend axios.ts: hardcoded localhost в prod

**Файл:** `frontend/src/shared/api/axios.ts`

В проде обращается на `localhost:8080`.

**Фикс:**
Использовать `import.meta.env.VITE_API_URL`.

---

## [WARNING] #8 — Нет лимита на размер jobDescription в AI-запросах

**Файл:** `AiApplicationRequest.java`

Нет `@Size(max = ...)` на `jobDescription`. Угроза раздувания промпта.

**Фикс:**
Добавить `@Size(max = 8000)`.

---

## [WARNING] #9 — AdminController возвращает User entity напрямую (data leak)

**Файл:** `AdminController.java`

Возвращает `User` со всеми payment-идентификаторами.

**Фикс:**
Использовать DTO.

---

## [WARNING] #10 — AiRateLimiter в памяти: делает DB-запрос на каждый вызов

**Файл:** `AiRateLimiter.java`

SQL-запрос на каждый `checkAndConsume`.

**Фикс:**
Кешировать план в Bucket4j или Redis.

---

## [INFO] #11 — Refresh token в теле ответа AuthResponse

**Файл:** `AuthService.buildAuthResponse()`

Refresh token возвращается и в cookie, и в JSON.

**Фикс:**
Убрать из JSON-тела, оставить только в HttpOnly cookie.

---

## [INFO] #12 — Refresh cookie: отсутствует Secure flag в prod

**Файл:** `AuthController.setRefreshTokenCookie()`

Нет флага `secure(true)`.

**Фикс:**
Добавить `.secure(cookieSecure)` через переменную `app.cookie.secure`.

---

## Приоритет работ
- **СЕЙЧАС**: #2 (KaspiWebhook) и #1 (SSRF), #4, #5
- **Перед релизом**: #3 (AES), #6 (Stripe Webhook), #7 (Axios), #12 (Secure Cookie)
- **Спринт 2**: Остальное.
