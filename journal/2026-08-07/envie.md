# Envie — 07.08.2026

## Что изменено / добавлено / исправлено

### 1. Бэкенд (Java / Spring Data JPA)
- **Исправлен PostgreSQL SQLGrammarException (`lower(bytea)`) в `NoteRepository.java` и `IdeaRepository.java`**:
  - В `NoteRepository.java` (запрос `searchNotes` с `SELECT DISTINCT`) и `IdeaRepository.java` при передаче `null` или пустого параметра поиска `:search` PostgreSQL присваивал типу тип `bytea`, вызывая ошибку `ОШИБКА: функция lower(bytea) не существует`.
  - Добавлено явное приведение параметров JPQL: `cast(:search as string)`.

### 2. Фронтенд (React / Tailwind v4 / FSD)
- **Полная переработка `CreateIdeaDrawer.tsx`**:
  - **Многострочные текстовые поля**: Поля `Target Audience` и `Monetization Strategy` переведены с однострочных `<input type="text">` на многострочные `<textarea>`.
  - **Автоматическая подгонка высоты (`auto-resize`)**: Добавлен расчет высоты по `scrollHeight` через `useRef` и `useEffect` с `requestAnimationFrame` при открытии формы в режиме создания или редактирования.
  - **Устранение вложенных скроллов**: Поля больше не создают внутренние вертикальные полосы прокрутки.
  - **Флюидная адаптивность**: Ширина модального окна увеличена до `w-[94vw] max-w-5xl` с аккуратным центрированием и стеклянным размытием `backdrop-blur-xl`.

## Проверка и статус
- `npm run build` — успешно (0 ошибок).
- `./gradlew build` — успешно (0 ошибок).
- Git: закоммичено и отправлено в `origin/master`.
