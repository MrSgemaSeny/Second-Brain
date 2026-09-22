# Статус JF-1C
_Обновлено: 2026-09-22_

## Текущий уровень: 4 (Production Live / Microservice Integration)
## Следующая веха: Интеграция биллинга и оплат (WebKassa / Kaspi Pay) + Домен zhanfinance.kz
## Проведенное тестирование:
- Backend JF-1C: 295/295 тестов (100% PASS, JUnit 5, MockMvc, Spring Security, Concurrency, JaCoCo).
- Telegram Bot Microservice: 89/89 тестов (100% PASS, Adversarial, Outbox, CommandDispatcher).
- Frontend JF-1C: 172/172 тестов (100% PASS, Vitest, strict TypeScript, ESLint 9 clean).
## Устраненные Дефекты и Уязвимости:
- Единая JS-валидация и ликвидация нативных тултипов: убран `required` из `Textarea.tsx` (заменен на `aria-required`), проставлен `noValidate` во всех формах, произведена замена на компонент `<Input>` с пробросом `error`, добавлена строгая JS-валидация непустых полей и корректности email/телефонов (`ContactForm`, `UserLabelManager`, `AdminLearnersPage`, `AdminCuratorsPage`, `AdminSubscriptionsPage`, `AdminInvoicesPage`, `SettingsPage`, `TaskEditModal`, `TaskCreateModal`, `CalendarPage`).
- Документирован отдельный микросервис Telegram-бота: зафиксирован в `CONTEXT.md` и `AGENTS.md` (`zhan-finance-tgbot`, порт 8081, `/api/v1/internal/**`, `Role.INTERNAL_BOT`).
- Google Account Linking & Gmail OTP Flow: Flyway V127 (google_sub, google_email, password_set, email_verification_otps с индексами и last_sent_at). Защита от угона через регистрацию с чужим @gmail.com (требуется 6-значный OTP код), безопасное хеширование паролей в payload (BCrypt), кулдаун 60 сек, лимит 5 попыток, защита от отвязки единственного метода входа, 1-click Google auth fallback.
- P1-01 (Optimistic Locking): Flyway V126 version column во всех 26 таблицах, перехват OptimisticLockException (HTTP 409).
- P1-02 (Atomic Task Pickup): атомарный native SQL claimTask в TaskRepository, защита от race conditions в пуле задач.
- Telegram Bot UX & Error Sanitization: полная санитизация клиентских ошибок в Telegram, отсутствие утечек JSON/стеков, человечные подсказки при истечении ссылки.
- Global Exception Hardening: перехват DataIntegrityViolationException (409), MaxUploadSizeExceededException (400), MethodArgumentTypeMismatchException (400), MissingServletRequestParameterException (400), ConstraintViolationException (400).
- Брендированный QR-код Telegram: SVG-карточка в оригинальном стиле Telegram с Excavated-самолетом и автополлингом статуса привязки.
## Блокеры:
- Оплата счета Fly.io для снятия паузы автодеплоя
- Покупка и подключение домена zhanfinance.kz через Cloudflare

