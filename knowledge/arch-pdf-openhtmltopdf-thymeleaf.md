# Паттерн: Векторная генерация PDF через Thymeleaf и OpenHTMLtoPDF

## Суть
Генерация высококачественных векторных PDF документов (сертификаты, счета, отчеты) прямо в Java-бэкенде без тяжелых браузеров (Headless Chrome/Puppeteer) и без уязвимостей внешних утилит (wkhtmltopdf).

## Архитектура решения
```
Данные сертификата (User, Course, Date, Code)
   │
   ▼
Thymeleaf Template Engine (templates/certificate.html)
   │ (Рендеринг HTML5/XHTML строки с подстановкой переменных)
   ▼
OpenHTMLtoPDF (PdfRendererBuilder)
   ├── Регистрация шрифтов (Inter, Roboto .ttf из resources/fonts/)
   ├── Режим useFastMode()
   └── Компиляция в byte[]
```

## Требования к шаблону (certificate.html)
1. **Строгий XML/XHTML синтаксис:** Все теги должны быть закрыты (`<meta ... />`, `<link ... />`, `<img ... />`).
2. **Paged Media CSS:**
```css
@page {
    size: A4 landscape;
    margin: 0;
}
body {
    margin: 0;
    padding: 0;
    width: 297mm;
    height: 210mm;
}
```
3. **Локальные шрифты:** Подключаются в `PdfRendererBuilder` через `.useFont(new FileSupplier(), "Inter")`, что обеспечивает корректный рендеринг кириллических символов на любой ОС без установки системных пакетов шрифтов.
