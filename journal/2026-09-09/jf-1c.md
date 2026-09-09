# Журнал: JF-1C (ZhanFinance)
Дата: 2026-09-09

## Отчет по статусу исправления 4 уязвимостей и деплою

### 1. Статус исправления уязвимостей в кодовой базе
Все 4 уязвимости, выявленные в ходе сквозного аудита безопасности, полностью устранены в исходном коде, проверены автоматическими тестами и зафиксированы в ветке `main` (коммиты `a497bda` и `a1fa33c`):

1. **[HIGH] CLIENT может изменить сумму/статус чужого Invoice через PUT**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `CLIENT` удалена из методов `canWrite` и `canCreateFor` в `InvoiceAccessService.java`. Создавать и изменять инвойсы разрешено только `ADMIN` и `EMPLOYEE`. В `InvoiceController.java` и `InvoiceService.java` реализован метод `GET /api/v1/invoices/{id}` с предикатом `assertCanRead` — клиент видит строго свои счета, чужие блокируются с `403 Forbidden`.

2. **[HIGH] ADVISOR может мутировать Task (должен быть Read-Only)**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `ADVISOR` исключена из `CrmAccessService.canUpdateTaskDetails` и из аннотации безопасности `@PreAuthorize` на методе `updateTaskDetails` (`PUT /v1/crm/tasks/{id}`) в `TaskController.java`. Советник переведен в режим строгого Read-Only наблюдения.

3. **[HIGH] ADVISOR может удалить Document (должен быть Read-Only)**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: Роль `ADVISOR` исключена из `DocumentAccessService.canWrite` и `canCreateFor`. Советник имеет доступ только на чтение и скачивание документов, удаление и создание блокируются с `403 Forbidden`.

4. **[MEDIUM] PDF Invoice возвращает 500 — отсутствует шрифт arial.ttf**:
   - Статус: **ИСПРАВЛЕНО**.
   - Решение: В `PdfGeneratorService.java` добавлена безопасная проверка доступности ресурса `/fonts/arial.ttf` в classpath (`getResourceAsStream`). Если шрифт отсутствует в контейнере, генератор не падает с необработанным исключением 500, а использует встроенные шрифты рендерера.

5. **Сопутствующие критические исправления целостности**:
   - LMS Course Deletion: В `CourseService.deleteCourse` добавлена каскадная очистка записей прогресса, зачислений и сертификатов перед удалением сущности курса, что исключило ошибки внешних ключей PostgreSQL (`fk_enrollments_course_id`).
   - LMS Chapter ID: В `CourseService.createChapter` добавлено сохранение через `chapterRepository.save(chapter)` для гарантии возврата сгенерированного ID в API-ответе.
   - HTTP 405 Method Not Allowed: В `GlobalExceptionHandler.java` добавлен обработчик `HttpRequestMethodNotSupportedException` вместо падения в 500.

### 2. Результаты тестов
- Backend: 169 тестов JUnit 5 — 100% green (`./gradlew.bat test --rerun-tasks`).
- Frontend: 74 теста Vitest — 100% green (`npm test -- --run`).
- E2E Lifecycle: 9 сьютов полного цикла (`tests/run-all-e2e.mjs`) пройдены успешно.
- CI/CD: Шаг сборки и тестов `Build and Test` в GitHub Actions завершился успешно.

### 3. Причина статуса "ожидают деплоя" на проде
- Изменения запушены в репозиторий GitHub в ветку `main`.
- Пайплайн автоматического деплоя `.github/workflows/deploy-backend.yml` успешно скомпилировал проект и прогнал все тесты, но упал на шаге `flyctl deploy --remote-only` с ошибкой:
  `ensure depot builder failed (status 403): Your account has overdue invoices. Please update your payment information: https://fly.io/dashboard/orka-best/billing`
- Боевой контейнер на Fly.io пока работает на предыдущем образе. Как только учетная запись на Fly.io будет разблокирована (оплачен счет в биллинге), запуск деплоя автоматически применит готовые фиксы на проде.
