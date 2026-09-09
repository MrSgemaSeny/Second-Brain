# Промышленный конвейер локализации субтитров через LLM: TagPreservator, Alignment и Batch API

## 1. Проблематика субтитров в NLP
Субтитры — это не обычный плоский текст. Они представляют собой строгий временной протокол (SRT/WebVTT), в котором:
1. Каждая реплика жестко привязана к миллисекундам экрана (`00:01:23.400 --> 00:01:26.800`).
2. Внутри реплик содержатся HTML-подобные теги курсива (`<i>голос за кадром</i>`), жирности (`<b>`), цветов (`<font color="#ffff00">`) или музыкальных нот (`♪`).
3. Языковые модели (GPT-4, Claude, Gemini) имеют привычку перефразировать диалоги, объединять две короткие строки в одну длинную или выбрасывать теги, что мгновенно разрушает тайминги и разметку видеоплеера.

---

## 2. Архитектура микросервиса `subtitle-translator`

```
  [ Исходный файл WebVTT / SRT ]
                │
                ▼
       [ TagPreservator ] 
       - Извлечение тегов: <i>, <b>, ♪
       - Замена на плейсхолдеры: <0>, <1>, <2>
                │
                ▼
       [ Чанкование по репликам ] (по 40-60 строк диалогов)
                │
                ▼
   ┌────────────┴────────────┐
   ▼                         ▼
[ Google Gemini Flash ]   [ OpenAI Batch API ]
(Срочный перевод)         (Фоновый перевод со скидкой 50%)
   └────────────┬────────────┘
                │
                ▼
     [ TranslationValidator ]
     1. Alignment Check: len(translated) == len(original)
     2. Non-Empty Check: нет пустых пропущенных строк
     3. Latin Leakage Check: нет непереведенного английского текста
                │
                ▼
     [ Детокенизация тегов ]
     - Замена <0> -> <i>, <1> -> </i>
     - Вычищение галлюцинированных тегов
                │
                ▼
     [ Сборка готового VTT ] ──(Webhook POST)──► [ Java Backend ]
```

---

## 3. Детали алгоритмических узлов

### 3.1. TagPreservator (Python)
```python
import re

class TagPreservator:
    TAG_REGEX = re.compile(r'(</?[a-zA-Z][^>]*>|♪|&[a-zA-Z]+;)')

    def tokenize(self, text: str) -> tuple[str, list[str]]:
        tags = []
        def replacer(match):
            tags.append(match.group(0))
            return f"<{len(tags) - 1}>"
        
        tokenized_text = self.TAG_REGEX.sub(replacer, text)
        return tokenized_text, tags

    def detokenize(self, text: str, tags: list[str]) -> str:
        for idx, tag in enumerate(tags):
            text = text.replace(f"<{idx}>", tag)
        # Удаление галлюцинированных моделью токенов <99>
        text = re.sub(r'<\d+>', '', text)
        return text
```

### 3.2. TranslationValidator
```python
class TranslationValidator:
    @staticmethod
    def validate_alignment(original_lines: list[str], translated_lines: list[str]):
        if len(original_lines) != len(translated_lines):
            raise AlignmentError(
                f"Строк на входе: {len(original_lines)}, на выходе: {len(translated_lines)}"
            )

    @staticmethod
    def detect_latin_leakage(text: str, whitelist: set[str], movie_glossary: set[str]) -> bool:
        words = re.findall(r'\b[A-Za-z]{4,}\b', text)
        for word in words:
            word_lower = word.lower()
            if word_lower not in whitelist and word_lower not in movie_glossary:
                return True # Обнаружена утечка непереведенного текста
        return False
```

---

## 4. Экономика и Batch API
Для снижения затрат на перевод каталога фильмов:
- **Синхронный API:** Стоимость обработки 2 000 строк фильма на GPT-4o-mini составляет ~$0.05 – $0.10.
- **OpenAI Batch API:** Предоставляет **50% скидку** на все токены при условии выполнения задачи в течение 24 часов. Воркер формирует `.jsonl` файл со всеми чанками фильма и отправляет батч, опрашивая статус раз в час.

## 5. Итог
Паттерн токенизации тегов + жесткая проверка выравнивания строк — обязательный золотой стандарт для любых промышленных задач генеративного перевода структурированных документов (субтитры, код, Markdown с разметкой).
