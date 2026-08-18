## Security Audit Fixes (Phase 10: Polish + Security)
- **Секреты:** Во всех 4 сервисах + gateway обновлён `SecretValidator.java`. Теперь требуется длина ключей `JWT_SECRET` и `INTERNAL_SERVICE_TOKEN` >= 32 символа. Обновлён `.env.example`.
- **Identity Service:** Добавлен rate limit на эндпоинт `/refresh`. Защищено чтение `X-Forwarded-For` — теперь оно доверяется только при наличии `X-Internal-Token` (то есть когда запрос прошел через Gateway).
- **Tenant Isolation & Roles:** В `TenantContextFilter` (vacancy, application, ai) добавлена строгая проверка на валидные Enum роли (`ADMIN`, `COMPANY_ADMIN`, `CANDIDATE`). Иначе — 401 Unauthorized.
- **Application Controller:** Добавлена эшелонированная защита `@PreAuthorize("hasRole('COMPANY_ADMIN')")` на методы получения списка кандидатов и обновления статуса отклика, чтобы CANDIDATE не мог даже стучаться туда (помимо защиты на уровне БД).
- **AI Service:** Добавлена защита от Prompt Injection. Строки `skills` режутся до 500 символов, `experience` — до 2000. В конец промпта добавлено системное предупреждение `[SYSTEM BOUNDARY]`. В `/health` убран провайдер (Groq) для предотвращения Information Disclosure.
- Все тесты пройдены, код отправлен в GitHub.
