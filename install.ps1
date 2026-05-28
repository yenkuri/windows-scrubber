$ErrorActionPreference = "Stop"

$BaseUrl = "https://git.yenkuri.com"
$DownloadRoot = Join-Path $env:TEMP "windows-scrubber"
$TweaksRoot = Join-Path $DownloadRoot "tweaks"
$LibRoot = Join-Path $DownloadRoot "lib"
$ModulesRoot = Join-Path $DownloadRoot "modules"
$BaselinePath = Join-Path $TweaksRoot "baseline.ps1"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$RequiredFiles = @(
    @{
        RelativePath = "tweaks/baseline.ps1"
        Url = "$BaseUrl/tweaks/baseline.ps1"
        Path = $BaselinePath
    },
    @{
        RelativePath = "lib/helpers.ps1"
        Url = "$BaseUrl/lib/helpers.ps1"
        Path = Join-Path $LibRoot "helpers.ps1"
    },
    @{
        RelativePath = "modules/cleanout.ps1"
        Url = "$BaseUrl/modules/cleanout.ps1"
        Path = Join-Path $ModulesRoot "cleanout.ps1"
    },
    @{
        RelativePath = "modules/buildup.ps1"
        Url = "$BaseUrl/modules/buildup.ps1"
        Path = Join-Path $ModulesRoot "buildup.ps1"
    },
    @{
        RelativePath = "modules/optional.ps1"
        Url = "$BaseUrl/modules/optional.ps1"
        Path = Join-Path $ModulesRoot "optional.ps1"
    },
    @{
        RelativePath = "modules/summary.ps1"
        Url = "$BaseUrl/modules/summary.ps1"
        Path = Join-Path $ModulesRoot "summary.ps1"
    }
)

Write-Host "Windows Scrubber launcher"
Write-Host "Staging root: $DownloadRoot"
Write-Host "Baseline path: $BaselinePath"

try {
    if (-not (Test-IsAdmin)) {
        Write-Host "Please run PowerShell as Administrator."
        exit 0
    }

    foreach ($folder in @($DownloadRoot, $TweaksRoot, $LibRoot, $ModulesRoot)) {
        if (-not (Test-Path $folder)) {
            Write-Host "Creating folder: $folder"
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }

    Write-Host "Setting process execution policy bypass..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    foreach ($file in $RequiredFiles) {
        Write-Host "Downloading $($file.RelativePath)..."
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Path -UseBasicParsing -ErrorAction Stop

        if (-not (Test-Path $file.Path)) {
            Write-Error "Download did not create the expected file: $($file.Path)"
            exit 1
        }
    }

    Write-Host "Opening Windows Scrubber menu..."
    . $BaselinePath
    Show-MainMenu
} catch {
    Write-Error "Windows Scrubber launcher failed: $($_.Exception.Message)"
    exit 1
}
