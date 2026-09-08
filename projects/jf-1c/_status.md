# Статус JF-1C
_Обновлено: 2026-09-08_

## Текущий уровень: 4 (Production Release v1.0.0 на GitHub)
## Следующая веха: Интеграция биллинга и оплат (WebKassa / Kaspi Pay) + Домен zhanfinance.kz
## Проведенное тестирование:
- E2E Playwright Browser: 16/16 тестов UI на живом GitHub Pages пройдены.
- Live Backend API: 34 маршрута безопасности и бизнес-логики на Fly.io пройдены.
- Live IDOR Security Audit: 15/21 тестов пройдены, выявлены 4 дефекта доступа (ADVISOR CRM/Documents, CLIENT Invoices, arial.ttf в PDF).
- Artillery Load Test: Сквозной CRUD-прогон, подтверждена стабильность при P95 < 3000ms.
## Технический долг и Баги:
- Исправление IDOR: запретить мутацию счетов клиентам (PUT `/v1/billing/invoices/{id}`)
- Ограничение роли ADVISOR режимом Read-Only в CRM и Документах
- Добавление шрифта `arial.ttf` в образ бэкенда для PDF
- Тюнинг JVM: применение `-XX:MaxMetaspaceSize=256m` при перезапуске машины Fly.io
## Блокеры:
- Оплата счета Fly.io для снятия паузы автодеплоя
- Покупка и подключение домена zhanfinance.kz через Cloudflare

