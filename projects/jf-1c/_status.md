# Статус JF-1C
_Обновлено: 2026-09-08_

## Текущий уровень: 4 (Production Release v1.0.0 на GitHub)
## Следующая веха: Интеграция биллинга и оплат (WebKassa / Kaspi Pay) + Домен zhanfinance.kz
## Проведенное тестирование:
- Full Lifecycle E2E: 5 боевых сьютов бизнес-логики (CRM, LMS, Chat, Documents, Invoices) — 45/45 тестов (100% PASS).
- Playwright Authenticated Journeys: 17/17 тестов в реальном браузере (Admin, Employee, Client) пройдены.
- E2E Playwright Browser: 16/16 тестов публичного UI на живом GitHub Pages пройдены.
- Live Backend API: 34 маршрута безопасности и бизнес-логики на Fly.io пройдены.
- Live IDOR Security Audit: 15/21 тестов пройдены, выявлены 4 дефекта доступа (ADVISOR CRM/Documents, CLIENT Invoices, arial.ttf в PDF).
- Artillery Load Test: Сквозной CRUD-прогон, подтверждена стабильность при P95 < 3000ms.
## Устраненные Дефекты и Уязвимости:
- Исправлен IDOR: запрещена мутация счетов клиентам (PUT `/v1/billing/invoices/{id}`), добавлен безопасный эндпоинт `GET /v1/billing/invoices/{id}` с `assertCanRead`.
- Роль ADVISOR изолирована в режим строгого Read-Only в CRM и Документах (запрещены мутации задач и удаление/создание документов).
- Исправлена отказоустойчивость PDF: безопасная проверка наличия `arial.ttf` в classpath исключает 500 ошибку при отсутствии файла.
- Исправлена реляционная целостность LMS: каскадное удаление прогресса, зачислений и сертификатов при удалении курса.
- Гарантирована генерация ID глав курсов: явное сохранение `chapterRepository.save(chapter)`.
## Технический долг:
- Тюнинг JVM: применение `-XX:MaxMetaspaceSize=256m` при следующем рестарте контейнера Fly.io.
## Блокеры:
- Оплата счета Fly.io для снятия паузы автодеплоя
- Покупка и подключение домена zhanfinance.kz через Cloudflare

