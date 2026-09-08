# Защита от IDOR (Insecure Direct Object Reference) и Матрица Доступа Сущностей

## 1. Концепция и Проблема
Уязвимость **IDOR (BOLA - Broken Object Level Authorization)** возникает, когда приложение принимает идентификатор ресурса (`/api/v1/tasks/{id}`, `/api/v1/invoices/{id}`, `/api/v1/documents/{id}`) и отдает или модифицирует данные без проверки того, принадлежит ли данный ресурс текущему аутентифицированному пользователю или его компании.

В SaaS-системах (JF-1C) IDOR в счетах или документах ведет к прямой утечке коммерческой тайны, персональных данных клиентов и возможности несанкционированного изменения финансовых статусов.

---

## 2. Матрица Доступа по Сущностям (CRM Entity Access Matrix)

В платформе действуют 4 ключевые бизнес-роли:
- **`CLIENT`** — Клиент компании (владелец бизнеса, бухгалтер клиента).
- **`EMPLOYEE`** — Штатный бухгалтер / оператор CRM.
- **`ADVISOR`** — Финансовый консультант / эксперт (Epic-19).
- **`ADMIN`** — Администратор системы.

| Сущность | Операция | CLIENT | EMPLOYEE | ADVISOR | ADMIN | Ограничение доступа (Row-Level Security) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Task (Сделка / Задача)** | READ | Свои | Назначенные / Воронка | ВСЕ | ВСЕ | `CLIENT` видит только задачи, где `task.clientId == user.clientId`. |
| | CREATE / UPDATE | Запрещено (403) | Разрешено | Запрещено (403) | Разрешено | Клиент не может переводить этапы сделок или создавать внутренние задачи. |
| | DELETE | Запрещено (403) | Запрещено (403) | Запрещено (403) | Разрешено | Удаление задач доступно строго администраторам. |
| **Invoice (Счет на оплату)** | READ | Свои | ВСЕ | ВСЕ | ВСЕ | `CLIENT` видит только счета, выставленные на его организацию (`invoice.clientId`). |
| | CREATE / UPDATE | Запрещено (403) | Разрешено | Запрещено (403) | Разрешено | Клиент ни при каких условиях не может менять сумму или статус счета (Фикс #33). |
| | DELETE | Запрещено (403) | Запрещено (403) | Запрещено (403) | Разрешено | Удаление финансовых проводок ограничено `ADMIN`. |
| **Document (Документ)** | READ / DOWNLOAD | Свои | ВСЕ | ВСЕ | ВСЕ | Скачивание файла разрешено только владельцу документа (`clientId`) или сотрудникам. |
| | UPLOAD | В свою папку | Разрешено | Запрещено (403) | Разрешено | Клиент может загружать только первичные документы со своим `clientId`. |
| | DELETE | Запрещено (403) | Запрещено (403) | Запрещено (403) | Разрешено | Удаление официальных документов запрещено клиентам и сотрудникам. |

---

## 3. Архитектура Проверки Доступа (CrmAccessService & InvoiceAccessService)

Проверка прав вынесена в выделенные доменные сервисы доступа:
```java
@Service("crmAccess")
@RequiredArgsConstructor
public class CrmAccessService {

    public boolean canReadTask(Long taskId, CustomUserDetails currentUser) {
        if (currentUser.hasRole(Role.ADMIN) || currentUser.hasRole(Role.ADVISOR)) {
            return true; // Полный аудит/консалтинг
        }
        Task task = taskRepository.findById(taskId).orElse(null);
        if (task == null) return false;

        if (currentUser.hasRole(Role.CLIENT)) {
            return Objects.equals(task.getClient().getId(), currentUser.getClientId());
        }
        return true; // EMPLOYEE
    }
}
```

Контроллеры защищаются декларативными аннотациями:
```java
@GetMapping("/{id}")
@PreAuthorize("@crmAccess.canReadTask(#id, principal)")
public ResponseEntity<TaskDto> getTaskById(@PathVariable Long id) { ... }
```

---

## 4. Автоматизированные Тесты на Защиту от IDOR

Тестовый сьют `EntityIdorSecurityTest` гарантирует строгую изоляцию клиентов друг от друга:

```java
@SpringBootTest
@AutoConfigureMockMvc
class EntityIdorSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(username = "client_a@test.kz", roles = {"CLIENT"})
    void clientCannotReadOtherClientTask() throws Exception {
        Long taskOfClientB = 202L;

        // Попытка Клиента А получить задачу Клиента Б обязана вернуть 403 Forbidden
        mockMvc.perform(get("/api/v1/tasks/{id}", taskOfClientB))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "client_a@test.kz", roles = {"CLIENT"})
    void clientCannotDownloadOtherClientDocument() throws Exception {
        Long docOfClientB = 505L;

        mockMvc.perform(get("/api/v1/documents/{id}/download", docOfClientB))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "client_a@test.kz", roles = {"CLIENT"})
    void clientCannotMutateInvoiceAmountOrStatus() throws Exception {
        Long invoiceOfClientA = 101L;
        String updatePayload = "{\"amount\": 1.00, \"status\": \"PAID\"}";

        // Даже для своего счета клиент не имеет прав на PUT/POST мутации
        mockMvc.perform(put("/api/v1/invoices/{id}", invoiceOfClientA)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updatePayload)
                .with(csrf()))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "advisor@test.kz", roles = {"ADVISOR"})
    void advisorHasReadOnlyAccessToAllEntitiesAndCannotMutate() throws Exception {
        Long anyTaskId = 202L;

        // Чтение разрешено
        mockMvc.perform(get("/api/v1/tasks/{id}", anyTaskId))
                .andExpect(status().isOk());

        // Мутация запрещена
        mockMvc.perform(put("/api/v1/tasks/{id}", anyTaskId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\": \"Hacked\"}")
                .with(csrf()))
                .andExpect(status().isForbidden());
    }
}
```

---

## 5. Результаты Live Security Аудита Прода (2026-09-08)

В ходе прогона сквозного security-сьюта `tests/e2e/idor-live.mjs` по боевому серверу `https://zhanfinance.fly.dev/api` выявлены следующие критические несоответствия матрице доступа:
1. **PUT `/api/v1/crm/tasks/{id}`**: Роль `ADVISOR` смогла успешно модифицировать задачу (получен статус 200 вместо 403). В `CrmAccessService.canUpdateTaskDetails` консультанту ошибочно возвращается `true`.
2. **DELETE `/api/v1/documents/{id}`**: Роль `ADVISOR` смогла удалить чужой документ (200 вместо 403) из-за избыточных прав в `DocumentAccessService.canWrite`.
3. **PUT `/api/v1/billing/invoices/{id}`**: Роль `CLIENT` смогла модифицировать параметры инвойса (200 вместо 403). Требуется строгая проверка `@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")` без исключений для владельца счета.
4. **GET `/api/v1/billing/invoices/{id}/pdf`**: Падение сервиса в HTTP 500 (`Font file arial.ttf not found in resources`), делающее невозможным скачивание счетов в рантайме.

