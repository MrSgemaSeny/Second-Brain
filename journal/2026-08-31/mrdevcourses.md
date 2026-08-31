# MrDevCourses — 2026-08-31

## Code Review (5-axis: Security + Architecture + Correctness + Readability + Performance)

### Результат: 3 Critical, 6 Required, 5 Optional, 3 Nit

### Critical
1. `POST /v1/projects/{id}/like` — permitAll без auth, бот-накрутка лайков
2. Drip Content вычисляется в Java (calculateUnlockTime) вместо SQL контракта
3. Frontend: нет `<Suspense>` для lazy-загружаемых protected-роутов — crash

### Required
1. Hardcoded JWT fallback secret в application.yml и JwtTokenProvider
2. Unbounded queries в AdminService (findAll без Pageable)
3. AdminService — God Object (нарушение SRP)
4. Frontend: отсутствие onError в useQuery/useMutation хуках
5. TypeScript: `any` типы в catch-блоках и map callbacks
6. FSD: entities root exports, widget-to-widget импорты

### Security Posture (Positive)
- IDOR защита на всех 11 student-facing контроллерах (SecurityUtils.getCurrentUserId)
- JWT httpOnly cookie (Secure+SameSite в prod)
- 3-tier Bucket4j rate limiting (AUTH/AI/GENERAL)
- BCrypt, CSP headers, anti-enumeration login
- Secrets в env vars (prod), Actuator ограничен

### Незакоммиченные pre-existing файлы (НЕ от ревью-сессии)
- `frontend/src/pages/course/CourseDetailPage.tsx`
- `frontend/src/widgets/course-sidebar/CourseStickyCard.tsx`
- `frontend/src/widgets/course-sidebar/CourseStickyCard.test.tsx`

### Статус
- Сессия: read-only code review, проектные файлы НЕ изменялись
- Артефакт: полный отчет в brain artifacts