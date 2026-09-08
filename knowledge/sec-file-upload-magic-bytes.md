# Защита и Тестирование Загрузки Файлов (Magic Bytes, Path Traversal, DoS)

## 1. Суть проблемы и Векторы Атак
Прием файлов от пользователей — один из наиболее критичных векторов атак на веб-приложения:
1. **MIME Spoofing / Polyglot Executables:** Злоумышленник переименовывает PHP-скрипт, ELF-бинарник или исполняемый `.exe` в `document.pdf` и передает заголовок `Content-Type: application/pdf`. При передаче такого файла в уязвимый парсер или сохранении в публичную веб-директорию возможен Remote Code Execution (RCE).
2. **Path Traversal (Directory Traversal):** Передача в параметре имени файла путей обхода каталогов (`../../../../etc/shadow` или `..\\..\\Windows\\System32\\cmd.exe`), что позволяет перезаписать системные файлы или исполняемый код сервера.
3. **Null-Byte Injection & Double Extensions:** Имена файлов вида `invoice.pdf\0.php` или `script.php.pdf` для обхода наивных фильтров расширений.
4. **Decompression Bomb (Zip Bomb) / XML Bomb (SVG XXE):** Файлы малого размера, разворачивающиеся в гигабайты памяти при обработке парсером, вызывая OutOfMemoryError (OOM) и DoS сервера.

---

## 2. Архитектура Защиты (Defense in Depth)

### А. Валидация сигнатур (Magic Bytes)
Проверка реальных первых байтов файла до его сохранения и передачи тяжелым парсерам.
- PDF: `%PDF` (`0x25, 0x50, 0x44, 0x46`)
- PNG: `\x89PNG\r\n\x1a\n` (`0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A`)
- JPEG: `\xFF\xD8\xFF`
- Использование **Apache Tika**: потоковая детекция реального MIME-типа через анализ байтовой структуры, а не заголовков клиента.

### Б. Санитарная очистка имени и UUID Storage Key
Имя файла, переданное пользователем, **НИКОГДА не используется как путь в файловой системе или S3**:
- Имя файла очищается: `String safeOriginalName = FilenameUtils.getName(file.getOriginalFilename())`.
- Физический ключ хранения генерируется криптографически случайно: `String storageKey = UUID.randomUUID().toString() + "." + extension`.
- Файл сохраняется строго в изолированном каталоге с проверкой канонического пути:
  ```java
  Path destinationPath = uploadDir.resolve(storageKey).normalize().toAbsolutePath();
  if (!destinationPath.startsWith(uploadDir.toAbsolutePath())) {
      throw new SecurityException("Path traversal attempt detected");
  }
  ```

---

## 3. Автоматизированные Тесты Безопасности Загрузки Файлов

Тестовый сьют `FileUploadSecurityTest` проверяет устойчивость слоя загрузки:

```java
@SpringBootTest
@AutoConfigureMockMvc
class FileUploadSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldRejectMimeSpoofedExecutableDisguisedAsPdf() throws Exception {
        // Поддельный файл: расширение .pdf и Content-Type application/pdf,
        // но внутри исполняемый шелл-скрипт (нет сигнатуры %PDF)
        byte[] fakePdfContent = "#!/bin/bash\nrm -rf /\n".getBytes(StandardCharsets.UTF_8);
        MockMultipartFile maliciousFile = new MockMultipartFile(
                "file",
                "invoice.pdf",
                MediaType.APPLICATION_PDF_VALUE,
                fakePdfContent
        );

        mockMvc.perform(multipart("/api/v1/documents/upload")
                .file(maliciousFile)
                .with(csrf()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(containsString("Invalid file signature")));
    }

    @Test
    void shouldPreventPathTraversalInFilename() throws Exception {
        byte[] validPdf = "%PDF-1.7\n%Valid minimal PDF content".getBytes(StandardCharsets.UTF_8);
        
        // Попытка выхода из каталога через относительный путь
        MockMultipartFile traversalFile = new MockMultipartFile(
                "file",
                "../../../../etc/cron.d/malicious_job",
                MediaType.APPLICATION_PDF_VALUE,
                validPdf
        );

        MvcResult result = mockMvc.perform(multipart("/api/v1/documents/upload")
                .file(traversalFile)
                .with(csrf()))
                .andExpect(status().isCreated())
                .andReturn();

        // Проверяем, что файл сохранен под UUID, а не по указанному относительному пути
        String responseJson = result.getResponse().getContentAsString();
        assertThat(responseJson).doesNotContain("cron.d");
        assertThat(responseJson).matches(".*\"storageKey\":\"[0-9a-fA-F-]{36}\\.pdf\".*");
    }

    @Test
    void shouldRejectFilesExceedingMaxUploadSize() throws Exception {
        // Превышение лимита (например, 25 МБ)
        byte[] oversized = new byte[26 * 1024 * 1024];
        oversized[0] = '%'; oversized[1] = 'P'; oversized[2] = 'D'; oversized[3] = 'F';

        MockMultipartFile hugeFile = new MockMultipartFile(
                "file",
                "large.pdf",
                MediaType.APPLICATION_PDF_VALUE,
                oversized
        );

        mockMvc.perform(multipart("/api/v1/documents/upload")
                .file(hugeFile)
                .with(csrf()))
                .andExpect(status().isPayloadTooLarge());
    }
}
```
