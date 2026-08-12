# Zustand Persist и Access Token

## Проблема
При использовании Zustand middleware `persist` для сохранения стейта авторизации, разработчики часто исключают `accessToken` из сохраняемых полей через функцию `partialize` (оставляя только `username`, `plan` и сохраняя `refreshToken` отдельно).

Следствие: при обновлении страницы (F5) стейт инициализируется с `accessToken: null`.
Роутер (например, `PrivateRoute`), проверяющий наличие `accessToken`, видит `null` и синхронно редиректит пользователя на `/login`. Это происходит ДО того, как любые API-запросы успевают отработать и упасть с 401 ошибкой, что полностью ломает механику Axios interceptor'а для автоматического рефреша токена.

## Решение
Добавлять `accessToken` в `partialize` стейта `zustand/persist`:
```typescript
partialize: (state) => ({ 
  accessToken: state.accessToken, 
  username: state.username, 
  plan: state.plan 
})
```
Таким образом, `accessToken` восстанавливается из localStorage мгновенно. Роутер пропускает пользователя. Если токен уже истёк — первый же запрос на бэкенд вернёт `401 Unauthorized`, который перехватит Axios interceptor и бесшовно обновит токен с помощью `refreshToken`.
