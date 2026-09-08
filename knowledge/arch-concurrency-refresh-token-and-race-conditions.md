# Архитектура: Concurrency, Refresh Token Rotation Race Conditions и Тестирование Параллелизма

## 1. Проблема: Race Condition при Refresh Token Rotation (RTR)

### Сценарий в реальном SPA:
При переходе на новую страницу фронтенд (React) монтирует сразу несколько независимых компонентов или хуков React Query (например, профиль пользователя, список задач, счетчик уведомлений, баланс).
Если срок жизни короткоживущего `accessToken` истек:
1. Компоненты отправляют 3-4 параллельных запроса к разным эндпоинтам.
2. Все запросы получают ответ `401 Unauthorized`.
3. Каждый запрос параллельно инициирует обновление через `POST /api/v1/auth/refresh`, отправляя **один и тот же** `refreshToken`.

### Развитие катастрофы на бэкенде:
- **Запрос №1** приходит первым на доли миллисекунды раньше: находит токен в БД, помечает его как использованный (`used = true` или удаляет), генерирует новую пару `(access, refresh)` и возвращает клиенту.
- **Запрос №2 и №3** приходят на бэкенд, пока запрос №1 еще обрабатывается или сразу после него:
  - Токен в базе данных **уже помечен как использованный**.
  - **Наивная логика безопасности (Token Reuse Detection):** Сервер считает, что старый токен был украден хакером, и в целях защиты **аннулирует все активные токены пользователя** (Force Logout).
  - **Итог:** Легитимный пользователь внезапно разлогинивается прямо во время активной работы в CRM.

---

## 2. Архитектурное Решение: Двухуровневая Защита

### Уровень 1: Frontend Singleton Refresh Promise (`http.ts`)
На стороне клиента перехватчик `fetch` или `axios` блокирует параллельные запросы обновления:
```typescript
let refreshPromise: Promise<string> | null = null;

export async function fetchWithAuth(url: string, options: RequestInit = {}) {
    let res = await fetch(url, options);
    if (res.status === 401) {
        if (!refreshPromise) {
            refreshPromise = executeRefreshToken().finally(() => {
                refreshPromise = null;
            });
        }
        const newAccessToken = await refreshPromise;
        // Повторяем исходный запрос с новым токеном
        options.headers = { ...options.headers, Authorization: `Bearer ${newAccessToken}` };
        res = await fetch(url, options);
    }
    return res;
}
```
*Уязвимость только клиентского решения:* Не спасает при открытии приложения в нескольких вкладках браузера или на разных мобильных устройствах одного пользователя.

### Уровень 2: Backend Grace Period (Leeway Window) & DB Lock
На стороне Spring Boot бэкенда вводится **Leeway Window (окно снисхождения)**:
1. При первой ротации старый токен не удаляется мгновенно, а помечается:
   - `used = true`
   - `replaced_by_token_id = <new_token_id>`
   - `rotated_at = Instant.now()`
2. Если в течение **Grace Period (например, 15-30 секунд)** на сервер поступает запрос с этим же старым токеном:
   - Сервер **НЕ паникует и НЕ инвалидирует все сессии**.
   - Сервер возвращает клиенту **ту же самую уже сгенерированную пару токенов**, избегая рассинхронизации.
3. Если запрос со старым токеном поступает **позже Grace Period**:
   - Фиксируется реальная атака повторного использования токена (Replay Attack).
   - Вызывается `refreshTokenRepository.deleteAllByUser(user)`, все сессии отзываются.

---

## 3. Автоматизированное Тестирование Concurrency (Race Condition Test)

Для тестирования состояния гонки используется многопоточный барьер синхронизации `CountDownLatch`, который запускает потоки строго одновременно в один момент времени.

```java
@SpringBootTest
@ActiveProfiles("test")
class RefreshTokenConcurrencyTest {

    @Autowired
    private RefreshTokenService refreshTokenService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    private User testUser;
    private String initialRawToken;

    @BeforeEach
    void setUp() {
        testUser = userRepository.save(User.builder()
                .email("concurrency@zhanfinance.kz")
                .passwordHash("hash")
                .role(Role.EMPLOYEE)
                .build());

        // Создаем исходный валидный Refresh Token
        initialRawToken = refreshTokenService.createRefreshToken(testUser).getRawToken();
    }

    @Test
    void shouldHandleConcurrentRefreshRequestsWithoutFalsePositiveTokenRevocation() throws Exception {
        int threadCount = 10;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch readyLatch = new CountDownLatch(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);

        List<CompletableFuture<AuthResponse>> futures = new ArrayList<>();

        for (int i = 0; i < threadCount; i++) {
            futures.add(CompletableFuture.supplyAsync(() -> {
                try {
                    readyLatch.countDown();
                    // Все потоки ждут стартового выстрела, чтобы ударить в одну наносекунду
                    startLatch.await();
                    return refreshTokenService.rotateToken(initialRawToken);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }, executor));
        }

        // Ждем готовности всех 10 потоков и даем залп
        readyLatch.await(5, TimeUnit.SECONDS);
        startLatch.countDown();

        // Дожидаемся завершения всех параллельных вызовов
        List<AuthResponse> results = new ArrayList<>();
        int errorCount = 0;

        for (CompletableFuture<AuthResponse> future : futures) {
            try {
                results.add(future.join());
            } catch (Exception e) {
                errorCount++;
            }
        }

        // Критерии надежности:
        // 1. Хотя бы один запрос (первый) успешно сгенерировал новую пару токенов
        assertThat(results).isNotEmpty();

        // 2. Все успешные ответы в пределах Leeway Window должны указывать на один и тот же новый Refresh Token
        String expectedNewToken = results.get(0).getRefreshToken();
        for (AuthResponse response : results) {
            assertThat(response.getRefreshToken()).isEqualTo(expectedNewToken);
        }

        // 3. Сессия пользователя НЕ должна быть принудительно убита
        List<RefreshToken> activeTokens = refreshTokenRepository.findAllByUserAndRevokedFalse(testUser);
        assertThat(activeTokens).isNotEmpty();

        executor.shutdown();
    }
}
```
