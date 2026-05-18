$ErrorActionPreference = "Stop"

$BaselineUrl = "https://raw.githubusercontent.com/r4kk0/windows-scrubber/main/tweaks/baseline.ps1"
$DownloadRoot = Join-Path $env:TEMP "windows-scrubber"
$BaselinePath = Join-Path $DownloadRoot "baseline.ps1"

Write-Host "Windows Scrubber launcher"
Write-Host "Baseline URL: $BaselineUrl"
Write-Host "Download path: $BaselinePath"

try {
    if (-not (Test-Path $DownloadRoot)) {
        Write-Host "Creating temp folder..."
        New-Item -Path $DownloadRoot -ItemType Directory -Force | Out-Null
    }

    Write-Host "Setting process execution policy bypass..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    Write-Host "Downloading baseline script..."
    Invoke-WebRequest -Uri $BaselineUrl -OutFile $BaselinePath -UseBasicParsing

    if (-not (Test-Path $BaselinePath)) {
        Write-Error "Download did not create the expected baseline script: $BaselinePath"
        exit 1
    }

    Write-Host "Running baseline script..."
    & $BaselinePath
} catch {
    Write-Error "Windows Scrubber launcher failed: $($_.Exception.Message)"
    exit 1
}
