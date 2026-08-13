# 2026-08-13: Интеграция шаблона Kaspi Pay

## Сделано
- Создана миграция `V11__add_kaspi_fields.sql` для добавления поля `kaspi_customer_id`.
- Обновлена сущность `User` (поля и методы в `UserRepository`).
- Создан шаблон сервиса `KaspiPayService` для генерации ссылок на оплату и обработки webhook-уведомлений.
- Добавлены эндпоинты `/checkout/kaspi` и `/webhook/kaspi` в `BillingController`.
- Обновлена конфигурация в `application.yml` (dev, prod) для Kaspi Merchant ID и Secret Key.
- Добавлен хук `useKaspiCheckout` в `useBilling.ts` на фронтенде.
- Бэкенд успешно скомпилирован, тесты проходят.
