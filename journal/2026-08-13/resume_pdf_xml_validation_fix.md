# Resume PDF XML Validation Fix

## Context
1. **Issue:** Generated PDFs were failing to load with `org.xml.sax.SAXParseException: The entity name must immediately follow the '&' in the entity reference`.
2. **Cause:** Flying Saucer (ITextRenderer) uses a strict XML parser for XHTML. The Thymeleaf templates `classic.html`, `minimal.html`, and `modern.html` contained `&&` in `th:if` and `th:each` attributes (e.g., `th:if="${profile.summary != null && !profile.summary.isEmpty()}"`). In XML, `&` is a reserved character and must be escaped (`&amp;`) or, in the case of Thymeleaf logic, `and` should be used. There was also an unescaped `&` in the `modern.html` template (`<h2>Skills & Technologies</h2>`).

## Actions Taken
- **Templates:** Replaced all occurrences of `&&` with `and` in `th:each` and `th:if` attributes across `classic.html`, `minimal.html`, and `modern.html`.
- **Text:** Replaced `&` with `&amp;` in `<h2>Skills & Technologies</h2>` in `modern.html`.

## Impact
- PDF generation now passes XML parsing validation.
