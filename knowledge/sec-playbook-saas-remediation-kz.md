# Паттерн: Защита SaaS от IDOR в биллинге и юридический комплаенс в Республике Казахстан

## 1. Проблема
В процессе разработки и подготовки SaaS-платформ к интеграции платежных систем (Kaspi Pay, Halyk Epay) и прохождения модерации регуляторов возникают типовые уязвимости:
1. **Financial IDOR / BOLA**: клиент имеет доступ к изменению суммы или статуса инвойсов через REST API (`PUT /api/v1/invoices/{id}`).
2. **Client-side Code Exposure**: сборка Vite/Webpack публикует `.map` файлы на статическом хостинге, раскрывая оригинальный исходный код и внутренние структуры данных.
3. **User Enumeration**: открытые методы проверки email (`/check-email`) или сброса пароля без строгого rate limit позволяют злоумышленникам проверять базу пользователей.
4. **Юридические риски в Казахстане**: отсутствие обязательной локализации баз данных на территории РК (ст. 12 Закона РК № 94-V), отсутствие согласий под формами и риски налоговой ответственности за ошибки клиентов.

---

## 2. Архитектурные решения

### 2.1. Строгая изоляция прав в биллинге (Invoice Access Pattern)
Клиент (`Role.CLIENT`) должен иметь право **только на чтение** своих счетов. Любая мутация статуса на `PAID` или изменение суммы счета клиентом — критическая уязвимость.

```java
// InvoiceAccessService.java
@Service
public class InvoiceAccessService {

    public boolean canRead(User actor, Invoice invoice) {
        if (actor.getRole() == Role.ADMIN) return true;
        if (actor.getRole() == Role.EMPLOYEE) {
            return assignedToEmployee(actor, invoice.getUser());
        }
        // Клиент видит только свои счета
        return actor.getRole() == Role.CLIENT && invoice.getUser().getId().equals(actor.getId());
    }

    public boolean canWrite(User actor, Invoice invoice) {
        // CLIENT полностью исключен!
        if (actor.getRole() == Role.ADMIN) return true;
        return actor.getRole() == Role.EMPLOYEE && assignedToEmployee(actor, invoice.getUser());
    }

    public boolean canCreateFor(User actor, Long clientId) {
        // Создавать счета могут только сотрудники и администраторы
        return actor.getRole() == Role.ADMIN || actor.getRole() == Role.EMPLOYEE;
    }
}
```

Контроллер защищается на уровне Spring Security:
```java
@PostMapping
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public ResponseEntity<InvoiceDto> createInvoice(@Valid @RequestBody CreateInvoiceRequest req) { ... }

@PutMapping("/{id}")
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public ResponseEntity<InvoiceDto> updateInvoice(@PathVariable Long id, @Valid @RequestBody UpdateInvoiceRequest req) { ... }

@DeleteMapping("/{id}")
@PreAuthorize("hasRole('ADMIN')")
public ResponseEntity<Void> deleteInvoice(@PathVariable Long id) { ... }
```
Статус `PAID` выставляется исключительно через:
- Обратный вызов (webhook) платежного шлюза с проверкой криптографической подписи (HMAC-SHA256).
- Ручной перевод администратором при безналичной оплате по банку.

---

### 2.2. Защита от утечки Source Maps
В `vite.config.ts`:
```ts
export default defineConfig({
  build: {
    sourcemap: false, // Запрещает генерацию .map файлов в dist/assets
  }
});
```
Если используется система мониторинга ошибок (Sentry):
- Использовать `sourcemap: 'hidden'`
- Подключать `@sentry/vite-plugin` с опцией `sourcemaps.filesToDeleteAfterUpload: ['./dist/**/*.map']`.

---

### 2.3. Изолированный Rate Limiting на перебор пользователей
Для эндпоинтов, раскрывающих наличие аккаунтов (`/auth/check-email`), настраивается независимый кэш с малым числом токенов (5 запросов в минуту):

```java
// AuthRateLimitFilter.java
private final Cache<String, Bucket> checkEmailCache = Caffeine.newBuilder()
        .maximumSize(50_000)
        .expireAfterAccess(Duration.ofMinutes(10))
        .build();

private boolean checkEmailRateLimit(String ip, HttpServletResponse response) throws IOException {
    Bucket bucket = checkEmailCache.get(ip, k -> Bucket.builder()
            .addLimit(Bandwidth.builder()
                    .capacity(5)
                    .refillGreedy(5, Duration.ofMinutes(1))
                    .build())
            .build());
    if (!bucket.tryConsume(1)) {
        response.setStatus(429);
        response.setContentType("application/json");
        response.getWriter().write("{\"code\":\"RATE_LIMIT_EXCEEDED\",\"message\":\"Too many attempts\"}");
        return false;
    }
    return true;
}
```

---

### 2.4. Юридический комплаенс в Республике Казахстан

#### Закон РК № 94-V «О персональных данных и их защите» (ст. 12)
- **Локализация**: Базы данных, содержащие персональные данные граждан РК, обязаны физически находиться на серверах в пределах границ Республики Казахстан.
- **Согласие субъекта**: Под каждой веб-формой (заявка, регистрация) обязателен прямой текст:
  *«Нажимая кнопку, вы соглашаетесь с Политикой конфиденциальности и Пользовательским соглашением»* со ссылками на соответствующие разделы.
- **Право на удаление/отзыв**: Пользователь имеет право отозвать согласие через обращение к DPO (Data Protection Officer).

#### Налоговый дисклеймер для бухгалтерских SaaS
В Пользовательском соглашении (Оферте) критически важно фиксировать распределение ответственности:
- Исполнитель рассчитывает налоги строго на базе первичных документов, загруженных клиентом.
- Исполнитель не несет ответственности за штрафы и доначисления налоговых органов (КГД МФ РК), если они вызваны искажением или непредоставлением клиентом первичных документов.

#### Файлы Cookie
- Использовать принцип минимизации: отказаться от сторонних рекламных пикселей.
- Хранить сессионные токены: `refreshToken` — в `HttpOnly`, `SameSite=Lax/Strict`, `Secure` cookie; `accessToken` — только в оперативной памяти (in-memory) приложения.
- Хранить согласие пользователя в `localStorage` (`cookie_consent = 'accepted' | 'essential_only'`).

#### Восстановление пароля (Password Reset Flow #25)
- **Токены**: Генерация 32-байтовых криптографически стойких токенов (`SecureRandom`), в БД сохраняется исключительно SHA-256 хэш (`token_hash`), срок жизни строго ограничен (15 минут), одноразовое использование (`used = true`).
- **Защита от перечисления**: Эндпоинт `/forgot-password` всегда возвращает HTTP 200 с нейтральным сообщением, предотвращая перечисление пользователей (Zero-Enumeration).
- **Отзыв сессий**: При успешном сбросе пароля все активные Refresh-токены пользователя удаляются из БД (`deleteAllByUser`), завершая скомпрометированные сессии.
- **Rate Limiting**: Выделенный кэш ограничения частоты запросов (3 запроса / 15 минут на IP).

---

## 3. Чеклист готовности к релизу
- [x] Клиент не может вызвать `PUT /invoices/{id}` и изменить `status` или `amount`.
- [x] В папке сборки `dist/` отсутствуют файлы `*.map`.
- [x] Лимит на `/check-email` не позволяет парсить существование адресов.
- [x] В футере и формах размещены реквизиты компании (ТОО, БИН, контакты).
- [x] Опубликованы страницы `/privacy-policy`, `/terms`, `/refund-policy`, `/cookie-policy`.
- [x] Все формы имеют дисклеймер согласия на обработку персональных данных.
- [x] Реализован безопасный цикл сброса пароля (`/forgot-password`, `/reset-password`) с SHA-256 токенами, отзывом сессий и защитой от перечисления.

