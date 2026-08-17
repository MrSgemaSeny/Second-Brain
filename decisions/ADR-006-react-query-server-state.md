# ADR-006: React Query (TanStack) для серверного состояния

**Дата:** 2026-08-17
**Статус:** Принято
**Проект:** Valeur

## Контекст
Управление состоянием в React приложениях часто делится на локальное состояние (UI state), глобальное клиентское состояние (theme, auth) и серверное состояние (данные из API). 
Исторически разработчики складывали серверные данные в глобальные хранилища типа Redux или Zustand, что требовало написания огромного количества бойлерплейта (actions, reducers, thunks, loading flags).

## Решение
Использовать `@tanstack/react-query` v5 для 100% управления серверным состоянием (fetching, caching, synchronizing and updating server state). Глобальные сторы (Zustand) оставить **строго** только для клиентского состояния (например, сессия пользователя, UI переключатели).

### Паттерн использования (FSD)
Хуки выносятся в слои `entities` или `features`. Пример:
```typescript
export const useVacancyQueries = () => {
    const getVacancies = () => useQuery({
        queryKey: ['vacancies'],
        queryFn: () => apiClient.get('/vacancies'),
    });

    const createVacancy = () => useMutation({
        mutationFn: (data: any) => apiClient.post('/vacancies', data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vacancies'] });
        },
    });

    return { getVacancies, createVacancy };
};
```

## Последствия (Trade-offs)
- **Плюсы:** 
  - Резкое сокращение бойлерплейта (из коробки доступны состояния `isLoading`, `isError`).
  - Умное кеширование и инвалидация (Stale-while-revalidate паттерн).
  - Оптимистичные обновления UI.
- **Минусы:** 
  - Требует изменения мышления разработчиков (отказ от хранения данных в Zustand).
  - Нужно следить за правильным формированием `queryKey`, чтобы не затереть чужой кеш.
