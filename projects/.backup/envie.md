## 1. Концепция и Философия Проекта

### 1.1 Манифест Envie
**"Without cloud. Without authorization. Without excess."**
Envie — это персональная база знаний, трекер задач и хранилище идей для соло-разработчиков. В отличие от корпоративных монстров (Jira, Notion, Confluence), Envie не пытается угодить менеджерам. Это инструмент, созданный программистом для программиста.
Ключевые принципы:
1. **Абсолютная приватность (Self-Hosted):** Никаких облаков. База данных крутится на локальной машине через Docker. Никто не имеет доступа к мыслям и коду автора.
2. **Нулевое трение (Zero Friction):** Отсутствие экранов логина, JWT-токенов, прав доступа. Вы открыли `localhost:5173` — вы сразу в контексте.
3. **Бескомпромиссная эстетика:** Приложение должно вызывать восторг. Использование 3D-графики, размытых стеклянных панелей (Glassmorphism), идеальной типографики и микро-анимаций.

### 1.2 Целевая аудитория и Use Cases
- **Ведение дневника разработки (Notes):** Логгирование багов, быстрые сниппеты кода, мысли.
- **Управление задачами (Board):** Kanban-доска для текущих эпиков. Без бюрократии (Story Points, Epics). Только To Do -> In Progress -> Done.
- **Инкубатор стартапов (Ideas):** Структурированное хранение идей с жестким фреймворком оценки (Проблема, Решение, Аудитория, Монетизация).
- **Второй мозг (Templates/Docs):** Хранение Markdown-шаблонов и глобальной документации с инновационной навигацией через 2D-граф связей.

---
## 2. Архитектурный Стек

### 2.1 Бэкенд (Java/Spring Boot)
- **Язык:** Java 17 LTS (Использование Records, Text Blocks, Pattern Matching).
- **Фреймворк:** Spring Boot 3.1+. (Tomcat embedded).
- **API:** RESTful (JSON).
- **Слой доступа к данным:** Spring Data JPA + Hibernate.
- **Миграции:** Flyway.
- **Сборка:** Gradle (Kotlin DSL).

### 2.2 Фронтенд (React/Vite/FSD)
- **Ядро:** React 18, TypeScript (Strict Mode).
- **Сборщик:** Vite (esbuild).
- **Стилизация:** Tailwind CSS v4 (Без `tailwind.config.js`, прямо через директивы CSS).
- **Архитектура:** Feature-Sliced Design (FSD).
- **State Management:** `@tanstack/react-query` v5 для серверного стейта. Локальный стейт только через `useState`/`useContext`.
- **UI Библиотеки:** `sonner` (Toast уведомления), `vaul` (Drawers/Шторки).
- **Графика:** `three.js`, `@react-three/fiber`, `gsap`, `react-force-graph-2d`.
- **Markdown:** `react-markdown` + `remark-gfm` + `highlight.js`.

### 2.3 Инфраструктура
- **База Данных:** PostgreSQL 17 (Запускается через `docker-compose.yml`).
- **Среда:** Локальный запуск (Localhost). Отсутствие Nginx/SSL.

---
## 3. База данных и Миграции (Flyway)

Все изменения БД строго версионируются в `backend/src/main/resources/db/migration/`.

### 3.1 V1__init.sql (Базовые настройки)
Включает расширение `uuid-ossp` для генерации UUID v4 на стороне БД.

### 3.2 V2__notes.sql (Лента заметок)
Заметки — это хронологический поток мыслей (как Twitter).
```sql
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL
);
CREATE TABLE note_tags (
    note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (note_id, tag_id)
);
```

### 3.3 V3__board.sql (Канбан)
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL, -- TODO, IN_PROGRESS, DONE
    position INTEGER NOT NULL, -- Для drag-and-drop
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE TABLE subtasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE
);
```

### 3.4 V4__ideas.sql (Идеи)
```sql
CREATE TABLE ideas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    problem TEXT,
    solution TEXT,
    audience TEXT,
    monetization TEXT,
    status VARCHAR(50) DEFAULT 'DRAFT',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3.5 V5__remove_ai.sql
Отмена предыдущего эксперимента. Удаление таблиц промптов, контекстов LLM и логов. Признание того, что AI архитектуру лучше вынести на уровень агентов (OpenHands), а не зашивать в ядро Envie.

### 3.6 V6__wallpaper.sql
Хранение настроек эстетики.
```sql
CREATE TABLE wallpaper_settings (
    id INT PRIMARY KEY DEFAULT 1,
    media_url TEXT NOT NULL,
    is_video BOOLEAN DEFAULT FALSE,
    blur_amount INT DEFAULT 20,
    opacity DECIMAL(3,2) DEFAULT 0.8
);
```

### 3.7 V7__templates.sql
Перенос файлов Markdown из файловой системы ОС внутрь PostgreSQL для унификации.
```sql
CREATE TABLE templates (
    name VARCHAR(255) PRIMARY KEY, -- 'EPIC_BOARD.md'
    content TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---
## 4. Архитектура Фронтенда: Feature-Sliced Design (FSD)

Envie строго следует методологии FSD. Это защищает код от эффекта "спагетти".

### 4.1 Shared (Переиспользуемый код)
- `shared/api/http.ts`: Базовый `axios` или `fetch` клиент. Обрабатывает HTTP 500, глобально вызывает тосты об ошибке (`toast.error('Server down')`).
- `shared/ui/`: Компоненты UI-кита. `Button`, `Input`, `Textarea`, `BentoCard`. Они "тупые" — не знают о бизнес-логике.
- `shared/lib/cn.ts`: Утилита слияния классов (`clsx` + `twMerge`).

### 4.2 Entities (Бизнес-сущности)
- `entities/note/`:
  - `model/`: TypeScript интерфейсы (`Note`, `Tag`).
  - `api/`: Функции `useNotesQuery`, `useNoteMutation` (инкапсуляция React Query).
  - `ui/`: `NoteCard` — компонент, который умеет рендерить заметку, но не умеет её удалять (удаление — это Feature).

### 4.3 Features (Взаимодействия)
- `features/create-note/`: Компонент с полем ввода и кнопкой отправки. Управляет локальным стейтом инпута и вызывает API сущности.
- `features/task-dnd/`: Логика перемещения карточки задачи. Интеграция `dnd-kit`, расчет новой позиции (например, среднее арифметическое между верхней и нижней карточкой).

### 4.4 Widgets (Самостоятельные блоки)
- `widgets/Sidebar/`: Левое меню навигации.
- `widgets/TemplateGraph/`: Компонент графа (`ForceGraph2D`). Запрашивает `entities/template` и рендерит холст.
- `widgets/TaskBoard/`: Собирает колонки, внедряет `features/task-dnd` и рендерит `entities/task/ui/TaskCard`.

### 4.5 Pages (Экраны)
- `pages/LandingPage/`: Содержит 3D-сцену и навигацию по Bento-модулям.
- `pages/NotesPage/`, `pages/BoardPage/`, `pages/IdeasPage/`, `pages/TemplatesPage/`.

---
## 5. Дизайн-Система и UI/UX (Emil Kowalski Principles)

Визуальная часть Envie — это предмет особой гордости. Интерфейс должен ощущаться дорогим, быстрым и отзывчивым, как нативные iOS приложения.

### 5.1 Анимации и CSS-свойства
- **Правило 1:** Строгий запрет на `transition-all`. Анимация высоты, ширины или margin вызывает Reflow браузера и убивает FPS. Допускается только `transition-transform` (Scale, Translate) и `transition-opacity`.
- **Правило 2:** Easing. Используется исключительно `ease-out` (или кубические Безье `cubic-bezier(0.16, 1, 0.3, 1)`). Элемент должен появляться быстро (максимальная скорость в начале) и плавно замедляться в конце. `ease-in` запрещен.
- **Правило 3:** Микро-взаимодействия (Micro-interactions). Каждая интерактивная кнопка имеет `active:scale-95`. При нажатии она "вдавливается" в экран.

### 5.2 Типографика и Цвета
- **Шрифт:** Vercel Geist (Geist Sans для UI, Geist Mono для кода). Эмодзи строго запрещены — они дешевят интерфейс. Иконки — Lucide React (строгие линии).
- **Цветовая палитра:** Монохром. `bg-background` (Почти черный, например `#0A0A0A`), `text-foreground` (`#EDEDED`). Акценты делаются за счет прозрачности (белый цвет с `opacity: 10%`, `50%`, `80%`), а не за счет кричащих цветов.
- **Glassmorphism:** Повсеместное использование `backdrop-blur-md` и `bg-white/5` для панелей, плавающих над обоями.

### 5.3 Dual-Layer Wallpaper (Слоистые обои)
Пользователь может установить GIF или видео на фон. Чтобы текст оставался читаемым, используется Dual-Layer рендеринг:
1. Задний слой: Исходное видео, растянутое на весь экран (`object-cover`), с применением CSS `filter: blur(40px) brightness(0.4)`. Это создает динамичную, мягкую атмосферу.
2. Передний слой (опционально): Окно пропорции 3:4 по центру с четким изображением, вокруг которого выстраивается UI (Bento-сетка).

---
## 6. Подсистема 3D и Графики

### 6.1 Интерактивный Дашборд (`Three.js`)
Главная страница (`/`) встречает пользователя 3D-композицией:
- **Основа:** `<Canvas>` от `@react-three/fiber`.
- **Объекты:** Центральная сфера (Core) с шейдерным свечением (Glow Material). Вокруг вращаются Wireframe-кольца или торусы.
- **Анимация (GSAP):** При загрузке страницы кольца вылетают из центра, масштабируясь от 0 до 1 с эффектом пружины (Elastic/Back ease). Камера медленно вращается вокруг оси Y.

### 6.2 Инновационная навигация по шаблонам (`react-force-graph-2d`)
Вместо скучного списка файлов слева, `TemplatesPage` использует графовую навигацию.

**Алгоритм построения графа (buildGraph.ts):**
1. Бэкенд возвращает список шаблонов: `['EPIC_BOARD.md', 'EPIC_NOTES.md', 'AI_PROMPT.md']`.
2. Фронтенд парсит имена по префиксу `_`. (Группа 1: `EPIC`, Группа 2: `AI`).
3. Для группы `EPIC` создаются связи (Links): `BOARD` <-> `NOTES`.
4. Библиотека `react-force-graph-2d` применяет физику (D3-force):
   - Отталкивание (Charge): Ноды отталкиваются друг от друга.
   - Пружины (Link Force): Связанные ноды притягиваются.
   - Центрирование (Center Force): Граф держится по центру экрана.
5. При клике на ноду (файл), справа выезжает шторка (Drawer) на всю высоту экрана с рендерингом Markdown.

---
## 7. Развитие и Интеграция с AI

Envie спроектирован так, чтобы быть идеальным рабочим пространством для человека, в то время как AI (Агенты вроде OpenHands или Claude Code) работают "вокруг" него.

- **Второй Мозг:** В папке шаблонов Envie хранятся файлы `prompts_for_ai.md`, `rules.md`, `projects.md`. Агенты получают доступ к этим файлам напрямую, читая их и понимая контекст всей экосистемы Мурата Орынбасара.
- **Будущее:** Интеграция API LLM (опциональная) только для суммаризации заметок или тегирования, но без изменения базовой концепции "Private Only".

---
## 8. Итоги и Ретроспектива

Проект Envie (В разработке) — это квинтэссенция текущего уровня разработчика. Он объединяет в себе:
- Глубокое понимание архитектуры React (FSD).
- Эстетический перфекционизм (Дизайн-система, Анимации).
- Продвинутые технологии браузера (WebGL/Canvas).
- Прагматичный подход к бэкенду (Java Spring Boot без лишних абстракций, так как нагрузка минимальна).
Envie — это не просто инструмент, это цифровой дом разработчика.
# Envie — Полное архитектурное руководство и спецификация

Этот документ является фундаментальным описанием проекта "Envie". Он задуман не просто как README, а как исчерпывающая база знаний, фиксирующая каждое архитектурное решение, структуру БД, паттерны UI/UX и принципы кодовой базы. 

---

## Содержание (Модули)

- [[01_1._концепция_и_философия_проекта]] - 1. Концепция и Философия Проекта
- [[02_2._архитектурный_стек]] - 2. Архитектурный Стек
- [[03_3._база_данных_и_миграции_(flyway)]] - 3. База данных и Миграции (Flyway)
- [[04_4._архитектура_фронтенда_feature-sliced_design_(fs]] - 4. Архитектура Фронтенда: Feature-Sliced Design (FSD)
- [[05_5._дизайн-система_и_uiux_(emil_kowalski_principles]] - 5. Дизайн-Система и UI/UX (Emil Kowalski Principles)
- [[06_6._подсистема_3d_и_графики]] - 6. Подсистема 3D и Графики
- [[07_7._развитие_и_интеграция_с_ai]] - 7. Развитие и Интеграция с AI
- [[08_8._итоги_и_ретроспектива]] - 8. Итоги и Ретроспектива
