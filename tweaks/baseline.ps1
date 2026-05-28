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
    (Join-Path $PSScriptRoot "..\modules\summary.ps1")
)

foreach ($ModulePath in $ModulePaths) {
    if (-not (Test-Path $ModulePath)) {
        Write-Error "Windows Scrubber module file was not found: $ModulePath"
        exit 1
    }

    . $ModulePath
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    Invoke-Tweak "Install $AppName" {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Skip "winget was not found. $AppName will not be installed."
            return
        }

        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            $wingetOutput = & winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent --disable-interactivity 2>&1
        } finally {
            $ProgressPreference = $previousProgressPreference
        }

        $wingetExitCode = $LASTEXITCODE
        $wingetText = ($wingetOutput | Out-String).Trim()

        if ($wingetExitCode -eq 0) {
            Write-Host "PASS: $AppName install completed successfully."
        } elseif ($wingetText -match "already installed|No available upgrade found|No newer package versions are available") {
            Write-Host "INFO: $AppName is already installed and no newer package is available."
        } else {
            Write-Host "WARN: $AppName install exited with code $wingetExitCode."
            if ($wingetText -and ($wingetText.Length -le 400)) {
                Write-Host $wingetText
            }
        }
    }
}

function Install-AppBundle {
    Write-ScrubberStage "Install apps"

    $apps = @(
        @{ Name = "Google Chrome"; Id = "Google.Chrome" },
        @{ Name = "7-Zip"; Id = "7zip.7zip" },
        @{ Name = "AltDrag"; Id = "AltDrag.AltDrag" },
        @{ Name = "Discord"; Id = "Discord.Discord" }
    )

    foreach ($app in $apps) {
        Install-WingetApp -AppName $app.Name -PackageId $app.Id
    }

    Set-ChromeDefaults
}

function Invoke-FullCleanup {
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
    Set-WindowsDarkTheme
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
}

function Show-MainMenu {
    while ($true) {
        Write-ScrubberStage "Windows Scrubber"
        Write-Host "Choose an option."
        Write-Host ""
        Write-Host "[1] Full cleanup / scrubber flow"
        Write-Host "[2] Install apps"
        Write-Host "[3] Enable Remote Desktop"
        Write-Host "[4] Configure automatic local sign-in"
        Write-Host "[5] Configure no-sleep power plan"
        Write-Host "[Q] Quit"

        $selection = Read-Host "Choose an option"

        if ([string]::IsNullOrWhiteSpace($selection)) {
            Write-Host "INFO: See you next time! :)"
            return
        }

        switch ($selection) {
            "1" { Invoke-FullCleanup }
            "2" { Install-AppBundle }
            "3" { Enable-RemoteDesktop }
            "4" { Invoke-AutoLogonMenu }
            "5" { Set-NoSleepPowerPlan }
            "Q" { Write-Host "INFO: See you next time! :)"; return }
            "q" { Write-Host "INFO: See you next time! :)"; return }
            default { Write-Host "INFO: Invalid selection. Choose an option or press Enter to quit." }
        }
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    if (-not (Test-IsAdmin)) {
        Write-Host "Please run PowerShell as Administrator."
        exit 0
    }

    Show-MainMenu
}
