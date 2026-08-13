# Дублирование и логические дыры: MeDev (Аудит v2)

---

## [CRITICAL] #1 — subscriptionExpiresAt никогда не проверяется

**Файл:** `SubscriptionService.assertPro()`

`subscriptionExpiresAt` устанавливается, но не проверяется при доступе. Если webhook не пришёл (или Kaspi подписка истекла по времени), пользователь остаётся PRO навсегда.

**Фикс:**
Добавить проверку срока давности в `assertPro()` и автоматический downgrade (`user.setPlan(User.Plan.FREE)`). Также добавить `@Scheduled` job для batch-даунгрейда истёкших подписок.

---

## [CRITICAL] #2 — medev_link_jwt cookie: не httpOnly, не Secure

**Файл:** `OAuth2LoginSuccessHandler.java`

Кука `medev_link_jwt` ставится без флагов защиты, что позволяет украсть JWT через XSS и привязать чужой GitHub аккаунт.

**Фикс:**
Использовать `ResponseCookie` с флагами `httpOnly(true)`, `secure(true)` и `sameSite("Lax")`.

---

## [CRITICAL] #3 — parse-resume: MIME type не проверяется

**Файл:** `AiController.java` → `AiAnalysisService.parseResumePdf()`

Нет проверки типа загружаемого файла. Можно загрузить .exe или бинарный мусор, что приведет к падению PDFBox (DoS / OOM) или некорректным запросам к Groq.

**Фикс:**
Добавить проверку `file.getContentType()` и валидацию магических байт (первые 4 байта должны быть `%PDF`).

---

## [WARNING] #4 — Дублирование: 5 одинаковых сервисов для профиль-секций

**Файл:** `ExperienceService`, `SkillService`, `LanguageService`, `ProjectService`, `EducationService`

100% дублирование кода проверок принадлежности сущности. Риск рассинхронизации логики (например, забытые проверки на null).

**Фикс:**
Вынести общую логику в абстрактный базовый класс `ProfileSectionService<E, D, R>`. Делать обязательно при добавлении новых секций.

---

## [WARNING] #5 — Reorder: нет лимита на количество IDs → N UPDATE-запросов

**Файл:** `ReorderRequest.java`, все `*Service.reorder*()`

Массив ID для сортировки не ограничен по размеру. Можно прислать 10000 ID, что породит 10000 UPDATE-запросов в одной транзакции.

**Фикс:**
Добавить `@Size(max = 100)` в DTO. Для производительности переписать на batch update.

---

## [WARNING] #6 — Дублирование rate limiters: RateLimitFilter + AuthRateLimiter

Две системы конфликтуют на логине. `RateLimitFilter` уязвим к spoofing (`X-Forwarded-For`) и имеет более строгий лимит, сводя на нет надежный `AuthRateLimiter`.

**Фикс:**
Удалить `RateLimitFilter` полностью, оставить только защиту в `AuthRateLimiter`.

---

## [WARNING] #7 — Google OAuth: пустой username из email типа `+@gmail.com`

**Файл:** `CustomOAuth2UserService.java`

При очистке email-а от спецсимволов может получиться пустая строка или зарезервированное имя (`admin`).

**Фикс:**
Генерировать случайный UUID-суффикс, если строка пустая, и добавить проверку по списку `RESERVED_USERNAMES`.

---

## [WARNING] #8 — Tracker: `/scrape` не rate limited

**Файл:** `JobApplicationController.java`

Эндпоинт открывает HTTP соединение на 10 секунд. Без лимитов можно легко исчерпать thread pool сервера (DoS).

**Фикс:**
Добавить вызов `scraperRateLimiter.checkAndConsume(userId)` перед парсингом.

---

## [WARNING] #9 — 3 DB-запроса к `users` на один AI-вызов

**Файл:** `AiRateLimiter`, `SubscriptionService`, `AiContextService`

Избыточная нагрузка на БД из-за постоянных селектов одной и той же строки.

**Фикс:**
Перенести `plan` в claims JWT токена и читать оттуда (или кешировать профиль).

---

## [INFO] #10 — EvaluationService: feedback не rate limited

**Файл:** `AiController.submitFeedback()`

Защитить от спама через `@Size(max = 1000)` на текст и ограничение вызовов.

---

## [INFO] #11 — Silent fail при парсинге дат

**Файл:** `ProfileService.importParsedResume()`

При ошибке парсинга дат из JSON ответ проглатывается без логов.

**Фикс:**
Добавить `log.warn(...)` в блок catch `DateTimeParseException`.

---

## Приоритет работ
- **СЕЙЧАС (Завтра)**: #1 (Billing) и #2 (Cookie).
- **Перед релизом**: #3 (PDF Upload), #7 (OAuth).
- **Следующий спринт**: Архитектурные исправления (#4, #5, #9) и защита от спама.
