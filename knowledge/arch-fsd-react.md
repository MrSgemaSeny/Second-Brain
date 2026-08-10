# Feature-Sliced Design (FSD) in React

## Overview
The frontend architecture follows the Feature-Sliced Design (FSD) methodology, which solves the problem of code organization in large React applications.

## Layers
- **app/**: Application initialization, context providers (AuthContext, QueryClientProvider), router.
- **pages/**: Application pages corresponding to router routes (e.g., LoginPage, DashboardPage).
- **widgets/**: Large, independent UI blocks used across multiple pages (e.g., TaskKanbanBoard, DocumentViewer).
- **features/**: User scenarios encapsulating feature logic (e.g., auth, contact-form, 2fa-setup).
- **entities/**: Business entities with their models, API clients, and React Query hooks (e.g., task, client, user).
- **shared/**: Reusable code across all layers: API/HTTP wrappers, basic UI components, utilities, and localization (i18n).

## Key Benefits
- **Modularity**: Code is decoupled based on business logic.
- **Reusability**: Shared components and entities can be easily used across different features.
- **Maintainability**: Simplifies navigation and scaling in large codebases.
