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
