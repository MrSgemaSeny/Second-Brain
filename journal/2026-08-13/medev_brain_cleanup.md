# 2026-08-13: Санитарная очистка Brain's Protocol и настройки MeDev

## Сделано:
1. **Brain's Protocol:**
   - Переименованы 9 файлов в `projects/medev/` (с кириллицы на snake_case) для устранения ошибки `File name too long` при клонировании на Linux.
   - Удалён мусорный файл `combined_docs.md` (11КБ дамп, мешающий работе).

2. **MeDev:**
   - Создан `CLAUDE.md` в корне проекта со строгими архитектурными правилами (SecurityUtils для защиты от IDOR, модульный монолит, запрет на изменение V-скриптов Flyway).

3. **3D Landing Preview (Three.js):**
   - Переписан и завершён HTML-прототип дашборда (`medev_dashboard_3d_5.html`).
   - Убраны кривые bloom-подложки и `CircleGeometry` полы, заливавшие экран цветом от `PointLight`.
   - Дизайн адаптирован под премиальный строгий GitHub Dark Mode (только прозрачные меши и акцентные edge-линии).

## Следующие шаги на критическом пути:
1. Деплой (Fly.io + GitHub Pages)
2. IDOR Security Audit
3. Покрытие тестами (JUnit/Vitest)
