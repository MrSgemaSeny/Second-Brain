# ADR-010: Генерация векторных PDF-сертификатов на базе OpenHTMLtoPDF и Thymeleaf

## Статус
Принято (2026-08-27)

## Контекст
При завершении 100% уроков курса платформа MrDevCourses выдает студенту официальный сертификат.
Требования к генерации:
1. Пиксель-перфектная верстка в темной эстетике платформы (золотые рамки, герб, печать, моноширинный код сертификата, QR-код/ссылка верификации).
2. Полная поддержка кириллицы (UTF-8) и шрифтов без кракозябр (шрифты Inter и Roboto).
3. Высокая производительность и отсутствие необходимости в тяжелых headless-браузерах (Puppeteer / Chromium).

## Решение
Использовать связку **Thymeleaf Template Engine** + **OpenHTMLtoPDF (PDFBox backend)**:
- Зависимость: `com.openhtmltopdf:openhtmltopdf-pdfbox:1.0.10`.
- Шаблонизация: HTML5 шаблон `templates/certificate.html` с CSS paged media (`@page { size: A4 landscape; margin: 0; }`).
- Шрифты: локальные TTF файлы (`Inter-Regular`, `Inter-Bold`, `Roboto-Regular`, `Roboto-Bold`) в `resources/fonts/`, подключаемые через `@font-face` с `font-family` подстановкой.
- Движок: `PdfRendererBuilder` с режимом `useFastMode()` для минимального потребления CPU/RAM.

## Последствия
- Положительные:
  - Генерация векторного PDF документа A4 landscape за ~40-70мс без развертывания Chromium.
  - Нулевая уязвимость перед SSRF (шрифты загружаются локально из classpath).
  - Студент получает валидный PDF файл для скачивания и печати, а любой внешний наблюдатель может верифицировать сертификат по публичной ссылке `/certificates/verify/{code}`.
