# Antigravity Hooks: Исполнение протокола (Post-Execution)

## Проблема
AI (Antigravity) склонен к "туннельному зрению" при выполнении задач и может забыть записать изменения в журнал (`Brain's Protocol`) или сделать `git push` перед тем, как отдать ответ пользователю и перейти в режим ожидания.

## Решение
Используется механизм **Lifecycle Hooks** системы Antigravity (файл `.agents/hooks.json`), чтобы перехватывать системное событие `Stop` (остановка агента). 

Скрипт проверяет наличие незакоммиченных и неотправленных файлов через PowerShell. Если они есть, агент насильно блокируется от остановки и заставляется сделать `push`.

## Конфигурация
**1. `.agents/hooks.json`**
```json
{
  "enforce-brains-protocol": {
    "Stop": [
      {
        "type": "command",
        "command": "powershell.exe -ExecutionPolicy Bypass -NoProfile -File scripts/check-protocol.ps1"
      }
    ]
  }
}
```

**2. `.agents/scripts/check-protocol.ps1`**
```powershell
$inputJson = [Console]::In.ReadToEnd()

# 1. Check MeDev (current repo)
$medevStatus = git status --porcelain
$medevUnpushed = git cherry -v 2>$null

# 2. Check Second-Brain
Push-Location "..\Brain's protocol - second brain"
$brainStatus = git status --porcelain
$brainUnpushed = git cherry -v 2>$null
Pop-Location

if ($medevStatus -or $medevUnpushed -or $brainStatus -or $brainUnpushed) {
    $reason = "[CRITICAL] PROTOCOL VIOLATION: You have uncommitted or unpushed changes in MeDev or Second-Brain! You MUST update the journal, run git add/commit, and push both repositories to remote before stopping."
    $response = @{
        decision = "continue"
        reason = $reason
    }
    $response | ConvertTo-Json -Compress | Write-Output
} else {
    $response = @{
        decision = "stop"
    }
    $response | ConvertTo-Json -Compress | Write-Output
}
```

## Эффект
Каждый раз, когда агент пытается завершить свой ход (перестать вызывать тулзы) с измененными файлами, скрипт возвращает `{"decision": "continue", "reason": "PROTOCOL VIOLATION..."}`, что внедряется агенту как High Priority системное сообщение. Агент "просыпается", читает предупреждение, пишет журнал, коммитит, пушит и только потом может нормально остановиться.
