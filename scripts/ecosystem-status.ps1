param (
    [string]$ProjectRoot = "C:\Users\murat\IdeaProjects\new_world\MrDevCourses",
    [string]$BrainRoot = "C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       MR DEVELOPER ECOSYSTEM STATUS DASHBOARD            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Memory Health
$memScript = Join-Path $BrainRoot "scripts\memory-manager.ps1"
if (Test-Path $memScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $memScript
}

# 2. Git Status Check across Repos
Write-Host "`n[GIT STATUS REPORT]" -ForegroundColor Yellow
$repos = @(
    @{ Name = "MrDevCourses"; Path = $ProjectRoot },
    @{ Name = "Second Brain"; Path = $BrainRoot }
)

foreach ($repo in $repos) {
    if (Test-Path $repo.Path) {
        $status = git -C $repo.Path status --porcelain
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Host "  $($repo.Name): [CLEAN] Working tree is fully committed." -ForegroundColor Green
        } else {
            Write-Host "  $($repo.Name): [DIRTY] Uncommitted changes detected!" -ForegroundColor Red
            $status | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
        }
    }
}

# 3. Journal Check for Today
$today = (Get-Date).ToString("yyyy-MM-dd")
$todayJournal = Join-Path $BrainRoot "journal\$today\mrdevcourses.md"
Write-Host "`n[DAILY JOURNAL CHECK]" -ForegroundColor Yellow
if (Test-Path $todayJournal) {
    $lines = (Get-Content $todayJournal -Encoding UTF8).Count
    Write-Host "  Today's Journal ($today): [OK] Found ($lines lines)." -ForegroundColor Green
} else {
    Write-Host "  Today's Journal ($today): [MISSING] journal/$today/mrdevcourses.md not created yet." -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "       ECOSYSTEM CHECK COMPLETE                           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
