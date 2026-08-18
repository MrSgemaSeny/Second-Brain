## Security Fixes (2026-08-18)
- Исправлена уязвимость Broken Access Control (BAC): добавлены проверки .hasRole("ADMIN") для путей /api/admin/** в SecurityConfig сервисов "identity-service" и "vacancy-service".
- Обновлен "docker-compose.yml": порты внутренних микросервисов закрыты через замену директивы "ports" на "expose", чтобы предотвратить обход API Gateway.
- Проверен "apiClient.ts" во фронтенде (мертвые заглушки уже были заменены на реальные запросы ранее).
- Проверен "InternalTokenFilter" — защита всех эндпоинтов работает корректно через строгую проверку "X-Internal-Token".

- Усилена валидация секретов в SecretValidator: теперь приложение упадет при старте, если JWT_SECRET или INTERNAL_SERVICE_TOKEN будут пустой строкой (ранее пустая строка обходила проверку).
