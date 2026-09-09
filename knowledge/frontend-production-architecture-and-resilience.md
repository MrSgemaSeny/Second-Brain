# Архитектура и отказоустойчивость фронтенда (Frontend Production Architecture)

Свод правил проектирования клиентских веб-приложений на React 19, TypeScript и Vite.

---

## 1. Методология Feature-Sliced Design (FSD)

Архитектура строго разделена на слои с однонаправленным потоком зависимостей (сверху вниз):
- **`app/`**: Инициализация приложения, глобальные контексты (`QueryClientProvider`, `AuthProvider`), корневой роутер, глобальные стили.
- **`pages/`**: Маршрутные экраны с композицией виджетов. Содержат минимум бизнес-логики.
- **`widgets/`**: Крупные самодостаточные блоки интерфейса (`DashboardLayout`, `KanbanBoard`, `ResumeBuilder`, `Sidebar`).
- **`features/`**: Пользовательские интерактивные сценарии (`TaskAssignModal`, `InvoiceCreateForm`, `GenerateSummaryButton`).
- **`entities/`**: Бизнес-сущности системы (`Task`, `User`, `Invoice`, `Document`, `Course`) — типы, модели, UI-карточки, API-запросы.
- **`shared/`**: Переиспользуемый базис, не знающий о специфике домена: UI-кит (Button, Modal, Input, Spinner), утилиты, HTTP-клиент, конфигурация роутов.

---

## 2. React Query: Префиксные ключи запросов (Structured Query Keys)

### 2.1. Фабрика ключей (Query Key Factory)
Для избежания опечаток и надежной точечной инвалидации кэша ключи организуются в структурированные фабрики:

```typescript
export const taskKeys = {
  all: ['tasks'] as const,
  lists: () => [...taskKeys.all, 'list'] as const,
  list: (filter: TaskFilter) => [...taskKeys.lists(), filter] as const,
  details: () => [...taskKeys.all, 'detail'] as const,
  detail: (id: number) => [...taskKeys.details(), id] as const,
};
```

### 2.2. Применение при мутациях
При успешном изменении задачи инвалидируются только списки задач, не затрагивая независимые кэши:
```typescript
const queryClient = useQueryClient();

const mutation = useMutation({
  mutationFn: updateTaskStage,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: taskKeys.lists() });
  },
});
```

---

## 3. Стейт-менеджмент: Zustand Store

- Использование легковесного Zustand для глобального состояния клиента (авторизация, тема, выбранный фильтр).
- Избежание перерендеров через селекторы:
  ```typescript
  const user = useAuthStore(state => state.user);
  const isAuthenticated = useAuthStore(state => state.isAuthenticated);
  ```
- Персистентность в `localStorage` подключается избирательно через middleware `persist`, чувствительные токены (Access Token) хранятся strictly in-memory.

---

## 4. JWT Refresh Singleton (Дедупликация запросов на обновление токена)

### 4.1. Проблема лавины 401
При одновременном выполнении нескольких API-запросов с истекшим Access-токеном каждый запрос получает ошибку 401 и пытается вызвать `/api/v1/auth/refresh`.

### 4.2. Решение: Синглтон-промис (refreshPromise) в HTTP-клиенте
```typescript
let refreshPromise: Promise<string> | null = null;

async function refreshAccessToken(): Promise<string> {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const response = await fetch('/api/v1/auth/refresh', {
          method: 'POST',
          credentials: 'include', // HttpOnly refresh cookie
        });
        if (!response.ok) throw new Error('Refresh failed');
        const data = await response.json();
        setInMemoryAccessToken(data.accessToken);
        return data.accessToken;
      } finally {
        refreshPromise = null; // Сброс синглтона после завершения
      }
    })();
  }
  return refreshPromise;
}
```
Все последующие параллельные запросы ожидают завершения одного и того же `refreshPromise` и повторяют свои вызовы с новым токеном.

---

## 5. Конфигурация CSP для безопасного превью PDF

### 5.1. Симптомы блокировки
Использование `iframe src="blob:https://..."` при стандартном заголовке `default-src 'self'` приводит к ошибке:
`Framing 'blob:...' violates Content Security Policy: default-src 'self'`.

### 5.2. Решение:
1. Дополнение CSP директивами:
   ```text
   frame-src 'self' blob: data:; child-src 'self' blob: data:;
   ```
2. Разрешение отображения во фреймах своего домена:
   ```text
   X-Frame-Options: SAMEORIGIN
   ```
3. Использование `srcDoc` в React-компоненте для прямого инлайн-рендеринга HTML:
   ```tsx
   <iframe 
     srcDoc={htmlContent} 
     title="Document Preview" 
     className="w-full h-full border-0" 
   />
   ```

---

## 6. Отказоустойчивое разделение кода (lazyWithRetry)

При обновлении продакшена старые чанки JS в браузере пользователя могут возвращать 404 ChunkLoadError.
Обычный `React.lazy` приводит к белому экрану (White Screen of Death).

### Реализация:
```typescript
export function lazyWithRetry<T extends React.ComponentType<any>>(
  componentImport: () => Promise<{ default: T }>
) {
  return React.lazy(async () => {
    const pageHasAlreadyBeenRefreshed = JSON.parse(
      window.sessionStorage.getItem('page-has-been-force-refreshed') || 'false'
    );

    try {
      const component = await componentImport();
      window.sessionStorage.setItem('page-has-been-force-refreshed', 'false');
      return component;
    } catch (error) {
      if (!pageHasAlreadyBeenRefreshed) {
        // При ошибке загрузки чанка делаем 1 автоматическую перезагрузку страницы
        window.sessionStorage.setItem('page-has-been-force-refreshed', 'true');
        window.location.reload();
      }
      throw error;
    }
  });
}
```
