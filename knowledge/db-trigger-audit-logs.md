# PostgreSQL Trigger-Based Audit Logs: Защита и Тестирование Иммутабельности

## Обзор и Бизнес-Критичность
В финансовых и CRM-системах (JF-1C) аудит-лог является юридически значимым источником правды. Любая возможность изменения (`UPDATE`), удаления (`DELETE`) или очистки (`TRUNCATE`) записей аудита — даже со стороны администратора базы данных или скомпрометированного сервисного пользователя — представляет собой критическую уязвимость комплаенса и целостности данных.

Для обеспечения свойства **WORM (Write Once, Read Many)** защита аудит-логов реализуется на уровне СУБД PostgreSQL с помощью неизменяемых триггеров.

---

## 1. DDL-миграция триггеров PostgreSQL

Триггеры устанавливаются на операции изменения строк и таблицы целиком:

```sql
-- 1. Функция блокировки модификаций
CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'UPDATE, DELETE and TRUNCATE on audit tables are strictly prohibited by compliance policy'
        USING ERRCODE = 'integrity_constraint_violation';
END;
$$ LANGUAGE plpgsql;

-- 2. Триггер запрета UPDATE (на каждую строку)
DROP TRIGGER IF EXISTS trg_audit_log_no_update ON audit_logs;
CREATE TRIGGER trg_audit_log_no_update
    BEFORE UPDATE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();

-- 3. Триггер запрета DELETE (на каждую строку)
DROP TRIGGER IF EXISTS trg_audit_log_no_delete ON audit_logs;
CREATE TRIGGER trg_audit_log_no_delete
    BEFORE DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();

-- 4. Триггер запрета TRUNCATE (на уровне таблицы)
DROP TRIGGER IF EXISTS trg_audit_log_no_truncate ON audit_logs;
CREATE TRIGGER trg_audit_log_no_truncate
    BEFORE TRUNCATE ON audit_logs
    FOR EACH STATEMENT EXECUTE FUNCTION prevent_audit_modification();
```

---

## 2. Архитектура интеграционного тестирования иммутабельности

### Ограничения сред тестирования:
- **H2 Database не подходит:** H2 в режиме эмуляции PostgreSQL не поддерживает PL/pgSQL триггеры и не выбросит исключение при `UPDATE/DELETE`.
- **Требование:** Тестирование триггеров проводится **только на реальном PostgreSQL** (через Testcontainers `PostgreSQLContainer` или на тестовом стенде CI/CD).

### Тестовый сьют (`AuditLogImmutabilityIntegrationTest`):
Тест проверяет 4 критических сценария:
1. `INSERT` успешно фиксирует запись.
2. `UPDATE` блокируется на уровне СУБД с откатом транзакции.
3. `DELETE` блокируется на уровне СУБД.
4. `TRUNCATE` блокируется на уровне всей таблицы.

```java
@SpringBootTest
@Testcontainers
@ActiveProfiles("test-pg")
class AuditLogImmutabilityIntegrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AuditLogRepository auditLogRepository;

    private Long auditId;

    @BeforeEach
    void setUp() {
        // Добавление эталонной записи разрешено
        AuditLog entry = AuditLog.builder()
                .action("TASK_CREATE")
                .entityName("Task")
                .entityId(101L)
                .actorEmail("employee@zhanfinance.kz")
                .createdAt(Instant.now())
                .build();
        auditId = auditLogRepository.save(entry).getId();
        assertThat(auditId).isNotNull();
    }

    @Test
    void shouldFailWhenAttemptingDirectUpdate() {
        // Попытка прямого SQL UPDATE обязана выбросить DataIntegrityViolationException
        assertThatThrownBy(() -> 
            jdbcTemplate.update("UPDATE audit_logs SET action = 'TAMPERED' WHERE id = ?", auditId)
        )
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("UPDATE, DELETE and TRUNCATE on audit tables are strictly prohibited");

        // Проверяем, что в базе запись осталась неизменной
        String currentAction = jdbcTemplate.queryForObject(
                "SELECT action FROM audit_logs WHERE id = ?", String.class, auditId);
        assertThat(currentAction).isEqualTo("TASK_CREATE");
    }

    @Test
    void shouldFailWhenAttemptingDirectDelete() {
        // Попытка SQL DELETE обязана быть отклонена триггером
        assertThatThrownBy(() -> 
            jdbcTemplate.update("DELETE FROM audit_logs WHERE id = ?", auditId)
        )
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("strictly prohibited");

        // Запись обязана физически остаться в таблице
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM audit_logs WHERE id = ?", Integer.class, auditId);
        assertThat(count).isEqualTo(1);
    }

    @Test
    void shouldFailWhenAttemptingJpaRepositoryDelete() {
        // Проверка защиты через ORM Spring Data JPA
        AuditLog entry = auditLogRepository.findById(auditId).orElseThrow();
        
        assertThatThrownBy(() -> {
            auditLogRepository.delete(entry);
            auditLogRepository.flush(); // Форсируем отправку DELETE в СУБД
        })
        .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void shouldFailWhenAttemptingTruncate() {
        // Попытка очистки таблицы целиком обязана быть заблокирована
        assertThatThrownBy(() -> 
            jdbcTemplate.execute("TRUNCATE TABLE audit_logs")
        )
        .isInstanceOf(DataIntegrityViolationException.class)
        .hasMessageContaining("strictly prohibited");
    }
}
```

---

## 3. Маскирование конфиденциальных полей перед вставкой
Иммутабельность означает, что ошибочно записанные данные **нельзя исправить или затереть**. Если в лог по ошибке попадет пароль или токен, он останется в БД навсегда.

Поэтому на прикладном уровне (`AuditEntityListener`) до выполнения `INSERT` выполняется маскирование чувствительных ключей (`password`, `token`, `secret`, `refreshToken`):
```java
public String maskSensitiveJson(String payload) {
    if (payload == null) return null;
    return payload.replaceAll("(?i)\"(password|token|secret|refreshToken)\"\\s*:\\s*\"[^\"]+\"", 
                              "\"$1\":\"***MASKED***\"");
}
```
Данная логика покрывается отдельным юнит-тестом на регулярные выражения и структуры JSON.
