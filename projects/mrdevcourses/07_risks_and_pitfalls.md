# 7. Риски, подводные камни и извлечённые уроки (Post-Mortem & Gotchas)

### 7.1 Архитектурные и Бэкенд Риски
- **[CRITICAL] Несоответствие часовых поясов в Drip-логике**: Всегда хранить и сравнивать время строго в UTC (`spring.jpa.properties.hibernate.jdbc.time_zone=UTC`, `TIMESTAMP WITH TIME ZONE`). Использование локального времени сервера ломает доступ к урокам при смене часового пояса.
- **[CRITICAL] JPA Cascading & orphanRemoval**: При обновлении вложенных коллекций сущностей (`Quiz -> Questions -> Options`) прямое присвоение нового списка вызывает `Hibernate OptimisticLockException` или `A collection with cascade="all-delete-orphan" was cleared and re-referenced`. **Решение**: Всегда очищать существующую коллекцию `quiz.getQuestions().clear()`, наполнять её заново и вызывать `saveAndFlush()`.
- **[WARNING] Google OAuth redirect URI**: Требуется точное совпадение URL в Google Cloud Console (`/api/login/oauth2/code/google`).
- **[WARNING] YouTube IFrame & CSP**: При настройке Content Security Policy заголовков обязательно разрешить `https://www.youtube.com` и `https://www.youtube-nocookie.com` в `frame-src`.
- **[INFO] Доступность первого дня**: Урок `day_number = 1` открывается сразу при записи (`(1-1) * 1 day = 0`).

### 7.2 Фронтенд и Тестирование
- **[WARNING] PowerShell String Interpolation в агентах**: Использование PowerShell heredocs (`@"" | Out-File`) для записи JSX/TSX файлов «съедает» обратные кавычки и переменные `${...}`, превращая шаблонные строки в невалидный синтаксис. **Правило**: Всегда использовать нативные инструменты редактирования `replace_file_content` и `write_to_file`.
- **[WARNING] React Testing Library (findByText vs findByRole)**: Когда один и тот же текст отображается и в хлебных крошках, и в заголовке `H1`, `screen.findByText('...')` выбрасывает исключение о множественном совпадении. **Решение**: Использовать `screen.findByRole('heading', { name: '...' })` или `screen.findAllByText(...)`.
- **[INFO] JSDOM window.scrollTo**: При тестировании компонентов со скроллом (`ScrollToTop`) JSDOM логирует `Error: Not implemented: window.scrollTo`. Это предупреждение не роняет тест, но для идеальной чистоты логов рекомендуется мокать `window.scrollTo = vi.fn()`.

