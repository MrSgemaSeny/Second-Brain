# Нативный Fetch с перехватом 401 (Refresh Token)

**Проект:** Valeur (Frontend)

Для полного отказа от Axios используется кастомный интерсептор на базе `fetch`. Его главная задача: 
1. Подставлять `Authorization: Bearer <token>` к каждому запросу.
2. Ловить статус `401 Unauthorized`.
3. В случае 401 прозрачно делать запрос на `/api/auth/refresh`, получать новый токен.
4. Повторять оригинальный запрос с новым токеном.

## Реализация (apiClient.ts)

```typescript
export class ApiError extends Error {
    public status: number;
    public data: any;
    // ... constructor
}

async function handleResponse(response: Response) {
    if (!response.ok) {
        // ... парсинг ошибки
        throw new ApiError(response.status, errorData);
    }
    if (response.status === 204) return null;
    return response.json();
}

async function refreshAccessToken() {
    const response = await fetch('/api/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'true' // если используется HttpOnly Cookie для Refresh токена
    });
    
    const data = await handleResponse(response);
    if (data?.accessToken) {
        localStorage.setItem('access_token', data.accessToken);
        return data.accessToken;
    }
    throw new Error('No access token returned');
}

export const apiClient = async (endpoint: string, options: RequestInit = {}) => {
    const headers = new Headers(options.headers);
    
    if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
        headers.set('Content-Type', 'application/json');
    }
    
    let token = localStorage.getItem('access_token');
    if (token) headers.set('Authorization', `Bearer ${token}`);
    
    const config: RequestInit = { ...options, headers };
    
    // 1. Первый вызов
    let response = await fetch(`/api${endpoint}`, config);
    
    // 2. Ловим 401 (Токен протух)
    if (response.status === 401) {
        try {
            // Запрашиваем новый
            token = await refreshAccessToken();
            headers.set('Authorization', `Bearer ${token}`);
            // 3. Повторяем оригинальный запрос
            response = await fetch(`/api${endpoint}`, { ...config, headers });
        } catch (e) {
            // Если рефреш не удался (протух и refresh токен) -> жесткий разлогин
            localStorage.removeItem('access_token');
            window.location.href = '/login';
            throw e;
        }
    }
    
    return handleResponse(response);
};

// Aliases
apiClient.get = (endpoint, options) => apiClient(endpoint, { ...options, method: 'GET' });
apiClient.post = (endpoint, body, options) => apiClient(endpoint, { ...options, method: 'POST', body: JSON.stringify(body) });
```

> [!TIP]
> В сложной версии этого интерсептора, если несколько запросов параллельно упадут с 401, может возникнуть "гонка" вызовов `/refresh`. Решается это введением переменной `isRefreshing` и массива `failedQueue` для ожидания выдачи токена. В Valeur пока используется базовый вариант.
