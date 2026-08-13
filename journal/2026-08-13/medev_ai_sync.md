# 2026-08-13: MeDev AI Smart Sync & Local State Fix

## Что сделано
1. Диагностирован баг "исчезающего профиля" после парсинга PDF (эндпоинт `/api/v1/ai/parse-resume`).
   - Описание проблемы: Фронт вызывает React Query `invalidateQueries`, и данные успешно ложились в кэш. Однако `AboutSection.tsx` внутри `onSuccess` слепо мёрджил весь `ProfileDto` (включая массивы `experience`, `education`) в свой локальный `formData`. Это приводило к засорению стейта и потенциально заставляло пользователя думать, что данные не спарсились.
   - Решение: Сделан явный деструктуринг полей в `setFormData` (только `fullName`, `headline`, `summary` и т.д.).
2. Доработан промпт `full_profile_generator_v1.txt`. Добавлено строгое правило: `IF GITHUB SNAPSHOT IS EMPTY ({}): rely entirely on CURRENT PROFILE JSON`. Теперь при генерации профиля без GitHub опыт и образование из PDF не будут затерты.
3. Добавлены глобальные кнопки **Smart AI Sync** в `DashboardPage.tsx` (в Quick Actions) и `ProfileEditor.tsx` (в хедер). Кнопки вызывают `useGenerateProfile()` (тот самый `POST /api/v1/ai/generate-profile`), который сливает воедино PDF и GitHub с помощью Groq. Добавлены переводы в `en.json` и `ru.json`.

## Результат
Пользователь может загрузить резюме в виде PDF (оно распарсится и ляжет в базу), а затем одной кнопкой слить эти данные с GitHub Snapshot для генерации идеального профиля. UI реагирует предсказуемо, стейты не засоряются. 

## Следующие шаги
- Запуск тестов.
- Переход к CI/CD пайплайнам (Action Items на завтра).
