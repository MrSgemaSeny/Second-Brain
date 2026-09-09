# Рекомендательные системы в медиа и SaaS: TF-IDF, Коллаборативные профили и Культурный бустинг

## 1. Концепция гибридного ранжирования
В рекомендательных системах чистые подходы имеют системные недостатки:
- **Collaborative Filtering (Коллаборативная фильтрация):** Страдает от «холодного старта» для новых элементов и новых пользователей, требует плотной матрицы оценок.
- **Content-Based Filtering (Контентная фильтрация):** Рекомендует только очевидно похожие вещи (переобучение на одном жанре), не учитывает скрытые поведенческие сигналы.

В проекте testCinema (INSIGHT) реализован **гибридный пайплайн (Hybrid Discovery)**, объединяющий матричные вычисления признаков в памяти и коллаборативные сигналы досмотра.

---

## 2. Алгоритмическая цепочка

### 2.1. Контентная модель и взвешивание признаков
Для каждого фильма генерируется мета-строка, в которой ключевые семантические атрибуты искусственно амплифицируются повторением:
$$\text{Content} = 3 \times \text{Genre} + 2 \times \text{Director} + \text{Description} + \text{Actors}$$

Пример в Python:
```python
enriched_text = (
    (movie.genres_str + " ") * 3 +
    (movie.director + " ") * 2 +
    movie.description + " " +
    movie.actors_str
)
```
- **Векторизация:** `TfidfVectorizer(stop_words='english', ngram_range=(1, 2), max_features=8000)`.
- **Косинусная матрица:** `cosine_similarity(tfidf_matrix)` рассчитывается в оперативной памяти ($N \times N$) и дает возможность находить похожие картины за $O(1)$.

---

### 2.2. Коллаборативный вектор вкуса пользователя
Вместо бинарной фиксации факта просмотра, вектор интересов пользователя масштабируется по степени досмотра (Watch Completion Rate):
```python
user_vector = np.zeros(num_features)
for watch in user_watch_history:
    movie_vec = tfidf_matrix[watch.movie_index]
    if watch.completed:
        weight = 2.0  # Сильный позитивный сигнал
    else:
        # Линейный вес от 0.5 до 1.5 в зависимости от времени просмотра (до 2 часов)
        weight = 0.5 + min(watch.seconds_watched / 7200.0, 1.0)
    user_vector += movie_vec * weight
```

### 2.3. Неявные сигналы (Implicit Feedback)
Вектор обогащается без необходимости выставлять явные оценки:
1. **Клики (`movie_clicks`):** Коэффициент $0.3$ к жанровым признакам просмотренных карточек.
2. **Поиск (`search_logs`):** Сопоставление поисковых запросов со справочником жанров.
3. **Субтитры (`subtitle_events`):** Выбор языка дорожки `lang='kk'` повышает скоринг фильмов с казахской локализацией до $+30\%$.

---

### 2.4. Культурный бустинг и Diversity Guard
Для поддержки локального контента применяется адаптивный мультипликатор:
- $\ge 50\%$ просмотров отечественного кино $\implies \text{Score} \times 1.8$.
- $20\% - 50\%$ просмотров $\implies \text{Score} \times 1.4$.
- $< 20\%$ просмотров $\implies \text{Score} \times 1.15$.

**Diversity Guard (Защита от пузыря фильтрации):**
Чтобы рекомендательная лента не превратилась в монолитный список одного типа фильмов:
```python
def apply_diversity_guard(candidate_list, max_ratio=0.35):
    final_recs = []
    kz_count = 0
    max_kz = int(len(candidate_list) * max_ratio)
    
    for movie in candidate_list:
        if movie.is_domestic:
            if kz_count < max_kz:
                final_recs.append(movie)
                kz_count += 1
        else:
            final_recs.append(movie)
    return final_recs
```

---

## 3. Мониторинг конверсии (Realtime CTR)
Для объективной оценки качества моделей создана таблица впечатлений:
```sql
CREATE TABLE recommendation_impressions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    movie_id BIGINT NOT NULL,
    strategy VARCHAR(64) NOT NULL, -- 'hybrid', 'because-you-liked', 'franchise', 'trending'
    position INT NOT NULL,
    clicked BOOLEAN DEFAULT FALSE,
    shown_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    clicked_at TIMESTAMP
);
```
Расчет CTR по стратегиям:
$$\text{CTR} = \frac{\sum \text{clicked}}{\text{total impressions}} \times 100\%$$
Это позволяет в реальном времени видеть в панели администратора, какая стратегия дает максимальную вовлеченность.
