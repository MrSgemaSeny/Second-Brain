# Архитектура: Ограничения Базы Данных (Postgres Constraints) vs Spring Validation и Тестирование Целостности

## 1. Проблема: Ложное чувство безопасности Spring Bean Validation

Многие разработчики полагают, что аннотации `@NotNull`, `@NotBlank` и `@Size` в DTO полностью защищают систему от некорректных данных. Это опасное заблуждение:

| Сценарий | Spring `@Valid` | PostgreSQL Constraint | Последствия без ограничения в БД |
| :--- | :--- | :--- | :--- |
| **HTTP-запрос в контроллер** | Работает (400 Bad Request) | Срабатывает при коммите | Защищено на входе. |
| **Внутренний сервис / Scheduled Job** | **НЕ работает** (нет контроллера) | Работает (ROLLBACK) | Появление NULL в критических полях (`created_by`, `status`). |
| **Параллельная регистрация (Race Condition)** | **НЕ работает** (`existsBy` вернет `false` обоим) | Работает (`UNIQUE INDEX`) | Дублирование email, крах авторизации. |
| **Прямой SQL / Миграция Flyway** | **НЕ работает** | Работает | Неконсистентность данных. |
| **Удаление родителя (Каскад связей)** | **НЕ работает** | Работает (`FK ON DELETE RESTRICT`) | Появление записей-сирот (Orphaned rows) в счетах/задачах. |
| **Отрицательные финансовые суммы** | Работает только если прописан `@Positive` | Работает (`CHECK (amount >= 0)`) | Дыра в биллинге. |

---

## 2. Ключевые Ограничения PostgreSQL в SaaS CRM (JF-1C)

1. **NOT NULL:** Все критические связи обязаны быть жестко зафиксированы в DDL (`client_id NOT NULL`, `created_by NOT NULL`). *Пример инцидента C4 из аудита:* миграция `V107` пыталась вставить NULL в `courses.created_by`, что ломало чистую инициализацию базы.
2. **UNIQUE:** Ограничение уникальности индексами для предотвращения гонок (`email`, `token_hash`, `company_bin`, `task_number`).
3. **FOREIGN KEY + ON DELETE RESTRICT:** Запрет удаления клиентов или курсов, если к ним привязаны финансовые проводки или активные задачи:
   ```sql
   ALTER TABLE invoices 
   ADD CONSTRAINT fk_invoices_client 
   FOREIGN KEY (client_id) REFERENCES clients(id) 
   ON DELETE RESTRICT;
   ```
4. **CHECK Constraints:** Валидация диапазонов на уровне диска:
   ```sql
   ALTER TABLE invoices ADD CONSTRAINT chk_invoice_amount_positive CHECK (amount > 0);
   ALTER TABLE subscriptions ADD CONSTRAINT chk_sub_dates CHECK (end_date >= start_date);
   ```

---

## 3. Автоматизированные Тесты Ограничений СУБД (Postgres Integrity Tests)

Тесты выполняются на реальном PostgreSQL (Testcontainers) и подтверждают, что база данных гарантированно отклоняет неконсистентные данные, выбрасывая `DataIntegrityViolationException`.

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test-pg")
class DatabaseConstraintIntegrityTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRejectNullInMandatoryAuditFields() {
        // Попытка вставки задачи без обязательного поля created_by_id на уровне БД
        Task taskWithoutCreator = Task.builder()
                .title("Deal without creator")
                .status("OPEN")
                .build();

        assertThatThrownBy(() -> {
            entityManager.persistAndFlush(taskWithoutCreator);
        })
        .isInstanceOf(PersistenceException.class)
        .hasCauseInstanceOf(ConstraintViolationException.class);
    }

    @Test
    void shouldEnforceUniqueIndexOnUserEmailUnderDirectInsert() {
        // Первый пользователь сохраняется успешно
        jdbcTemplate.update("INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)",
                "unique_test@zhanfinance.kz", "hash1", "CLIENT");

        // Попытка вставить дубликат напрямую в БД обязана быть заблокирована уникальным индексом
        assertThatThrownBy(() -> {
            jdbcTemplate.update("INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)",
                    "unique_test@zhanfinance.kz", "hash2", "EMPLOYEE");
        })
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("uk_users_email");
    }

    @Test
    void shouldPreventDeletingClientWithExistingInvoicesViaForeignKeyRestrict() {
        // Создаем клиента и выставляем ему счет
        Long clientId = insertTestClient("ТОО Тест");
        Long invoiceId = insertTestInvoice(clientId, 50000.0);

        // Попытка удалить клиента при наличии связанных счетов обязана блокироваться СУБД
        assertThatThrownBy(() -> {
            jdbcTemplate.update("DELETE FROM clients WHERE id = ?", clientId);
        })
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("fk_invoices_client");

        // Клиент обязан остаться в базе
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM clients WHERE id = ?", Integer.class, clientId);
        assertThat(count).isEqualTo(1);
    }

    @Test
    void shouldRejectNegativeInvoiceAmountViaCheckConstraint() {
        Long clientId = insertTestClient("ТОО Ромашка");

        // Попытка записать отрицательную сумму счета в обход валидаторов
        assertThatThrownBy(() -> {
            jdbcTemplate.update("INSERT INTO invoices (client_id, amount, status) VALUES (?, ?, ?)",
                    clientId, -1000.00, "ISSUED");
        })
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("chk_invoice_amount_positive");
    }
}
```
