# Антипаттерны и Опасности Hibernate (JPA)

## 1. N+1 Query Explosion при использовании MapStruct
**Суть:** Мапперы типа MapStruct (и Jackson при сериализации) автоматически обходят все getters объекта. Если сущность (например, `Profile`) имеет коллекции `@OneToMany` с дефолтной ленивой загрузкой (lazy fetch), то вызов `mapper.toDto(profile)` спровоцирует выполнение отдельного SELECT запроса для каждой коллекции.
**Пример ошибки:** Вызов `profileRepository.findById()` возвращает 1 сущность. В ней 5 коллекций. MapStruct обращается к каждой -> база получает 6 запросов (1+5). Если вытаскивать список из 20 профилей — база получает 120 запросов. СУБД ляжет.
**Как чинить:** 
- Для загрузки сущностей, которые пойдут в глубокий DTO (с коллекциями), **обязательно** использовать `@EntityGraph` в репозитории:
```java
@EntityGraph(attributePaths = {"experiences", "educations", "skills"})
Optional<Profile> findByUserId(Long userId);
```
- Либо писать кастомные `@Query` с `JOIN FETCH`.

## 2. Поломка Persistence Context (Orphan Removal vs Ручное удаление)
**Суть:** Когда дочерние коллекции замапплены с `cascade = CascadeType.ALL, orphanRemoval = true`, жизненный цикл дочерних сущностей полностью управляется Hibernate через состояние родительской коллекции.
**Пример ошибки:**
```java
// ОШИБКА: Ручное удаление через репозиторий ломает Persistence Context
projectRepository.deleteAll(toDelete);
profile.getProjects().removeAll(toDelete); 
```
Вызов `deleteAll` удаляет записи из БД напрямую, но Hibernate (из-за orphanRemoval) тоже попытается удалить объекты, так как они пропали из коллекции родителя. Это приводит к `ObjectDeletedException`, `ConcurrentModificationException` или отвалу транзакции.
**Как чинить:** Достаточно просто убрать элементы из коллекции родителя. Hibernate сам сделает `DELETE` в момент `flush` или `commit`.
```java
// ПРАВИЛЬНО: Делегировать удаление Hibernate
profile.getProjects().removeAll(toDelete);
```
