# Frontend Architecture (FSD) and UI/UX Patterns

Extracted from "Envie" and "Valeur" projects.

## 1. Feature-Sliced Design (FSD)
FSD is adopted to prevent spaghetti code by organizing code strictly by domain features rather than tech types.
- **app/**: Global setup (Router, Store, Theme).
- **pages/**: Application screens (e.g., `LandingPage`, `BoardPage`).
- **widgets/**: Independent, complex blocks that combine multiple features (e.g., `Sidebar`, `TaskBoard`).
- **features/**: User interactions or business actions (e.g., `create-note`, `task-dnd`).
- **entities/**: Business domains/models and their UI representations (e.g., `NoteCard` that only renders, without deletion logic).
- **shared/**: Reusable UI kits (`Button`, `Input`), API configs, utility functions (`cn.ts`).

## 2. UI/UX Principles (Emil Kowalski style)
- **Performance-First Animations:** Strict prohibition of animating layout properties (width, height, margin) via `transition-all` as it triggers browser Reflows and drops FPS. Exclusively use `transition-transform` and `transition-opacity`.
- **Easing:** Always use `ease-out` (or custom cubic-bezier). UI elements should appear fast and smoothly decelerate. Never use `ease-in`.
- **Micro-interactions:** Interactive elements must feel tactile. Use `active:scale-95` to create a "pressed-in" physical effect for buttons.
- **Data Density:** B2B interfaces must balance showing high volumes of data (tables/Kanbans) without clutter. Achieved via compact typography and precise padding.

## 3. Visual Aesthetics
- **Monochrome & Subtlety:** Avoid cheap/loud colors. Build on a monochromatic base (`#0A0A0A` backgrounds, `#EDEDED` text). Use varying opacity (`10%`, `50%`) of white for accents.
- **Glassmorphism:** Extensive use of blurred backdrops (`backdrop-blur-md` with `bg-white/5`) to float panels over backgrounds.
- **Typography:** Premium fonts (Vercel Geist Sans/Mono) with no emojis (emojis cheapen the corporate/pro feel). Use strict line icons (Lucide React).
- **Dual-Layer Wallpapers:** Background videos/GIFs are blurred and darkened (`filter: blur(40px) brightness(0.4)`) on a back layer to provide a dynamic but non-distracting atmosphere, with a clear central UI layout overlay.
