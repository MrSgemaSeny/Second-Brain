# Статус JF-1C
_Обновлено: 2026-09-22_

## Текущий уровень: 4 (Production Live / Microservice Integration)
## Следующая веха: Интеграция биллинга и оплат (WebKassa / Kaspi Pay) + Домен zhanfinance.kz + Google Account Linking
## Проведенное тестирование:
- Backend JF-1C: 289/289 тестов (100% PASS, JUnit 5, MockMvc, Spring Security, Concurrency, JaCoCo).
- Telegram Bot Microservice: 89/89 тестов (100% PASS, Adversarial, Outbox, CommandDispatcher).
- Frontend JF-1C: 169/169 тестов (100% PASS, Vitest, strict TypeScript, ESLint 9 clean).
## Устраненные Дефекты и Уязвимости:
- P1-01 (Optimistic Locking): Flyway V126 version column во всех 26 таблицах, перехват OptimisticLockException (HTTP 409).
- P1-02 (Atomic Task Pickup): атомарный native SQL claimTask в TaskRepository, защита от race conditions в пуле задач.
- Telegram Bot UX & Error Sanitization: полная санитизация клиентских ошибок в Telegram, отсутствие утечек JSON/стеков, человечные подсказки при истечении ссылки.
- Global Exception Hardening: перехват DataIntegrityViolationException (409), MaxUploadSizeExceededException (400), MethodArgumentTypeMismatchException (400), MissingServletRequestParameterException (400), ConstraintViolationException (400).
- Брендированный QR-код Telegram: SVG-карточка в оригинальном стиле Telegram с Excavated-самолетом и автополлингом статуса привязки.
## Блокеры:
- Оплата счета Fly.io для снятия паузы автодеплоя
- Покупка и подключение домена zhanfinance.kz через Cloudflare

