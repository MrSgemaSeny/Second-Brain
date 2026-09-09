# Фронтенд-инженерия медиа: Кастомный плеер и RAF Scroll Restoration

## 1. Контекст
В мультимедийных веб-приложениях (testCinema / INSIGHT) стандартные UI-решения из npm пакетов часто создают неконтролируемые проблемы:
1. Сторонние плееры (Video.js, Plyr) содержат избыточный бандл, жестко управляют DOM-деревом и сбрасывают буферизованный видеопоток при малейшем обновлении родительских React-пропсов (например, при смене языка интерфейса).
2. Браузерный скролл при переходе «Назад» в SPA с асинхронными запросами (React Query) срабатывает до того, как карточки фильмов отрисовались, из-за чего страница дергается и прокручивается в самый верх (Scroll Jump).

---

## 2. Кастомный HTML5-плеер (`PlayerSurface.jsx`)

### 2.1. Защита от сброса воспроизведения через `useRef`
При изменении состояния интернационализации (`i18n` / `t` функция) ре-рендер компонента не должен перезагружать тег `<video>`:
```javascript
// Сохраняем ссылку на функцию перевода в ref, чтобы не триггерить пересоздание эффектов плеера
const tRef = useRef(t);
useEffect(() => {
    tRef.current = t;
}, [t]);
```

### 2.2. Heartbeat и античит-телеметрия
Каждые 5-10 секунд плеер отправляет сигнал на сервер:
```javascript
useEffect(() => {
    const interval = setInterval(() => {
        if (!videoRef.current || videoRef.current.paused) return;
        
        const currentTime = Math.floor(videoRef.current.currentTime);
        // Сохранение в LocalStorage для продолжения с места остановки
        localStorage.setItem(`resume_${movieId}`, currentTime);
        
        // Отправка сигнала серверу
        api.post('/watch-history/beat', {
            movieId,
            secondsWatched: currentTime,
            deltaSeconds: 10
        }).catch(() => {});
    }, 10000);
    
    return () => clearInterval(interval);
}, [movieId]);
```
На бэкенде действует античит-ограничение: дельта просмотра жестко зажата в диапазоне `0..30` секунд, исключая искусственную накрутку просмотров через API.

---

## 3. Алгоритмический ScrollManager на базе `requestAnimationFrame`

Стандартное поведение браузера отключается:
```javascript
window.history.scrollRestoration = "manual";
```

### Реализация плавного удержания скролла:
```javascript
// ScrollManager.jsx
export function useScrollRestoration() {
    const location = useLocation();

    useEffect(() => {
        const savedPosition = sessionStorage.getItem(`scroll_${location.key}`);
        if (!savedPosition) {
            window.scrollTo(0, 0);
            return;
        }

        const targetY = parseInt(savedPosition, 10);
        let userInterrupted = false;

        // Прерывание при любом физическом действии пользователя
        const cancelHandler = () => { userInterrupted = true; };
        window.addEventListener('wheel', cancelHandler, { passive: true });
        window.addEventListener('touchstart', cancelHandler, { passive: true });
        window.addEventListener('keydown', cancelHandler, { passive: true });

        const startTime = performance.now();
        const timeoutMs = 3000; // Держим до 3 секунд, пока React Query рендерит карточки

        function step(now) {
            if (userInterrupted) {
                cleanup();
                return;
            }

            // Пытаемся доскроллить до нужной координаты
            window.scrollTo(0, targetY);

            // Если высота страницы уже достаточна и скролл встал на место
            if (Math.abs(window.scrollY - targetY) < 5 || (now - startTime > timeoutMs)) {
                cleanup();
            } else {
                requestAnimationFrame(step);
            }
        }

        function cleanup() {
            window.removeEventListener('wheel', cancelHandler);
            window.removeEventListener('touchstart', cancelHandler);
            window.removeEventListener('keydown', cancelHandler);
        }

        requestAnimationFrame(step);

        return cleanup;
    }, [location]);
}
```

## 4. Итог
- Кастомный плеер на базе чистого HTML5 API обеспечивает тотальный контроль над горячими клавишами, субтитрами и метриками.
- Алгоритмический скролл-менеджер полностью ликвидирует баг «прыжка» страницы при возврате назад в асинхронных каталогах контента.
