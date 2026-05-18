function Show-FileExtensions {
    Invoke-Tweak "Show file extensions" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    }
}

function Show-HiddenFiles {
    Invoke-Tweak "Show hidden files" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
    }
}

function Disable-MouseAcceleration {
    Invoke-Tweak "Disable mouse acceleration" {
        $path = "HKCU:\Control Panel\Mouse"

        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }

        Set-ItemProperty -Path $path -Name "MouseSpeed" -Value "0" -Type String
        Set-ItemProperty -Path $path -Name "MouseThreshold1" -Value "0" -Type String
        Set-ItemProperty -Path $path -Name "MouseThreshold2" -Value "0" -Type String
        Write-Host "Set mouse acceleration values to 0"
    }
}


function Disable-TaskbarSearchIcon {
    Invoke-Tweak "Disable Taskbar Search Icon" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0
    }
}

function Disable-TaskbarTaskViewIcon {
    Invoke-Tweak "Disable Taskbar Task View Icon" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0
    }
}


function Install-Chrome {
    Invoke-Tweak "Install Google Chrome" {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Skip "winget was not found. Google Chrome will not be installed."
            return
        }

        $wingetOutput = & winget install --id Google.Chrome --exact --accept-source-agreements --accept-package-agreements --silent 2>&1
        $wingetExitCode = $LASTEXITCODE
        $wingetText = $wingetOutput -join "`n"

        if ($wingetExitCode -eq 0) {
            Write-Host "Google Chrome install completed successfully."
        } elseif ($wingetText -match "already installed|No available upgrade found|No newer package versions are available") {
            Write-Host "Google Chrome is already installed and no newer package is available."
        } else {
            Write-Skip "Google Chrome install did not complete successfully. winget exited with code $wingetExitCode."
        }
    }
}

function Install-7Zip {
    Invoke-Tweak "Install 7-Zip" {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Skip "winget was not found. 7-Zip will not be installed."
            return
        }

        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            $wingetOutput = & winget install --id 7zip.7zip --exact --accept-source-agreements --accept-package-agreements --silent --disable-interactivity 2>&1
        } finally {
            $ProgressPreference = $previousProgressPreference
        }

        $wingetExitCode = $LASTEXITCODE
        $wingetText = ($wingetOutput | Out-String).Trim()

        if ($wingetExitCode -eq 0) {
            Write-Host "PASS: 7-Zip install completed successfully."
        } elseif ($wingetText -match "already installed|No available upgrade found|No newer package versions are available") {
            Write-Host "INFO: 7-Zip is already installed and no newer package is available."
        } else {
            Write-Host "WARN: 7-Zip install exited with code $wingetExitCode."
            if ($wingetText -and ($wingetText.Length -le 400)) {
                Write-Host $wingetText
            }
        }
    }
}

function Set-ChromeDefaults {
    Invoke-Tweak "Set Chrome defaults" {
        $chromePaths = @(
            (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
            (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe")
        )

        if (-not (Test-PathExists -Path $chromePaths)) {
            Write-Skip "Chrome executable was not found. Default app associations will not be changed."
            return
        }

        $associationsPath = Join-Path $env:TEMP "windows-scrubber-default-apps.xml"
        $associationsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@

        try {
            Set-Content -Path $associationsPath -Value $associationsXml -Encoding UTF8
            Write-Host "PASS: Chrome default associations XML created: $associationsPath"
        } catch {
            Write-Skip "Could not create Chrome default associations XML: $($_.Exception.Message)"
            return
        }

        if (Test-IsAdmin) {
            try {
                $dismOutput = & DISM /Online "/Import-DefaultAppAssociations:$associationsPath" 2>&1
                $dismExitCode = $LASTEXITCODE

                if ($dismExitCode -eq 0) {
                    Write-Host "PASS: Chrome default associations import completed."
                } else {
                    Write-Host "WARN: Chrome default associations import exited with code $dismExitCode."
                    if ($dismOutput) {
                        Write-Host ($dismOutput -join "`n")
                    }
                }
            } catch {
                Write-Skip "Could not import Chrome default associations: $($_.Exception.Message)"
            }
        } else {
            Write-Skip "Administrator rights are required to import default app associations with DISM."
        }

        Write-Host "WARN: Chrome default association import may require new user/first logon."

        try {
            Start-Process "ms-settings:defaultapps"
            Write-Host "INFO: Opened Default Apps settings for manual confirmation."
        } catch {
            Write-Skip "Could not open Default Apps settings: $($_.Exception.Message)"
        }
    }
}

function Set-WindowsDarkTheme {
    Invoke-Tweak "Set Windows theme to dark" {
        $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

        if (-not (Test-Path $personalizePath)) {
            New-Item -Path $personalizePath -Force | Out-Null
        }

        Set-RegistryDword -Path $personalizePath -Name "AppsUseLightTheme" -Value 0
        Set-RegistryDword -Path $personalizePath -Name "SystemUsesLightTheme" -Value 0
        Write-Host "PASS: Windows app and system theme set to dark for current user."
    }
}

function Set-WindowsScrubberDesktop {
    Invoke-Tweak "Set Windows Scrubber desktop" {
        $WallpaperUrl = "https://raw.githubusercontent.com/r4kk0/windows-scrubber/main/assets/wallpaper.png"
        $wallpaperFolder = Join-Path $env:TEMP "windows-scrubber"
        $wallpaperPath = Join-Path $wallpaperFolder "wallpaper.png"

        Set-WindowsDarkTheme

        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideIcons" -Value 1
        Write-Host "PASS: Desktop icons hidden for current user."

        $script:DesktopShortcutCleanupAttempted = $true
        $desktopPaths = @(
            [Environment]::GetFolderPath("Desktop"),
            [Environment]::GetFolderPath("CommonDesktopDirectory")
        )

        foreach ($desktopPath in $desktopPaths) {
            if (-not $desktopPath -or -not (Test-Path $desktopPath)) {
                Write-Host "INFO: Desktop path does not exist: $desktopPath"
                continue
            }

            $shortcuts = Get-ChildItem -Path $desktopPath -Filter "*.lnk" -File -ErrorAction SilentlyContinue

            if (-not $shortcuts) {
                Write-Host "INFO: No desktop shortcuts found in: $desktopPath"
                continue
            }

            foreach ($shortcut in $shortcuts) {
                try {
                    Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
                    Write-Host "PASS: Removed desktop shortcut: $($shortcut.FullName)"
                } catch {
                    Write-Host "WARN: Could not remove desktop shortcut $($shortcut.FullName): $($_.Exception.Message)"
                }
            }
        }

        try {
            if (-not (Test-Path $wallpaperFolder)) {
                New-Item -Path $wallpaperFolder -ItemType Directory -Force | Out-Null
            }

            Invoke-WebRequest -Uri $WallpaperUrl -OutFile $wallpaperPath -UseBasicParsing -ErrorAction Stop
            Write-Host "PASS: Wallpaper downloaded: $wallpaperPath"
        } catch {
            Write-Host "WARN: Could not download wallpaper: $($_.Exception.Message)"
            return
        }

        try {
            New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperPath -PropertyType String -Force | Out-Null

            if (-not ("WindowsScrubberWallpaper" -as [type])) {
                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WindowsScrubberWallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
            }

            $result = [WindowsScrubberWallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)

            if ($result) {
                Write-Host "PASS: Wallpaper applied."
            } else {
                Write-Host "WARN: Wallpaper registry value was set, but Windows did not report a successful refresh."
            }
        } catch {
            Write-Host "WARN: Could not apply wallpaper: $($_.Exception.Message)"
        }
    }
}


function Prefer-IPv4OverIPv6 {
    Invoke-Tweak "Prefer IPv4 over IPv6" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for the HKLM IPv4 preference tweak."
            return
        }

        # DisabledComponents = 32 prefers IPv4 over IPv6 but does not fully disable IPv6.
        Set-RegistryDword -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32
    }
}

