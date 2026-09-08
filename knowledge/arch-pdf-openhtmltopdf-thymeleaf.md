# Паттерн: Векторная генерация PDF через Thymeleaf и OpenHTMLtoPDF

## 1. Суть
Генерация высококачественных векторных PDF документов (сертификаты, счета, акты) прямо в Java-бэкенде без тяжелых браузеров (Headless Chrome/Puppeteer) и без уязвимостей внешних утилит (wkhtmltopdf).

---

## 2. Архитектура решения
```
Данные сертификата/счета (User, Invoice, Client, Items)
   │
   ▼
Thymeleaf Template Engine (templates/invoice.html)
   │ (Рендеринг HTML5/XHTML строки с подстановкой переменных)
   ▼
OpenHTMLtoPDF (PdfRendererBuilder)
   ├── Регистрация шрифтов (Inter, Roboto .ttf из resources/fonts/)
   ├── Режим useFastMode()
   └── Компиляция в byte[]
```

---

## 3. Требования к шаблону (invoice.html / certificate.html)
1. **Строгий XML/XHTML синтаксис:** Все теги должны быть закрыты (`<meta ... />`, `<link ... />`, `<img ... />`).
2. **Paged Media CSS:**
```css
@page {
    size: A4 portrait;
    margin: 10mm;
}
body {
    margin: 0;
    padding: 0;
    font-family: 'Inter', sans-serif;
}
```
3. **Локальные шрифты:** Подключаются в `PdfRendererBuilder` через `.useFont(new FileSupplier(), "Inter")`, что обеспечивает корректный рендеринг кириллических символов на любой ОС без установки системных пакетов шрифтов.

---

## 4. Проблема Регрессии Генерации PDF

### В чем опасность классического Unit-теста:
Обычный тест проверяет только то, что метод вернул ненулевой массив байтов:
```java
// БЕСПОЛЕЗНЫЙ ТЕСТ:
byte[] pdf = pdfService.generateInvoice(dto);
assertThat(pdf).isNotNull();
assertThat(pdf.length).isGreaterThan(0);
```
**Почему этого недостаточно:**
- Если разработчик изменил CSS (например, увеличил padding или размер шрифта), верстка может "развалиться".
- Счет на оплату, который обязан быть на 1 листе, перетекает на 2 листа с одной строкой подписи.
- При ошибке загрузки шрифта вся кириллица превращается в знаки вопроса `????` или пустые квадратики (Tofu), но байтовый массив генерируется без ошибок.
- Таблица товаров съезжает за границы страницы (overflow).

---

## 5. Стратегия Тестирования Регрессии PDF (Structural & Visual Testing)

Тестовый сьют `PdfGenerationRegressionTest` проверяет генерацию на двух уровнях:

### Уровень 1: Семантическая и структурная проверка (Apache PDFBox)
```java
@SpringBootTest
class PdfGenerationRegressionTest {

    @Autowired
    private PdfDocumentService pdfDocumentService;

    @Test
    void shouldRenderCyrillicCorrectlyAndFitOnSinglePage() throws Exception {
        InvoiceDto invoice = createTestInvoiceDto();

        byte[] pdfBytes = pdfDocumentService.generateInvoicePdf(invoice);

        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            // 1. Контроль геометрии документа: строго 1 страница
            assertThat(document.getNumberOfPages())
                    .as("Счет на оплату обязан помещаться ровно на одну страницу A4")
                    .isEqualTo(1);

            // 2. Извлечение текста и проверка рендеринга кириллицы
            PDFTextStripper stripper = new PDFTextStripper();
            String extractedText = stripper.getText(document);

            // Проверяем обязательные бизнес-реквизиты
            assertThat(extractedText).contains("ТОО «ZhanFinance»");
            assertThat(extractedText).contains("БИН 240140023819");
            assertThat(extractedText).contains("Счет на оплату № INV-2026-001");
            assertThat(extractedText).contains("Итого к оплате: 150 000 ₸");

            // 3. Проверка отсутствия артефактов отсутствующих шрифтов (tofu / replacement characters)
            assertThat(extractedText).doesNotContain("???");
            assertThat(extractedText).doesNotContain("\uFFFD");
        }
    }
}
```

### Уровень 2: Визуальное регрессионное тестирование (Pixel Diff)
Рендеринг страницы в растровое изображение `BufferedImage` и сравнение с эталонным снимком (Gold Baseline):

```java
@Test
void shouldMatchVisualBaselineImage() throws Exception {
    byte[] pdfBytes = pdfDocumentService.generateInvoicePdf(getDeterministicInvoice());

    try (PDDocument document = Loader.loadPDF(pdfBytes)) {
        PDFRenderer renderer = new PDFRenderer(document);
        BufferedImage actualImage = renderer.renderImageWithDPI(0, 150, ImageType.RGB);

        BufferedImage expectedImage = ImageIO.read(
                getClass().getResourceAsStream("/baselines/invoice_gold.png"));

        // Вычисляем процент расхождения пикселей
        double diffPercentage = ImageDiffUtil.calculateDifference(actualImage, expectedImage);

        // Порог расхождения не более 0.1% (на антиалиасинг)
        assertThat(diffPercentage)
                .as("Визуальный вид PDF изменился относительно эталона! Различие: " + diffPercentage + "%")
                .isLessThan(0.1);
    }
}
```
Если дизайнер или разработчик намеренно меняет шаблон, эталонное изображение обновляется через запуск теста с флагом `-DupdateBaseline=true`.
