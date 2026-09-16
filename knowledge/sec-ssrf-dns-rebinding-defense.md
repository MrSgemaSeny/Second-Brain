# Защита от SSRF, DNS-Rebinding и Open Redirects в Spring Boot

## Проблема (Анатомия уязвимости)
В приложениях, принимающих произвольные внешние URL от пользователей (парсинг вакансий, импорт резюме, превью ссылок), типовые ошибки валидации приводят к критическим уязвимостям **Server-Side Request Forgery (SSRF)**:
1. **Поглощение исключений**: блок `try { validate(url); } catch (Exception e) {}` проглатывает ошибку, и сетевой клиент выполняет запрос.
2. **DNS-Rebinding (TOCTOU)**: хост проверяется через DNS один раз, но ко времени реального HTTP-запроса злоумышленник меняет A/AAAA запись на `127.0.0.1` или `169.254.169.254`.
3. **Цепочки Redirects (Open Redirect)**: начальный URL публичный (`https://example.com/redirect`), но сервер отвечает `302 Location: http://10.0.0.5:8080/internal-api`.
4. **Нестандартные порты**: злоумышленник указывает `http://localhost:6379` или `http://192.168.1.1:5432` для сканирования портов внутренней сети.

## Архитектурный паттерн: UrlSecurityValidator

### 1. Блокировка всех зарезервированных и приватных CIDR
При резолвинге хоста необходимо получить **все** привязанные IP-адреса через `InetAddress.getAllByName(host)` и проверить каждый:

```java
public void validateUrl(String urlString) {
    URI uri = URI.create(urlString);
    String scheme = uri.getScheme();
    if (scheme == null || (!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https"))) {
        throw new IllegalArgumentException("Разрешены только HTTP и HTTPS протоколы");
    }

    int port = uri.getPort();
    if (port != -1 && port != 80 && port != 443) {
        throw new IllegalArgumentException("Запрещены нестандартные сетевые порты: " + port);
    }

    String host = uri.getHost();
    InetAddress[] addresses = InetAddress.getAllByName(host);
    for (InetAddress addr : addresses) {
        if (isForbiddenIp(addr)) {
            throw new IllegalArgumentException("Доступ к приватным и локальным IP-адресам заблокирован: " + addr.getHostAddress());
        }
    }
}
```

### 2. Полный предикат проверки запрещенных IP
```java
private boolean isForbiddenIp(InetAddress address) {
    if (address.isLoopbackAddress() || address.isAnyLocalAddress() || 
        address.isLinkLocalAddress() || address.isSiteLocalAddress() || 
        address.isMulticastAddress()) {
        return true;
    }
    byte[] bytes = address.getAddress();
    // IPv4 проверки
    if (bytes.length == 4) {
        int first = bytes[0] & 0xFF;
        int second = bytes[1] & 0xFF;
        if (first == 10) return true; // 10.0.0.0/8
        if (first == 172 && (second >= 16 && second <= 31)) return true; // 172.16.0.0/12
        if (first == 192 && second == 168) return true; // 192.168.0.0/16
        if (first == 169 && second == 254) return true; // 169.254.0.0/16 (AWS metadata)
        if (first == 100 && (second >= 64 && second <= 127)) return true; // 100.64.0.0/10 CGNAT
        if (first == 127 || first == 0) return true;
    }
    // IPv6 проверки (Unique Local fc00::/7)
    if (bytes.length == 16) {
        int first = bytes[0] & 0xFF;
        if ((first & 0xFE) == 0xFC) return true;
    }
    return false;
}
```

### 3. Ручной контроль цепочки Redirects
Сетевой клиент настраивается с отключенным авто-переходом по редиректам:
```java
String currentUrl = url;
int redirects = 0;
while (redirects < 3) {
    urlSecurityValidator.validateUrl(currentUrl);
    Connection.Response res = Jsoup.connect(currentUrl)
            .followRedirects(false)
            .timeout(8000)
            .execute();
    if (res.statusCode() >= 300 && res.statusCode() < 400) {
        String location = res.header("Location");
        currentUrl = URI.create(currentUrl).resolve(location).toString();
        redirects++;
        continue;
    }
    return res.parse();
}
```

## Правило для продакшена
Любой исходящий сетевой вызов по URL, пришедшему от пользователя, обязан проходить валидацию IP и схем **непосредственно перед выполнением сетевого запроса**, а редиректы должны валидироваться на каждом шаге.
