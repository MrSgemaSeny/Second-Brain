# Концепция: Исключение N+1 Проблем в Hibernate/JPA

## Суть проблемы N+1
При загрузке списка из $N$ сущностей, содержащих ленивые связи (`@OneToMany`, `@ManyToOne`), Hibernate выполняет 1 начальный запрос и затем $N$ дополнительных запросов для каждой дочерней коллекции в цикле.

## Стратегии ликвидации N+1:

### 1. `@EntityGraph` (Eager Fetch через JOIN)
Используется для единичных связей `1:1` или `Many:1`, а также для одной коллекции `1:N`:
```java
@EntityGraph(attributePaths = {"modules", "modules.lessons"})
Optional<Course> findWithCurriculumById(Long id);
```

### 2. `@BatchSize` (Пакетная выборка IN (...))
Идеально для нескольких параллельных коллекций `1:N`, чтобы избежать декартова произведения (`MultipleBagFetchException`):
```java
@BatchSize(size = 25)
@OneToMany(mappedBy = "course")
private List<CourseModule> modules;
```

### 3. DTO Проекции
Выборка только необходимых колонок через конструкторы `new com.mrdev.dto.SummaryDto(c.id, c.title)` полностью минует Hibernate Entity Snapshot и кэш первого уровня, работая в 5–10 раз быстрее.
