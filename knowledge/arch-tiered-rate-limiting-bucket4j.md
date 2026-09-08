# Паттерн: Tiered Rate Limiting с Bucket4j и Caffeine

## Суть
Ограничение частоты запросов на уровне Java Servlet Filter с разделением эндпоинтов на функциональные уровни (Tiers) с разными лимитами и ключами идентификации.

## Архитектура
```
HTTP Request 
   │
   ▼
OncePerRequestFilter (RateLimitingFilter)
   ├── 1. Извлечение пути (extractNormalizedPath)
   ├── 2. Определение Tier:
   │      ├── /v1/auth/** ──► AUTH (10 req/15m per IP)
   │      ├── /v1/ai/**   ──► AI (5 req/min per User)
   │      └── /v1/**      ──► GENERAL (60 req/min per User/IP)
   ├── 3. Формирование ключа (resolveKey): "ip:192.168.1.1" или "user:42"
   ├── 4. Получение Bucket из Caffeine кэша
   └── 5. probe = bucket.tryConsumeAndReturnRemaining(1)
          ├── isConsumed == true:
          │      Заголовок: X-RateLimit-Remaining: {N}
          │      Пропуск дальше по FilterChain
          └── isConsumed == false:
                 Заголовки: Retry-After: {seconds}, X-RateLimit-Remaining: 0
                 Ответ: HTTP 429 Too Many Requests (JSON ErrorResponse)
```

## Важные нюансы реализации
1. **Refill Strategy:** Использовать `refillIntervally(tokens, duration)`, а не `refillGreedy`, когда требуются строгие дискретные лимиты на весь интервал без непрерывного помиллисекундного подсыпания токенов.
2. **Caffeine Cache:** `expireAfterAccess(1, TimeUnit.HOURS)` и `maximumSize(50_000)` предотвращают утечки памяти при большом числе уникальных IP.
3. **CORS Safe:** Фильтр обязан пропускать HTTP метод `OPTIONS` без проверки токенов во избежание блокировки CORS pre-flight запросов.

---

## Алгоритмы: Sliding Window vs Fixed Window vs Token Bucket

При проектировании Rate Limiter важно четко различать используемую алгоритмическую модель:

### 1. Fixed Window Counter (Фиксированное окно)
- **Принцип:** Время делится на жесткие кванты (например, 12:00:00–12:01:00). Счетчик инкрементируется и сбрасывается в нуль на границе минуты.
- **Критический дефект (Boundary Burst):** Атакующий может сделать 60 запросов в 12:00:59 и еще 60 запросов в 12:01:01. Итог: **120 запросов за 2 секунды** при декларированном лимите "60 в минуту". Это пробивает бэкенд и базу данных двойной нагрузкой.

### 2. Sliding Window (Скользящее окно)
- **Sliding Window Log:** Хранит таймстемпы всех вызовов за последний интервал. Идеально точен, но требует колоссального объема памяти при высоких RPS (O(N) по числу запросов).
- **Sliding Window Counter:** Взвешенная сумма запросов текущего и предыдущего фиксированного окна: `Count = CurrentWindow + PreviousWindow * (1 - Progress)`. Дает сглаживание без Boundary Burst при фиксированной O(1) памяти.

### 3. Token Bucket (Bucket4j)
- **Принцип:** Ведро фиксированной емкости $B$, куда с постоянной скоростью поступают токены со скоростью $R$. При каждом запросе списывается 1 токен. Если ведро пусто — запрос блокируется.
- **Преимущество:** Позволяет легитимный контролируемый кратковременный всплеск (Burst Allowance до емкости $B$), гарантируя при этом, что долговременная частота не превысит $R$.
- **Разница Refill:**
  - `refillGreedy(tokens, period)`: токены начисляются непрерывно (математически гладкое скользящее окно).
  - `refillIntervally(tokens, period)`: токены возвращаются строго полной пачкой раз в период (дискретное окно).

---

## Векторы атак: X-Forwarded-For Spoofing и CF-Connecting-IP

Самая распространенная ошибка в кастомных Rate Limiting фильтрах — слепое доверие HTTP-заголовкам клиентского IP-адреса.

### Анатомия уязвимости (Bypass Rate Limiting)
Если в фильтре реализовано наивное извлечение:
```java
// УЯЗВИМЫЙ КОД!
String ip = request.getHeader("CF-Connecting-IP");
if (ip == null) ip = request.getHeader("X-Forwarded-For");
if (ip == null) ip = request.getRemoteAddr();
```

Атакующий отправляет циклы запросов:
```http
POST /api/v1/auth/login HTTP/1.1
Host: api.zhanfinance.kz
CF-Connecting-IP: 185.220.101.5
X-Forwarded-For: 185.220.101.5
```
Меняя IP в заголовке на каждой итерации (`.6`, `.7`, `.8`), атакующий получает **бесконечные новые корзины (Buckets)** в Caffeine кэше и **100% обходит Rate Limiter**, проводя брутфорс паролей или DoS.

### Правило безопасного извлечения IP (Rightmost Untrusted IP)
1. **До подключения Cloudflare:** Заголовок `CF-Connecting-IP` полностью запрещено считать доверенным! Любой клиент может передать его снаружи.
2. **Проверка Trusted Proxy:** Заголовкам `X-Forwarded-For` можно доверять **только тогда**, когда `request.getRemoteAddr()` (физический сокет TCP-соединения) принадлежит доверенному обратному прокси (Nginx, Fly.io Edge Proxy).
3. **Парсинг цепочки:** В заголовке вида `X-Forwarded-For: client, proxy1, proxy2` клиент может дописать слева любой фейк: `fake_ip, real_client_ip`. Если прокси просто дописывает адрес в конец, взятие первого элемента (`parts[0]`) приводит к уязвимости. Необходимо анализировать цепочку **справа налево**, отбрасывая известные доверенные прокси, и брать первый внешний узел.

---

## Тестирование Rate Limiting

Для надежной защиты в тестовый сьют включаются 3 обязательных теста:

### 1. Тест на исчерпание лимита и восстановление (Window & Capacity)
```java
@Test
void shouldBlockAfterLimitAndRecoverAfterRefill() {
    String clientIp = "10.0.0.1";
    // 1. Посылаем N разрешенных запросов -> 200 OK
    for (int i = 0; i < 5; i++) {
        mockMvc.perform(get("/api/v1/auth/check-email").with(remoteAddr(clientIp)))
               .andExpect(status().isOk())
               .andExpect(header().exists("X-RateLimit-Remaining"));
    }
    // 2. 6-й запрос обязан быть заблокирован -> 429 Too Many Requests
    mockMvc.perform(get("/api/v1/auth/check-email").with(remoteAddr(clientIp)))
           .andExpect(status().isTooManyRequests())
           .andExpect(header().string("Retry-After", notNullValue()));
}
```

### 2. Тест на попытку обхода через подделку X-Forwarded-For (Spoofing Prevention)
```java
@Test
void shouldNotAllowBypassViaSpoofedHeaders() {
    String realSocketIp = "192.168.1.100";
    
    // Атакующий шлет разные фейковые заголовки с одного физического адреса
    for (int i = 0; i < 5; i++) {
        mockMvc.perform(get("/api/v1/auth/check-email")
                .with(remoteAddr(realSocketIp))
                .header("X-Forwarded-For", "203.0.113." + i)
                .header("CF-Connecting-IP", "198.51.100." + i))
               .andExpect(status().isOk());
    }

    // 6-й запрос с нового фейкового IP все равно должен быть заблокирован, 
    // так как сервер берет реальный socket IP незащищенного соединения
    mockMvc.perform(get("/api/v1/auth/check-email")
            .with(remoteAddr(realSocketIp))
            .header("X-Forwarded-For", "8.8.8.8")
            .header("CF-Connecting-IP", "8.8.4.4"))
           .andExpect(status().isTooManyRequests());
}
```

### 3. Тест на корректность заголовков CORS Pre-flight (OPTIONS)
Проверка, что HTTP `OPTIONS` не потребляет токены из корзины и никогда не возвращает 429, иначе браузер заблокирует любые кросс-доменные запросы при спайках.

