# ADR-005: Нативный Fetch API вместо Axios (Frontend)

**Дата:** 2026-08-17
**Статус:** Принято
**Проект:** Valeur

## Контекст
Традиционно для React-приложений используется библиотека Axios для выполнения HTTP-запросов, так как она предоставляет удобный синтаксис, автоматическую трансформацию JSON и интерсепторы "из коробки".
Однако, современные браузеры предоставляют мощный нативный `fetch` API. В архитектуре FSD нам необходимо централизованное место для работы с сетью (`apiClient.ts`).

## Решение
Отказаться от библиотеки Axios в пользу нативного `fetch` API и написать собственный легкий `apiClient` с поддержкой перехвата ошибок и обновления токенов.

### Код-сниппет (Суть решения)
```typescript
export const apiClient = async (endpoint: string, options: RequestInit = {}) => {
    // ... инжект токена
    let response = await fetch(`/api${endpoint}`, config);
    
    // Кастомный перехват 401 для Refresh Token
    if (response.status === 401) {
        try {
            const token = await refreshAccessToken();
            headers.set('Authorization', `Bearer ${token}`);
            response = await fetch(`/api${endpoint}`, { ...config, headers });
        } catch (e) {
            localStorage.removeItem('access_token');
            window.location.href = '/login';
            throw e;
        }
    }
    
    return handleResponse(response);
};
```

## Последствия (Trade-offs)
- **Плюсы:** 
  - Минус одна зависимость (уменьшение бандла, отсутствие уязвимостей стороннего пакета).
  - Полный контроль над поведением и логикой Refresh-токенов без "магии" интерсепторов Axios, которые иногда сложно дебажить.
- **Минусы:** 
  - Приходится вручную обрабатывать выброс ошибок при `response.ok === false` (встроенный `fetch` не бросает exception на 4xx и 5xx статусы).
  - Приходится вручную прописывать `JSON.stringify` для body запросов.
