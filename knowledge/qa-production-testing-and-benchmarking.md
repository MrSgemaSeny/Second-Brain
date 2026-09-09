# Производственное тестирование и бенчмаркинг (Testing & QA Suite)

Практическое руководство по сквозному обеспечению качества веб-платформ на базе боевого опыта ZhanFinance и MeDev.

---

## 1. Нагрузочное тестирование с утилитой Artillery

### 1.1. Взвешенные сценарии (Weighted Scenarios)
В боевых условиях нагрузка распределяется неравномерно: 70% пользователей читают публичные страницы, 20% работают с задачами в CRM, 10% создают документы или запускают генерацию PDF.

```yaml
config:
  target: "https://zhanfinance.fly.dev"
  phases:
    - duration: 60
      arrivalRate: 5
      rampTo: 30
      name: "Ramp-up to peak"
    - duration: 30
      arrivalRate: 35
      name: "Sustained high load"
  plugins:
    expect: {}

scenarios:
  - name: "Public Catalog & Health (70%)"
    weight: 70
    flow:
      - get:
          url: "/api/actuator/health"
          expect:
            - statusCode: 200
      - get:
          url: "/api/v1/services"
          expect:
            - statusCode: 200

  - name: "Authenticated Task Workflow (20%)"
    weight: 20
    flow:
      - post:
          url: "/api/v1/auth/login"
          json:
            email: "employee@zhanfinance.kz"
            password: "SecurePassword123"
          capture:
            - json: "$.accessToken"
              as: "token"
      - get:
          url: "/api/v1/crm/tasks"
          headers:
            Authorization: "Bearer {{ token }}"
          expect:
            - statusCode: 200

  - name: "Document Generation & PDF (10%)"
    weight: 10
    flow:
      - get:
          url: "/api/v1/billing/invoices/101/pdf"
          headers:
            Authorization: "Bearer {{ token }}"
          ifFalse: "token == undefined"
          expect:
            - statusCode: 200
```

### 1.2. Capture и Условные переходы (`ifFalse`)
- `capture`: извлечение `accessToken` или идентификаторов созданных сущностей (`$.id`) в переменные Artillery для последующих шагов цепочки.
- `ifFalse`: защита от выполнения зависимых шагов (например, скачивания файла или модификации статуса), если предыдущий шаг авторизации завершился неудачей или rate limit блокировкой.

---

## 2. Сквозное E2E тестирование в реальном браузере (Playwright)

### 2.1. Мультиролевые аутентифицированные сценарии (Authenticated User Journeys)
Тестирование проводится против боевого фронтенда (GitHub Pages) и боевого API (Fly.io) в headless Chrome:

```javascript
import { test, expect } from '@playwright/test';

test.describe('Multi-Role CRM Flows', () => {

  test('ADMIN: dashboard metrics and task management', async ({ page }) => {
    await page.goto('https://mrsgemaseny.github.io/JF-1C/login');
    await page.fill('input[type="email"]', 'admin@zhanfinance.kz');
    await page.fill('input[type="password"]', process.env.ADMIN_PASSWORD);
    await page.click('button[type="submit"]');

    // Проверка редиректа в админ-панель
    await expect(page).toHaveURL(/.*\/admin/);
    await expect(page.locator('text=Сводный отчет')).toBeVisible();

    // Проверка перехода в Kanban задач
    await page.click('a[href="#/admin/tasks"]');
    await expect(page.locator('.kanban-board')).toBeVisible();
  });

  test('CLIENT: read-only documents and invoices access', async ({ page }) => {
    await page.goto('https://mrsgemaseny.github.io/JF-1C/login');
    await page.fill('input[type="email"]', 'client@test.com');
    await page.fill('input[type="password"]', 'ClientPass123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/.*\/client/);
    await page.click('a[href="#/client/documents"]');
    // Проверка отсутствия кнопки удаления для роли CLIENT
    await expect(page.locator('button:has-text("Удалить документ")')).toHaveCount(0);
  });
});
```

---

## 3. Интеграционный слой бэкенда (JUnit 5 + Mockito + MockMvc)

### 3.1. Архитектура интеграционного теста контроллера
Тест поднимает веб-контекст с изолированными моками сервисов или in-memory базой данных:

```java
@WebMvcTest(controllers = TaskController.class)
@AutoConfigureMockMvc(addFilters = false) // или с фильтрами для проверки безопасности
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskService taskService;

    @MockBean
    private CrmAccessService crmAccessService;

    @Test
    @WithMockUser(username = "advisor", roles = {"ADVISOR"})
    void updateTask_asAdvisor_shouldReturnForbidden() throws Exception {
        doThrow(new AccessDeniedException("Advisors have read-only access"))
            .when(crmAccessService).assertCanUpdateTask(any(), any());

        mockMvc.perform(put("/api/v1/crm/tasks/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Updated Task\"}"))
            .andExpect(status().isForbidden());
    }
}
```

---

## 4. Фронтенд тестирование (Vitest + React Testing Library)

### 4.1. Тестирование компонентов и хуков
- Быстрый запуск тестов без тяжелого браузерного контекста (Node / JSDOM).
- Тестирование состояний загрузки, отображения ошибок и корректности рендеринга данных из React Query кэша.

```typescript
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { TaskCard } from './TaskCard';

test('renders task card with status badge and title', () => {
  const queryClient = new QueryClient();
  const mockTask = { id: 1, title: 'Сдать налоговую форму 910', status: 'IN_PROGRESS' };

  render(
    <QueryClientProvider client={queryClient}>
      <TaskCard task={mockTask} />
    </QueryClientProvider>
  );

  expect(screen.getByText('Сдать налоговую форму 910')).toBeInTheDocument();
  expect(screen.getByText('В работе')).toHaveClass('badge-in-progress');
});
```

---

## 5. IDOR тест-кейсы через перекрёстные аккаунты (Cross-Account Matrix)

### 5.1. Методология
Создаются два независимых пользователя одной роли (`Client A` и `Client B`) и одна сущность, принадлежащая `Client A`:
1. `Client A` создает ресурс `Resource A1` -> получает `201 Created` с ID `100`.
2. `Client B` выполняет `GET /api/v1/resources/100` -> **Ожидается HTTP 403 Forbidden**.
3. `Client B` выполняет `PUT /api/v1/resources/100` -> **Ожидается HTTP 403 Forbidden**.
4. `Client B` выполняет `DELETE /api/v1/resources/100` -> **Ожидается HTTP 403 Forbidden**.
5. Анонимный запрос без токена -> **Ожидается HTTP 401 Unauthorized**.

Только при прохождении всех 5 проверок сущность считается защищенной от IDOR.
