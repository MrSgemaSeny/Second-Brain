# Мета-Журнал: 2026-08-13

## Задачи:
Внедрение генерации современного HTML и редизайн 5 премиум-шаблонов для обхода ограничений PDF-генератора Flying Saucer.

## Что было сделано:
1. **Backend Endpoint**:
   - В `ResumeController` добавлен `GET /api/v1/resume/html/{template}`.
   - В `PdfGeneratorService` добавлен метод `generateHtml` для обработки Thymeleaf-шаблонов в `resume-html/`.
2. **Шаблоны (HTML/CSS)**:
   - Написаны с нуля 5 бескомпромиссных шаблонов: Apple Modern, GitHub, Grok Monolith, Milky Soft, PH Orange.
   - Использованы современные стандарты: CSS Grid, Flexbox, переменные, закругления, Google Fonts.
3. **Frontend (UI)**:
   - Live Preview в `ResumeBuilder.tsx` переведен с рендеринга PDF (очень медленного и кривого) на чистый HTML. Превью стало мгновенным.
   - Добавлена кнопка "HTML" для выгрузки.

## Усвоенные уроки (Brain's Protocol):
- Flying Saucer (PDF engine) абсолютно не подходит для современного веб-дизайна (не понимает flexbox, grid, calc, css variables).
- Идеальное решение для Enterprise Resume Builder — отдавать красивый HTML и позволять пользователю делать "Print to PDF" из браузера, либо запускать headless browser (Puppeteer) на сервере (что пока слишком дорого для нашего MVP). 
- Переход на HTML в превью ускоряет рендеринг в сотни раз.

## Риски и техдолг:
- Скачивание PDF кнопкой "Export PDF" всё ещё использует старые "табличные" шаблоны. Пользователь может заметить рассинхрон между идеальным Live HTML Preview и скачанным через бекенд PDF. Возможный фикс в будущем: внедрение Puppeteer или полный отказ от бекенд-генерации PDF.
