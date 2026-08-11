param (
    [string]$Project = ""
)

$BaseDir = $PSScriptRoot

function Get-LatestFile {
    param([string]$Directory)
    
    $Path = Join-Path $BaseDir $Directory
    if (Test-Path $Path) {
        $Files = Get-ChildItem -Path $Path -Filter "*.md" | Sort-Object LastWriteTime -Descending
        if ($Files.Count -gt 0) {
            return $Files[0].FullName
        }
    }
    return $null
}

$FilesToCombine = @(
    (Join-Path $BaseDir "context\me.md"),
    (Join-Path $BaseDir "context\prompts_for_ai.md")
)

if ($Project) {
    $StatusFile = Join-Path $BaseDir "projects\$Project\_status.md"
    if (Test-Path $StatusFile) {
        $FilesToCombine += $StatusFile
    } else {
        Write-Warning "Status file not found: $StatusFile"
    }

    $MainProjectFile = Join-Path $BaseDir "projects\$Project\$Project.md"
    if (Test-Path $MainProjectFile) {
        $FilesToCombine += $MainProjectFile
    }
}

$LatestJournal = Get-LatestFile "journal"
if ($LatestJournal) {
    $FilesToCombine += $LatestJournal
}

$OutPath = Join-Path $BaseDir "combined_docs.md"
$OutContent = ""

foreach ($File in $FilesToCombine) {
    if (Test-Path $File) {
        $RelPath = Resolve-Path -Relative $File -ErrorAction SilentlyContinue
        if (-not $RelPath) { $RelPath = $File }
        
        $OutContent += "`n`n--- $RelPath ---`n`n"
        $OutContent += [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
    }
}

[System.IO.File]::WriteAllText($OutPath, $OutContent, [System.Text.Encoding]::UTF8)

Write-Host "Context successfully collected in combined_docs.md" -ForegroundColor Green
Write-Host "Included files:"
foreach ($File in $FilesToCombine) {
    if (Test-Path $File) {
        $Rel = Resolve-Path -Relative $File
        Write-Host " - $Rel"
    }
}
