# Resume PDF SpEL Fix & Data Integrity

## Context
1. **Issue:** Generated PDFs were failing to load, throwing `TemplateProcessingException` due to a SpringEL error: `Exception evaluating SpringEL expression: "proj.githubUrl && proj.liveUrl"`.
2. **Issue:** Re-parsing resumes with AI was wiping out existing collections (e.g., educations, experiences) if the AI failed to generate those specific arrays, due to aggressive clearing in `ProfileService.importParsedResume`.

## Actions Taken
- **Templates (SpEL):** Fixed `classic.html`, `minimal.html`, and `modern.html`. Replaced the JavaScript-style boolean evaluation `th:if="${proj.githubUrl && proj.liveUrl}"` with strict Java/SpEL null and empty string checks:
  `th:if="${proj.githubUrl != null and !proj.githubUrl.isEmpty() and proj.liveUrl != null and !proj.liveUrl.isEmpty()}"`
- **Data Integrity:** Modified `ProfileService.importParsedResume` to only clear collections (educations, experiences, languages, projects, skills) if the incoming `ResumeParsingResponse` actually contains a non-null, non-empty list for that specific collection. This prevents the loss of user data on partial AI parsing failures.

## Impact
- PDF generation (Flying Saucer + Thymeleaf) no longer fails on template evaluation for projects.
- AI resume data import is safer and doesn't destroy existing sections if the AI omits them.
