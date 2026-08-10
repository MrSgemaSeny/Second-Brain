# Career Portal & ATS (Applicant Tracking System) Design

Based on the architectural retrospective of the "Career Hub" project.

## 1. Core Functionality & User Roles
- **Candidates:** Interfaces for browsing jobs, submitting applications, building digital CVs, and tracking application statuses.
- **Recruiters (HR):** Tools for posting jobs, screening candidates, managing the hiring funnel (Kanban), and analytics.

## 2. Business Modules
- **ATS Board (Kanban):** A drag-and-drop pipeline representing the hiring funnel (e.g., Sourced -> Screening -> Technical Interview -> Cultural Fit -> Offer).
- **CV Viewer & Scorecard:** A side-by-side interface for technical reviews. The left pane shows a PDF viewer of the resume, while the right pane contains a scorecard with specific criteria (e.g., Java, React, SQL) to calculate an "Overall Fit" score.
- **HR Analytics Dashboard:** Visualizes metrics like Time-to-Hire, Cost-per-Hire, and Funnel Conversion Rates (using Recharts or Chart.js).

## 3. Post-Mortem & Architectural Pitfalls to Avoid
- **Avoid 100% Client-Side Logic:** Doing complex filtering (e.g., `Array.filter` on candidate lists) entirely on the frontend works for prototypes but crashes the browser when scaling (10,000+ records). Such operations must be offloaded to the backend (e.g., Elasticsearch).
- **Mandatory Real-Time Sync (WebSockets):** Shared Kanban boards without real-time synchronization lead to "Lost Updates" where recruiters overwrite each other's changes. WebSockets are strictly required for ATS boards.
- **State Management:** Avoid "spaghetti state" in Redux when managing complex drag-and-drop actions. Opt for optimistic UI updates coupled with robust server state synchronization (e.g., React Query).
