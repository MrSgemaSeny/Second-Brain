# 2026-08-13: Исправление роута в SuccessPage.tsx

## Сделано
- В файле `frontend/src/pages/billing/SuccessPage.tsx` исправлен путь запроса с `'/v1/billing/status'` на `'/billing/status'`.
- Ошибка `NoResourceFoundException: No static resource v1/v1/billing/status` происходила из-за того, что базовый URL в инстансе `axios` уже включает в себя префикс `/api/v1`, и в итоге запрос шел на `/api/v1/v1/billing/status`.
- Теперь компонент успешно поллит статус биллинга без дублирования `/v1`.
