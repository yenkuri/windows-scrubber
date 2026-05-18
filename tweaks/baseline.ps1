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

function Show-Welcome {
    Write-Host ""
    Write-Host "Windows Scrubber"
    Write-Host "Fresh install cleanup + workstation setup"
    Write-Host ""
    Write-Host "This will run the standard scrub, then offer optional cleanup tools."
    Write-Host "Review the README/source before running on important machines."
    Write-Host ""

    $confirmation = Read-Host "Run the standard scrub now? (Y/n)"

    switch ($confirmation) {
        "" { return }
        "Y" { return }
        "y" { return }
        "N" {
            Write-Host "INFO: Baseline skipped by user."
            exit 0
        }
        "n" {
            Write-Host "INFO: Baseline skipped by user."
            exit 0
        }
        default {
            Write-Host "INFO: No valid confirmation received. Exiting."
            exit 0
        }
    }
}

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
    (Join-Path $PSScriptRoot "..\modules\summary.ps1")
)

foreach ($ModulePath in $ModulePaths) {
    if (-not (Test-Path $ModulePath)) {
        Write-Error "Windows Scrubber module file was not found: $ModulePath"
        exit 1
    }

    . $ModulePath
}

Show-Welcome

Write-ScrubberStage "STAGE 00: Preflight"
Write-Host "Running as Administrator: $(Test-IsAdmin)"
Write-Host "winget available: $([bool](Get-Command winget -ErrorAction SilentlyContinue))"

Write-ScrubberStage "STAGE 01: Cleanout"
Disable-AdvertisingId
Disable-TailoredExperiences
Disable-FeedbackPrompts
Disable-ActivityHistory
Disable-ConsumerFeatures
Disable-StoreConsumerChurn
Disable-WindowsTipsAndSetupPrompts
Disable-StoreAutoUpdates
Optimize-WindowsSearchIndexing
Disable-LocationTracking
Disable-StartMenuBingSearch
Disable-StartMenuRecommendations
Reset-StartMenuLayout
Remove-BaselineStoreBloat
Disable-Widgets
Disable-Copilot
Remove-OneDrive
Remove-Edge
Disable-AppAutoStartEntries

Write-ScrubberStage "STAGE 02: Buildup"
Install-Chrome
Install-7Zip
Set-ChromeDefaults
Set-WindowsScrubberDesktop
Show-FileExtensions
Show-HiddenFiles
Disable-MouseAcceleration
Prefer-IPv4OverIPv6
Disable-TaskbarSearchIcon
Disable-TaskbarTaskViewIcon
Restart-ExplorerShell

Write-ScrubberStage "STAGE END: Summary"

Invoke-ScrubberSummary

Invoke-OptionalModulesMenu
