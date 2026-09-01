# Эволюция Lifecycle Hooks и Guardrails в Antigravity / .agents

## Контекст и Предыстория (3 месяца использования)
На ранних этапах работы с AI-агентами (Cursor, Antigravity, Claude Code) дисциплина работы с гитом и журналом поддерживалась двумя базовыми скриптами: `reminder.ps1` и `git-reminder.ps1`. Они успешно служили напоминанием о правиле **«ТЕСТЫ -> ЖУРНАЛ -> GIT PUSH»** на протяжении 3 месяцев.

## Исходный код скриптов (Архив)

### 1. `reminder.ps1` (Статическое напоминание о Second Brain и Journal)
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$today = Get-Date -Format "yyyy-MM-dd"
$journalPath = "C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain\journal\$today\mrdevcourses.md"

$response = @{
    injectSteps = @(
        @{
            ephemeralMessage = "CRITICAL WORKFLOW RULES:`n1. JOURNAL & PUSH: You must always run git add, git commit, git push and update the journal ($journalPath) after completing any stage or task.`n2. SECOND BRAIN: If you learn important project info, make architectural decisions, or discover critical debt, YOU MUST document it in the Second Brain (the context/ folder or mrdevcourses.md) so it isn't lost."
        }
    )
}

$response | ConvertTo-Json -Compress | Write-Output
exit 0
```

### 2. `git-reminder.ps1` (Мягкое предупреждение о незакоммиченных изменениях)
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$rawInput = ""
if ([Console]::IsInputRedirected) {
    $rawInput = [Console]::In.ReadToEnd()
}

$injectSteps = @()

Push-Location "C:\Users\murat\IdeaProjects\new_world\MrDevCourses"
$repoStatus = git status --porcelain 2>$null
$repoUnpushed = git cherry -v 2>$null
Pop-Location

Push-Location "C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain"
$brainStatus = git status --porcelain 2>$null
$brainUnpushed = git cherry -v 2>$null
Pop-Location

if ($repoStatus -or $repoUnpushed -or $brainStatus -or $brainUnpushed) {
    $reason = "[WARNING] Не забывай про Workflow: ТЕСТЫ → ЖУРНАЛ → GIT PUSH. У тебя есть незакоммиченные или неотправленные изменения. Ты можешь остановиться, чтобы задать вопрос пользователю, но НЕ ЗАБУДЬ сделать push перед финальным завершением задачи!"
    $injectSteps += @{ ephemeralMessage = $reason }
}

@{ injectSteps = $injectSteps } | ConvertTo-Json -Depth 10 -Compress | Write-Output
```

---

## Архитектурная эволюция (Переход к Hard Guardrails)

Пассивные текстовые напоминания (soft reminders) со временем теряли эффективность в длинных диалогах. Была спроектирована система **жестких барьеров (hard barriers)**:

1. **`pre-invocation.ps1` (Динамический Context Injector)**:
   - При старте сессии (`invocationNum == 1`) загружает полный контекст `CONTEXT.md` и ключевые файлы Second Brain (`me.md`, `projects.md`, `rules.md`).
   - На повторных шагах (`invocationNum > 1`) вставляет легковесный маркер `[AI GUARD] Active Session. Directives: Zero emojis | Use native API tools | Strict Level-3 scope.`
   - Контролирует лимит размера `CONTEXT.md` (до 200 строк).

2. **`stop-check-commits.ps1` (Stop Hook Barrier)**:
   - Физически блокирует завершение работы агента (`decision: continue`), если в основном репозитории или Second Brain остались незакоммиченные файлы.

3. **`enforce-workflow.ps1` (PreToolUse Barrier)**:
   - Перехватывает вызов `git push` и запрещает отправку (`decision: deny`), если за текущие/последние 24 часа нет записи в журнале разработки.

4. **`safety-gate.ps1` (Tool Discipline Gate)**:
   - Блокирует попытки вызова CLI-утилит (`cat`, `grep`, `Get-Content`, `Select-String`, `dir`) в пользу нативных API-инструментов, экономя токены.

5. **`prompt-guard.ps1` (PowerShell Profile Stderr Injection)**:
   - На уровне шелла внедряет напоминание в поток `stderr` через `prompt`, сохраняя нулевую деградацию контекста при любых сценариях.
