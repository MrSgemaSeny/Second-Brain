# Производственная безопасность: Регламент и паттерны (Security Hardening)

Этот документ фиксирует реальный срез проверенных и внедрённых решений по безопасности в боевых проектах ZhanFinance (JF-1C) и MeDev.

---

## 1. Защита от IDOR (BOLA) и матрица RBAC по ролям

### 1.1. Проблема
Insecure Direct Object References (IDOR / BOLA) возникает, когда эндпоинт принимает идентификатор сущности (`/api/v1/billing/invoices/{id}`, `/api/v1/crm/tasks/{id}`, `/api/v1/tracker/applications/{id}`), проверяет аутентификацию пользователя, но не валидирует владение объектом или право роли на мутацию.

### 1.2. Архитектурное решение: Сервисы доступа (Access Services)
Вместо размазывания проверок по контроллерам и SQL-запросам создаются специализированные доменные гварды: `InvoiceAccessService`, `CrmAccessService`, `DocumentAccessService`.

```java
@Service
public class InvoiceAccessService {

    public boolean canRead(User user, Invoice invoice) {
        if (isAdmin(user) || isEmployee(user) || isAdvisor(user)) return true;
        // Клиент имеет доступ СТРОГО к собственным счетам
        return isClient(user) && invoice.getClient() != null 
            && invoice.getClient().getId().equals(user.getId());
    }

    public boolean canWrite(User user, Invoice invoice) {
        // Роли CLIENT и ADVISOR физически исключены из права записи
        return isAdmin(user) || isEmployee(user);
    }

    public void assertCanRead(User user, Invoice invoice) {
        if (!canRead(user, invoice)) {
            throw new AccessDeniedException("Access denied to invoice id: " + invoice.getId());
        }
    }

    public void assertCanWrite(User user, Invoice invoice) {
        if (!canWrite(user, invoice)) {
            throw new AccessDeniedException("Write access denied to invoice id: " + invoice.getId());
        }
    }
}
```

### 1.3. Принцип минимальных привилегий для роли ADVISOR (Read-Only Guard)
Роль внешнего финансового советника / консультанта требует доступа ко всем данным, но запрещает любые мутации:
- В `@PreAuthorize` контроллеров разрешается `hasAnyRole('ADMIN', 'EMPLOYEE')` для POST/PUT/PATCH/DELETE.
- В сервисах доступа роль `ADVISOR` удаляется из предикатов `canWrite()` и `canCreateFor()`.
- Попытки советника изменить статус задачи или удалить документ гарантированно возвращают HTTP 403 Forbidden.

---

## 2. In-Memory Rate Limiting (Bucket4j и Token Bucket алгоритм)

### 2.1. Алгоритм Token Bucket
Каждому клиенту (по IP или User ID) выделяется виртуальная корзина емкостью `capacity`, пополняемая с заданной частотой `refillTokens` за период времени.

### 2.2. Двухуровневая фильтрация
1. **`AuthRateLimitFilter`** (строгий):
   - Регистрация, логин: 5 попыток в минуту на IP.
   - Сброс пароля (`/forgot-password`, `/reset-password`): 3 запроса за 15 минут.
   - Anti-enumeration (`/check-email`): 5 проверок в минуту.
2. **`ApiRateLimitFilter`** (общий CRM / API):
   - 60 запросов в минуту на публичные и общие эндпоинты.
   - Burst-лимит: 10 мгновенных запросов, далее отсечка с кодом HTTP 429 Too Many Requests.
   - Хранилище корзин: Caffeine L1 Cache с временем жизни `expireAfterAccess(1, TimeUnit.HOURS)` для защиты от утечек памяти.

```java
Bucket bucket = cache.get(clientIp, ip -> Bucket.builder()
    .addLimit(Bandwidth.builder()
        .capacity(10)
        .refillGreedy(10, Duration.ofMinutes(1))
        .build())
    .build());

if (bucket.tryConsume(1)) {
    filterChain.doFilter(request, response);
} else {
    response.setStatus(429);
    response.setContentType("application/json");
    response.getWriter().write("{\"error\": \"Too many requests. Please try again later.\"}");
}
```

---

## 3. Заголовки безопасности OWASP

Реализуются на уровне Spring Security `SecurityFilterChain` и конфигурации реверс-прокси:

```java
http.headers(headers -> headers
    .contentTypeOptions(Customizer.withDefaults()) // X-Content-Type-Options: nosniff
    .frameOptions(frame -> frame.sameOrigin())      // X-Frame-Options: SAMEORIGIN
    .httpStrictTransportSecurity(hsts -> hsts
        .includeSubDomains(true)
        .maxAgeInSeconds(31536000))                 // HSTS: 1 год
    .contentSecurityPolicy(csp -> csp
        .policyDirectives("default-src 'self'; frame-src 'self' blob: data:; img-src 'self' data: https: blob:;"))
);
```

### Защита iframe для превью PDF
Заголовок `X-Frame-Options: SAMEORIGIN` в сочетании с директивой CSP `frame-src 'self' blob: data:` позволяет встроенному просмотрщику рендерить сгенерированные квитанции и резюме без блокировок браузером.

---

## 4. Ротация JWT с Grace Period при параллельных (Concurrent) запросах

### 4.1. Проблема Race Condition
Когда SPA открывает страницу с 5 параллельными запросами при истекшем Access-токене, все 5 запросов одновременно дергают `/api/v1/auth/refresh`. Первый запрос обновляет Refresh-токен и инвалидирует старый. Остальные 4 запроса приходят со старым токеном, получают 401 Unauthorized и выбрасывают пользователя на форму логина.

### 4.2. Решение: 15-секундный Grace Period в Redis / DB
- При генерации новой пары токенов старый Refresh-токен не удаляется мгновенно, а помечается как `grace_until = now() + 15 sec`.
- Если в течение 15 секунд поступает повторный запрос с тем же старым токеном, сервер возвращает уже сгенерированный новый Access-токен вместо ошибки.
- По истечении 15 секунд старый токен аннулируется окончательно. При попытке использования после этого срока срабатывает детектор компрометации (Reuse Detection), отзывающий всю цепочку сессий пользователя.

---

## 5. Защита от перебора учетных записей (Anti-enumeration)

### 5.1. Эндпоинт проверки email (`/api/v1/auth/check-email`)
- Ответ всегда стандартизирован: `{ "available": boolean }`.
- Сервер не раскрывает имена, роли, наличие блокировок или метаданные.
- Жесткий лимит: 5 запросов в минуту с одного IP. При превышении — HTTP 429.

### 5.2. Сброс пароля
- Метод `/forgot-password` всегда возвращает `200 OK` с сообщением "Если указанный адрес зарегистрирован, вам отправлена ссылка", вне зависимости от того, существует ли пользователь в БД.
- Токен сброса сохраняется в виде SHA-256 хеша с временем жизни 15 минут. Исходный токен отправляется только на email.

---

## 6. Защита от SSRF (Web Scraper Protection)

При парсинге внешних ссылок (вакансий, резюме, интеграций):
1. **Проверка схемы**: Разрешены строго `http://` и `https://`.
2. **Блокировка Private / Loopback IP адресов**:
   - `127.0.0.0/8` (localhost)
   - `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` (RFC 1918)
   - `169.254.169.254` (AWS/GCP/Fly metadata service)
   - `::1` (IPv6 localhost)
3. **Безопасный перехват ошибок**: Парсер перехватывает общий `Exception`, логирует инцидент и возвращает статус "Ручной ввод данных" вместо падения бэкенда с 500 ошибкой.

---

## 7. Стресс-тестирование лимитов (Adversarial Rate Limit Testing)

В интеграционных тестах (`ApiRateLimitFilterAdversarialTest`) проверяется устойчивость к атакам:
- Генерация пакета из $N$ быстрых параллельных запросов через `ExecutorService` и `CountDownLatch`.
- Проверка точной отсечки: ровно $K$ запросов получают 200 OK, остальные $N-K$ получают 429 Too Many Requests.
- Учёт жадного пополнения токенов (greedy refill) на высокопроизводительных многоядерных машинах.
