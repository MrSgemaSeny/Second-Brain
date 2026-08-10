# PDF Generation with Thymeleaf and OpenHTMLtoPDF

## Overview
Generating complex documents dynamically while ensuring correct formatting and typography is achieved through a combination of Thymeleaf and OpenHTMLtoPDF.

## Implementation Details
- **Thymeleaf**: Acts as the templating engine to map Java objects (variables) into an HTML template.
- **OpenHTMLtoPDF**: Renders the generated HTML into a PDF file.
- **Benefits**: This stack provides full support for Cyrillic characters, complex typography, and corporate branding which is often a limitation in other PDF generation libraries. 
- **Service Layer**: A unified `DocumentGeneratorService` manages the generation of both PDF (via Thymeleaf) and DOCX (via poi-tl).
