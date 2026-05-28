$ErrorActionPreference = "Stop"
$script:StartMenuCleanupAttempted = $false
$script:BaselineStoreBloatCleanupRan = $false
$script:DesktopShortcutCleanupAttempted = $false
$script:SearchIndexingOptimizationAttempted = $false

$HelpersPath = Join-Path $PSScriptRoot "..\lib\helpers.ps1"
if (-not (Test-Path $HelpersPath)) {
    Write-Error "Windows Scrubber helpers file was not found: $HelpersPath"
    exit 1
}

. $HelpersPath

function Write-ScrubberStage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $separator = "=" * 64

    Write-Host ""
    Write-Host $separator
    Write-Host $Message
    Write-Host $separator
}

$ModulePaths = @(
    (Join-Path $PSScriptRoot "..\modules\cleanout.ps1"),
    (Join-Path $PSScriptRoot "..\modules\buildup.ps1"),
    (Join-Path $PSScriptRoot "..\modules\optional.ps1"),
    (Join-Path $PSScriptRoot "..\modules\summary.ps1"),
    (Join-Path $PSScriptRoot "..\modules\full-cleanup.ps1"),
    (Join-Path $PSScriptRoot "..\modules\app-bundle.ps1"),
    (Join-Path $PSScriptRoot "..\modules\main-menu.ps1")
)

foreach ($ModulePath in $ModulePaths) {
    if (-not (Test-Path $ModulePath)) {
        Write-Error "Windows Scrubber module file was not found: $ModulePath"
        exit 1
    }

    . $ModulePath
}

if ($MyInvocation.InvocationName -ne ".") {
    if (-not (Test-IsAdmin)) {
        Write-Host "Please run PowerShell as Administrator."
        exit 0
    }

    Show-MainMenu
}
