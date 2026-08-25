# 7. Риски и подводные камни MrDevCourses

- **[CRITICAL] Несоответствие часовых поясов в Drip-логике**: Всегда хранить и сравнивать время строго в UTC.
- **[WARNING] Google OAuth redirect URI**: Требуется точное совпадение URL в Google Cloud Console (`/api/login/oauth2/code/google`).
- **[WARNING] YouTube IFrame & CSP**: При настройке Content Security Policy заголовков обязательно разрешить `https://www.youtube.com` в `frame-src`.
- **[INFO] Доступность первого дня**: Урок `day_number = 1` открывается сразу при записи (`(1-1) * 1 day = 0`).
