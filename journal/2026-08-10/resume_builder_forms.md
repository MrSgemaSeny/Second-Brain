# ResumeBuilder Forms and DragOverlay Fix
## Context
- The user reported that Drag and Drop was clipping/getting stuck in `ResumeBuilder`.
- The user reported that the generated PDF was empty and they could not find where to edit their Profile data.

## Actions Taken
- Fixed `dnd-kit` clipping by implementing `<DragOverlay>` to portallize dragged items over the layout.
- Designed and implemented CRUD editor forms (`AboutForm`, `ExperienceForm`, `EducationForm`, `SkillsForm`, `LanguagesForm`, `ProjectsForm`) within the `ResumeBuilder` sidebar.
- Mapped backend profile POST/PUT endpoints to React Query hooks in `useProfile.ts`.
- Integrated instant PDF re-rendering on successful form save.
- Cleaned up an accidental commit of `redis-server.exe` from Git history.

## Results
- Forms successfully render and edit the user profile.
- PDF dynamically updates.
- All tests pass (frontend builds successfully).

