# WebFlux SSE Streaming и проблема потери кодировки UTF-8

## Суть проблемы
При стриминге ответов от LLM (например, через Groq API) на русском языке часть символов искажалась (например, «Тыновил» вместо «Ты обновил»).

## Причина
В Spring WebFlux при использовании `.bodyToFlux(String.class)` ответ читается как поток строк. Декодер WebFlux (`StringDecoder`) натыкается на фрагментацию TCP-пакетов (chunks). Если граница чанка проходит ровно посередине многобайтового символа UTF-8 (а кириллица занимает 2 байта), символ ломается, и мы получаем кракозябры или проглоченные буквы.

## Решение
Вместо парсинга потока как простого `String`, необходимо использовать `ServerSentEvent` (ведь LLM API отдает `text/event-stream`).

```java
// НЕПРАВИЛЬНО:
webClient.post()
    .retrieve()
    .bodyToFlux(String.class) // Режет TCP-чанки, ломает UTF-8

// ПРАВИЛЬНО:
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.codec.ServerSentEvent;

webClient.post()
    .accept(MediaType.TEXT_EVENT_STREAM)
    .retrieve()
    .bodyToFlux(new ParameterizedTypeReference<ServerSentEvent<String>>() {})
    .mapNotNull(sse -> extractStreamChunk(sse.data())) // sse.data() уже содержит чистую строку (содержимое payload без префикса "data: ")
```

При таком подходе Spring использует `ServerSentEventHttpMessageReader`, который аккумулирует байты до встречи с разделителем `\n\n` (стандарт SSE), и только потом декодирует целое событие как одну строку UTF-8. Это полностью исключает риск разрыва символов.
