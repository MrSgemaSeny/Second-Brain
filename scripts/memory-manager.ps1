param (
    [string]$ProjectRoot = "C:\Users\murat\IdeaProjects\new_world\MrDevCourses",
    [string]$BrainRoot = "C:\Users\murat\IdeaProjects\new_world\Brain's protocol - second brain"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  BRAIN'S PROTOCOL: CONTEXT & MEMORY HEALTH AUDIT " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Check Project CONTEXT.md
$contextMd = Join-Path $ProjectRoot ".agents\CONTEXT.md"
if (Test-Path $contextMd) {
    $lines = Get-Content $contextMd -Encoding UTF8
    $lineCount = $lines.Count
    $charCount = ($lines -join "`n").Length
    $approxTokens = [math]::Round($charCount / 3.8)

    Write-Host "`n[L1 WORKING MEMORY] Project CONTEXT.md:" -ForegroundColor Yellow
    Write-Host "  Path: $contextMd"
    Write-Host "  Lines: $lineCount (Target: <150 lines)"
    Write-Host "  Approximate Tokens: $approxTokens tokens"

    if ($lineCount -gt 200) {
        Write-Host "  [WARNING] CONTEXT.md exceeds 200 lines limit! Pruning recommended." -ForegroundColor Red
    } else {
        Write-Host "  [OK] CONTEXT.md is within optimal memory boundaries." -ForegroundColor Green
    }
} else {
    Write-Host "`n[WARNING] CONTEXT.md not found in $contextMd" -ForegroundColor Red
}

# 2. Check Second Brain Context Files (L1 Whitelist vs L2 Archival)
$brainContextDir = Join-Path $BrainRoot "context"
$coreWhitelist = @("rules.md", "me.md", "projects.md")

if (Test-Path $brainContextDir) {
    Write-Host "`n[L1 AUTO-INJECTED WHITELIST] Core Second Brain Context:" -ForegroundColor Yellow
    $totalL1Tokens = 0
    foreach ($file in $coreWhitelist) {
        $p = Join-Path $brainContextDir $file
        if (Test-Path $p) {
            $c = Get-Content $p -Raw -Encoding UTF8
            $tokens = [math]::Round($c.Length / 3.8)
            $totalL1Tokens += $tokens
            Write-Host "  - $file : $($c.Length) bytes (~$tokens tokens)" -ForegroundColor Green
        }
    }
    Write-Host "  Total L1 Bootstrap Payload: ~$totalL1Tokens tokens" -ForegroundColor Cyan

    Write-Host "`n[L2 ARCHIVAL MEMORY] On-Demand Files (Not Auto-Injected):" -ForegroundColor Yellow
    Get-ChildItem -Path $brainContextDir -Filter "*.md" | Where-Object { $_.Name -notin $coreWhitelist } | ForEach-Object {
        $tokens = [math]::Round($_.Length / 3.8)
        Write-Host "  - $($_.Name) : $($_.Length) bytes (~$tokens tokens) [On-Demand Only]" -ForegroundColor DarkGray
    }
}

# 3. Check Pre-Invocation Hook Alignment
$hookPath = Join-Path $ProjectRoot ".agents\scripts\pre-invocation.ps1"
if (Test-Path $hookPath) {
    $hookContent = Get-Content $hookPath -Raw -Encoding UTF8
    Write-Host "`n[LIFECYCLE HOOKS] pre-invocation.ps1 Status:" -ForegroundColor Yellow
    if ($hookContent -match 'coreWhitelist' -and $hookContent -match 'invocationNum > 1') {
        Write-Host "  [OK] Streaming Attention Sinks & Tiered Whitelist Active." -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Hook might be using legacy uncompressed injection." -ForegroundColor Red
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  AUDIT COMPLETE: MEMORY OPTIMIZATION ACTIVE      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
