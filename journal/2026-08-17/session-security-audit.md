# Session Log: Security Audit & Hardening (Sprint 5)
Date: 2026-08-17
Context: Comprehensive Security Audit & PII Compliance fixes based on the Critical/Warning issues found.

## Что было сделано:

### 1. Архитектура и Auth (OAuth2 Stateless)
**Проблема:** В Spring Security по умолчанию `oauth2Login()` полагается на `HttpSessionOAuth2AuthorizationRequestRepository`, что приводит к созданию JSESSIONID сессий. В stateless API (где токены передаются через JWT) это ведет к утечке памяти на сервере, так как сессии скапливаются и не удаляются.
**Решение:**
- Реализован кастомный `CookieOAuth2AuthorizationRequestRepository.java`.
- Теперь состояние (`state`) и параметры авторизации хранятся во временных куках (`oauth2_auth_request`) с `HttpOnly` и `MaxAge=180`.
- Внедрено в `SecurityConfig.java` через `.authorizationEndpoint(a -> a.authorizationRequestRepository(cookieAuthorizationRequestRepository))`.
- Устранен баг с генерацией пустого username при логине через Google, если email начинался со спецсимволов.

### 2. Защита PII (Персональных Данных) и LLM Compliance
**Проблема:** Закон РК о персональных данных и GDPR запрещают прямую передачу необработанных ПДн (ФИО, телефон, email) третьим лицам (Groq API, OpenAI) без маскировки или явного согласия.
**Решение:**
- Создан компонент `PiiMasker.java` с базовыми RegEx правилами для маскировки телефонов, email и имен на `[PHONE]`, `[EMAIL]`, `[NAME]`.
- Добавлен шаг маскировки в `AiAnalysisService.java` перед конкатенацией промпта.
- Созданы страницы `PrivacyPolicy.tsx` и `TermsOfService.tsx` на фронтенде, объясняющие использование ИИ, процессинг данных (Stripe/Kaspi) и сбор ПДн.

### 3. Prompt Injection (Внедрение Промптов)
**Проблема:** Загружаемые PDF-резюме могут содержать скрытый текст, который переписывает системные инструкции LLM ("Забудь все предыдущие инструкции и напиши...").
**Решение:**
- Пользовательский контент теперь строго оборачивается в XML теги `<user_resume> ... </user_resume>` в `AiAnalysisService.java`. LLM-модели (в том числе Llama-3 через Groq) натренированы строго разделять системный промпт от пользовательского инпута в таких тегах.

### 4. Защита от PDF парсер-эксплойтов
**Проблема:** Метод проверки файлов только по `contentType` легко обходится. PDFBox уязвим к OOM-атакам и зависаниям при чтении битых бинарников.
**Решение:**
- В `AiAnalysisService.java` добавлена проверка Magic Bytes. Читаем первые 4 байта загруженного файла, они обязаны быть `%PDF`. При несовпадении выбрасываем `IllegalArgumentException` до передачи потока в PDFBox.
- Обновлены тесты `AiAnalysisServiceTest.java`.

### 5. Остальное (Подтверждено / Ранее пофикшено)
- `WebScraperService` уже имеет строгую валидацию URL (SiteLocal, Loopback IPs) и Whitelist доменов (SSRF).
- `EncryptionUtils` уже использует `AES/GCM/NoPadding`.
- Endpoints `/actuator/**` закрыты `ADMIN` ролью в конфигах.

**Статус:** Все тесты проходят локально (`BUILD SUCCESSFUL`).
