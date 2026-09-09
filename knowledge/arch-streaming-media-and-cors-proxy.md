# Архитектура медиа-стриминга, HLS/MP4, Presigned URLs и WebVTT CORS Proxy

## 1. Введение
Организация видеостриминга в веб-приложениях требует баланса между тремя факторами:
- Защита контента от несанкционированного доступа.
- Снятие паразитной нагрузки по раздаче тяжелого бинарного трафика с серверов бизнес-логики (Spring Boot).
- Корректная работа браузерных стандартов безопасности (Same-Origin Policy, CORS) при загрузке текстовых дорожек субтитров (`<track>`).

В проекте testCinema (INSIGHT) реализован масштабируемый гибридный медиа-шлюз.

---

## 2. Схема движения медиа-потоков

```
[ Браузер: PlayerSurface ]
     │                │
     │ 1. GET /stream/{id}
     ▼                │
[ Spring Boot Core ]  │
     │                │
     │ (Генерация Presigned URL на 60 мин)
     ▼                │
(Прямая ссылка на MinIO)
     │                │
     │ 2. Прямой видеопоток (Range requests: 206 Partial Content)
     ▼                ▼
[ MinIO S3 Object Storage ]

     ──────────────────────────────────────────

[ Браузер: <track src="/stream/{id}/subtitle"> ]
     │
     │ 3. GET /stream/{id}/subtitle (Запрос субтитров)
     ▼
[ Spring Boot Core ] ──(Чтение SRT из хранилища)──► [ MinIO / FS ]
     │
     │ On-the-fly Regex: 00:00:01,000 -> 00:00:01.000
     │ Добавление заголовка WEBVTT
     ▼
(Отдача WebVTT с Content-Type: text/vtt; charset=utf-8 от имени бэкенда)
```

---

## 3. Инженерные особенности реализации

### 3.1. Защита видеопотока через MinIO Presigned URLs
```java
// StreamService.java
public Map<String, String> getStreamUrls(Long movieId) {
    Movie movie = movieRepository.findById(movieId)
        .orElseThrow(() -> new ResourceNotFoundException("Movie not found"));

    String presignedVideoUrl = minioClient.getPresignedObjectUrl(
        GetPresignedObjectUrlArgs.builder()
            .method(Method.GET)
            .bucket(videoBucket)
            .object(movie.getVideoS3Path())
            .expiry(60, TimeUnit.MINUTES)
            .build()
    );

    return Map.of(
        "videoUrl", presignedVideoUrl,
        "subtitleUrl", "/stream/" + movieId + "/subtitle"
    );
}
```
**Преимущества:**
- Бэкенд не пропускает через себя гигабайты видео, не расходует память JVM и сокеты сервера приложений.
- Браузер обращается к MinIO напрямую, используя HTTP Range-запросы (`Range: bytes=0-1048575`) для перемотки и буферизации.

### 3.2. Обход браузерных ограничений CORS для WebVTT субтитров
Браузеры блокируют загрузку внешних субтитров в теге `<track src="...">`, если сервер отдачи не выставляет специфические CORS-заголовки. Для приватного S3-хранилища это требует постоянной перенастройки bucket CORS rules.

Решение — проксирование через контроллер бэкенда:
```java
// StreamController.java
@GetMapping("/{id}/subtitle")
@PermitAll
public ResponseEntity<byte[]> subtitle(@PathVariable Long id) {
    byte[] content = streamService.getSubtitleBytes(id);
    if (content == null) {
        return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_TYPE, "text/vtt; charset=utf-8")
            .body(content);
}
```
Конвертер на лету приводит сторонние SRT-файлы к валидному WebVTT-формату:
```java
String vttContent = "WEBVTT\n\n" + srtText.replaceAll("(\\d{2}:\\d{2}:\\d{2}),(\\d{3})", "$1.$2");
```

---

## 4. Памятка при разработке стриминговых систем
1. **Никогда не стримить видео через бэкенд на Spring Boot (`InputStream / byte[]`)**, если только это не проксирование маленьких файлов. Для видео всегда использовать Presigned URLs или CDN (Cloudflare Stream / AWS CloudFront).
2. **Всегда проверять Content-Type для субтитров.** Если отдать субтитры с `text/plain` или `application/octet-stream`, плеер HTML5 проигнорирует дорожку.
3. **Хранить в БД только относительные S3-пути (`movies.video_s3_path`),** а не абсолютные доменные ссылки. Это позволяет менять домены и бакеты хранилища без миграции базы данных.
