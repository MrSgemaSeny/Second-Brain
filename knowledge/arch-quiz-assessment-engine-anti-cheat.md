# Архитектура интерактивных квизов и защита от списывания (Anti-Cheat)

## Проблема утечки ответов
В традиционных веб-приложениях фронтенд часто запрашивает весь объект теста с флагами `isCorrect: true/false`. Даже если эти флаги скрыты в UI, студент может открыть DevTools (Network tab) и мгновенно увидеть правильные варианты ответов.

## Решение: Раздельные DTO и серверная проверка

### 1. Маскировка на уровне публичного API (`QuizDto`)
При запросе квиза урока `GET /api/v1/lessons/{lessonId}/quiz`:
- Бэкенд возвращает список вопросов и вариантов ответов **БЕЗ** поля `isCorrect`.
- Поле `explanation` также скрыто до момента завершения попытки.

```typescript
// Публичный DTO для студента (shared/types)
export interface QuizQuestionOptionDto {
  id: number;
  text: string;
  // isCorrect отсутствует!
}
```

### 2. Серверная проверка попытки (`POST /api/v1/lessons/{lessonId}/quiz/submit`)
Студент отправляет массив выбранных `optionIds`:
```json
{
  "answers": [
    { "questionId": 101, "selectedOptionId": 502 },
    { "questionId": 102, "selectedOptionId": 506 }
  ]
}
```

Бэкенд в транзакции:
1. Загружает сущность `Quiz` с вопросами и правильными ответами из БД.
2. Проверяет каждый ответ: `selectedOption.isCorrect == true`.
3. Подсчитывает процент правильных ответов: `(correctCount / totalQuestions) * 100`.
4. Сохраняет результат в таблицу `quiz_submissions`.
5. Если процент `>= passingScore` (по умолчанию 70%), урок автоматически помечается завершённым.
6. Возвращает `QuizResultDto`, который **только теперь** содержит объяснения (`explanation`) и разбор ошибок.

## Особенности JPA Cascading
При создании или редактировании квиза администратором:
- Включается `cascade = CascadeType.ALL` и `orphanRemoval = true` на коллекциях вопросов и опций.
- Для предотвращения конфликтов версий Hibernate используется атомарная очистка:
  ```java
  quiz.getQuestions().clear();
  // добавление новых вопросов
  quizRepository.saveAndFlush(quiz);
  ```
