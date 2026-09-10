# MeDev — Session Context
**Date**: 2026-09-10  
**Purpose**: Resume Matcher analysis → MeDev feature roadmap  
**Status**: Context handoff for next session

---

## What Was Discussed

### 1. Resume Matcher (open-source project)
Reviewed `Resume-Matcher-main.zip` + `resume-matcher-audit.md`.

**Core concept**: single-use tool — upload resume + job description → get tailored resume. No auth, no storage, no accounts. Self-hosted. Stateless.

**Key patterns from the audit**:
- LiteLLM abstraction over multiple LLM providers (swappable)
- Jinja2 prompt templates (prompts as files, not hardcoded strings)
- Layered architecture: API → Service → LLM client
- No persistent state — each run is independent

---

### 2. MeDev vs Resume Matcher — Core Difference

| | Resume Matcher | MeDev |
|---|---|---|
| Type | Single-use tool | SaaS platform |
| State | Stateless | Full user profile, history, billing |
| Auth | None | JWT + OAuth2 GitHub/Google |
| Resume input | Upload PDF each time | Built from stored profile |
| AI usage | Adapt existing resume | Generate from scratch + adapt |
| Monetization | None (OSS) | Free/PRO subscription (Stripe + Kaspi) |

**Overlap**: resume adaptation to a job description. But Resume Matcher needs you to upload a PDF every time; MeDev already has your profile in the DB — it just needs to use it.

---

### 3. MeDev Current State (as of 2026-09-09 audit)

**Production**: Live (Level 4)  
**Backend**: `https://medev-backend.onrender.com/api`  
**Frontend**: `https://app.medev.mrsgemaseny.com` / `https://me-dev-two.vercel.app`  
**Stack**: Java 17 + Spring Boot 3.3.0 + PostgreSQL 17 + pgvector + Redis/Valkey 8.1.4 + React 19 + TypeScript + FSD + Tailwind v4  
**Migrations**: V1–V24 (Flyway)  
**Tests**: 66/66 E2E green (run against prod), 253/253 backend unit/integration green  
**Mobile**: M1–M4 Done (full responsive adaptation + safe-area + iOS auto-zoom guards)

**All 10 modules implemented**:
- `auth` — JWT (access 24h / refresh 30d in Redis), OAuth2 GitHub + Google, password reset
- `profile` — skills, experience, education, languages, projects, README, section reorder
- `resume` — Thymeleaf + Flying Saucer PDF, 6 templates, singlePage/multiPage
- `portfolio` — public page `/p/{username}`, L1 Caffeine + L2 Redis cache
- `tracker` — Job Tracker Kanban (WISHLIST/APPLIED/INTERVIEW/OFFER/REJECTED), scraper (HH, LinkedIn, Habr)
- `ai` — Groq SSE streaming chat, summary, project description, cover letter, tailor, match-job, parse-resume, LinkedIn export, onboarding
- `github` — GraphQL API, repo scoring (stars×0.35 + recency×0.30 + codeSize×0.20 + forks×0.15), README parsing
- `billing` — Stripe + KaspiPay, webhooks, PRO subscription
- `admin` — RBAC dashboard, user management, audit log viewer
- `shared` — JWT filter, IDOR protection via `SecurityUtils.getCurrentUserId()`, GlobalExceptionHandler, AuditService

---

### 4. Bugs Fixed in 2026-09-09 Audit Session (8 logical holes)

1. **AI fallback** — `cleanAndValidateJson` crashed on plain text from LinkedIn generator → added `buildFallbackParsedProfile()` safe fallback
2. **Flying Saucer templates** — all 6 templates migrated to table layout (CSS 2.1, no flex/grid/CSS vars)
3. **GitHub scoring** — was sorting by created_at (forks/empty repos first) → composite scoring algorithm
4. **Language/skill separation** — AI was putting Java/Python into "spoken languages" → blocklist in `LanguageService` + prompt rule + auto-migration to skills
5. **CORS / OAuth2** — OPTIONS blocked by Render env override; logout 403 from CSRF; Google OAuth linked wrong user via residual `medev_link_jwt` cookie → hardcoded whitelist, cookie cleanup on logout
6. **Scraper resilience** — `WebScraperService` only caught `IOException`, SSRF validation threw `IllegalArgumentException` → catch `Exception`, return graceful fallback
7. **Kanban status transitions** — allowed WISHLIST → OFFER directly → `validateStatusTransition()` guard added
8. **GlobalExceptionHandler** — inconsistent error shape (`error` vs `errors`) → unified `errorPayload(status, message)` factory

**CSP fix**: `frame-src blob:` missing in `vercel.json` → blocked blob iframe for PDF preview. Fixed by adding `frame-src 'self' blob: data:` and switching `ResumeBuilder.tsx` to `srcDoc`.

---

### 5. Known Open Issues (from epics)

**[WARNING] — affects monetization:**
- `ResumeController` PRO-gate is **inverted**: blocks templates whose name contains `'pro'` for everyone instead of blocking non-PRO users from PRO templates. Templates with `pro` in name are inaccessible to all.
- `/v1/ai/match-job` does NOT call `assertPro` — FREE users can match jobs unlimited. PRO gate inconsistent.

**[WARNING] — performance:**
- `structuredCompletion` uses `.block()` — synchronous call in reactive stack, will hit thread pool ceiling under load.

**[INFO] — tech debt:**
- `sanitize()` (prompt injection guard) only applied to chat; `jobDescription` in structured calls passed without length limit.
- `VectorizationService` deletes and re-adds all vectors on every profile update (no diff).
- JSON cleaning logic duplicated in `GroqClient` and `AiAnalysisService`.
- `max_tokens=2048` fixed — long generations may be truncated.

---

### 6. Existing AI Endpoints (relevant for roadmap)

| Endpoint | What it does | PRO-gated |
|---|---|---|
| `POST /v1/ai/tailor` | Adapt resume to job description | Yes |
| `POST /v1/ai/match-job` | Match score + feedback | **No (bug)** |
| `POST /v1/ai/cover-letter` | Generate cover letter for vacancy | Yes |
| `POST /v1/ai/generate/summary` | Generate profile summary | No |
| `POST /v1/ai/generate/project-description` | Generate project description | No |
| `POST /v1/ai/chat/stream` | SSE chat with AI assistant | No |
| `POST /v1/ai/parse-resume` | Extract profile from PDF | No |

**Key insight**: `/v1/ai/tailor` already exists and works. It takes a job description and returns adapted resume content. The Job Tracker already stores job descriptions (scraped from HH/LinkedIn). **These two are not connected yet.**

---

### 7. Proposed Roadmap (from this session)

#### Sprint 1 — Fix monetization bugs (1-2 days)
- Fix PRO-gate inversion in `ResumeController` (1 line change)
- Add `assertPro` to `/v1/ai/match-job`

#### Sprint 2 — Killer feature: "Tailor resume to this job" (2-3 days)
**Backend**: zero work needed — `/v1/ai/tailor` already exists  
**Frontend**: add "Tailor Resume" button to Job Tracker card → sends `jobDescription` from the card to `/ai/tailor` → shows result in modal or opens Resume Builder with pre-filled content  
**Why this matters**: Resume Matcher's entire purpose (adapt resume to JD) becomes a one-click feature inside MeDev, with the advantage that the profile data is already in the DB — no file upload needed.

#### Sprint 3 — RAG semantic job matching (5-7 days)
**Infrastructure already in place**: pgvector (V18 migration), HNSW index, `VectorizationService`  
**What's missing**: endpoint to find jobs from tracker that match the user's profile semantically  
**Approach**: vectorize job descriptions on save → find nearest neighbors to profile embedding → surface "best match" ranking in tracker UI

#### Sprint 4 — Async PDF (when load demands it)
Replace `.block()` in `structuredCompletion` with async execution via `ThreadPoolTaskExecutor`. Return `202 Accepted` + poll or SSE for result. Not urgent until real traffic.

#### Sprint 5 — Observability (infrastructure)
- Sentry for frontend error tracking
- Prometheus metrics via Spring Actuator (already exposed, needs scraper)
- Nightly DB dump to Cloudflare R2 via GitHub Actions cron
- Uptime pings to prevent Render free tier sleep

---

### 8. Architecture Notes

**pgvector setup** (V18): 384-dimensional vectors, HNSW index, cosine similarity. `VectorizationService` is event-driven and async. Current flaw: full delete+re-add on every profile update instead of diff-based update.

**AI resilience**: Resilience4j CircuitBreaker + Retry (4 attempts, 4-20s backoff, only for 429/5xx). Rate limits: FREE=10 req/day, PRO=100 req/day, TTL 24h in Redis, plan cache 15min.

**Email**: not implemented yet. Password reset generates Redis token only, no SMTP. When adding: must use `@TransactionalEventListener(phase = AFTER_COMMIT)` + `@Async` to avoid HikariCP exhaustion inside `@Transactional`.

**Flying Saucer constraint**: CSS 2.1 only. No flex, no grid, no CSS variables. All 6 templates use table layout with inline hex colors. `phub-orange` does not support text rotation in PDF.

---

## Next Session Starting Point

Pick one of:
1. Fix the two monetization [WARNING]s — small, high impact
2. Build "Tailor to this job" button in tracker UI — medium effort, killer feature
3. Discuss RAG matching architecture before implementing

Files to reference if needed:
- `backend/src/main/java/com/medev/modules/resume/controller/ResumeController.java` — PRO-gate bug
- `backend/src/main/java/com/medev/modules/ai/controller/AiController.java` — match-job missing assertPro
- `frontend/src/features/job-tracker/ui/KanbanBoard.tsx` — where to add Tailor button
- `backend/src/main/java/com/medev/modules/ai/service/AiApplicationService.java` — tailor logic
- `Epics/Plan/Epic-05-ai/epic.md` — full AI module documentation
- `Epics/Plan/Epic-07-tracker/epic.md` — full tracker documentation
- `AUDIT_REPORT_2026-09-09.md` — last full audit with all 8 fixes documented
