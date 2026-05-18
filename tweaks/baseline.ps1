$ErrorActionPreference = "Stop"
$script:StartMenuCleanupAttempted = $false
$script:BaselineStoreBloatCleanupRan = $false

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message"
}

function Write-Skip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "SKIP: $Message"
}

function Write-Stage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host $Message
    Write-Host ("-" * $Message.Length)
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )

    foreach ($item in $Path) {
        if ($item -and (Test-Path $item)) {
            return $true
        }
    }

    return $false
}

function Write-SummaryItem {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PASS", "WARN", "INFO")]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "${Status}: $Message"
}

function Set-RegistryDword {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    Write-Host "Set $Path\$Name = $Value"
}

function Remove-RegistryValueIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ((Test-Path $Path) -and (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
        Remove-ItemProperty -Path $Path -Name $Name -Force
        Write-Host "Removed $Path\$Name"
    }
}

function Remove-RegistryKeyIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "Removed $Path"
    } else {
        Write-Host "INFO: Registry path does not exist: $Path"
    }
}

function Invoke-Tweak {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    Write-Step $Name

    try {
        & $ScriptBlock
    } catch {
        Write-Warning "Failed: $Name. $($_.Exception.Message)"
    }
}

function Disable-AdvertisingId {
    Invoke-Tweak "Disable Advertising ID for current user" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
    }
}

function Disable-TailoredExperiences {
    Invoke-Tweak "Disable Tailored Experiences with diagnostic data for current user" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0
    }
}

function Disable-FeedbackPrompts {
    Invoke-Tweak "Disable feedback prompts for current user" {
        $path = "HKCU:\Software\Microsoft\Siuf\Rules"

        Set-RegistryDword -Path $path -Name "NumberOfSIUFInPeriod" -Value 0
        Remove-RegistryValueIfExists -Path $path -Name "PeriodInNanoSeconds"
    }
}

function Disable-ActivityHistory {
    Invoke-Tweak "Disable Activity History publish/upload via HKLM policy" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Activity History policy tweaks."
            return
        }

        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

        Set-RegistryDword -Path $path -Name "PublishUserActivities" -Value 0
        Set-RegistryDword -Path $path -Name "UploadUserActivities" -Value 0
    }
}

function Disable-StartMenuBingSearch {
    Invoke-Tweak "Disable Start Menu Bing web search" {
        Set-RegistryDword -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
    }
}

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

function Disable-ConsumerFeatures {
    Invoke-Tweak "Disable Consumer Features" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Consumer Features policy tweaks."
            return
        }

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    }
}

function Disable-LocationTracking {
    Invoke-Tweak "Disable Location Tracking" {
        $userPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"

        if (-not (Test-Path $userPath)) {
            New-Item -Path $userPath -Force | Out-Null
        }

        New-ItemProperty -Path $userPath -Name "Value" -Value "Deny" -PropertyType String -Force | Out-Null
        Write-Host "Set $userPath\Value = Deny"

        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Location policy tweaks."
            return
        }

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1
    }
}

function Disable-Widgets {
    Invoke-Tweak "Disable Widgets" {
        try {
            Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0
        } catch {
            Write-Skip "Could not set the HKCU Widgets taskbar value: $($_.Exception.Message)"
        }

        if (Test-IsAdmin) {
            Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0
        } else {
            Write-Skip "Administrator rights are required for the HKLM Widgets policy tweak."
            return
        }
    }
}

function Disable-Copilot {
    Invoke-Tweak "Disable Copilot" {
        Set-RegistryDword -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1

        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Copilot policy tweaks."
            return
        }

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    }
}

function Disable-StartMenuRecommendations {
    Invoke-Tweak "Disable Start Menu Recommendations" {
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

        Set-RegistryDword -Path $advancedPath -Name "Start_IrisRecommendations" -Value 0
        Set-RegistryDword -Path $advancedPath -Name "Start_AccountNotifications" -Value 0
        Set-RegistryDword -Path $contentPath -Name "SubscribedContent-338388Enabled" -Value 0
        Set-RegistryDword -Path $contentPath -Name "SubscribedContent-338389Enabled" -Value 0
    }
}

function Reset-StartMenuLayout {
    Invoke-Tweak "Reset Start Menu layout" {
        $script:StartMenuCleanupAttempted = $true

        try {
            Remove-RegistryKeyIfExists -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
        } catch {
            Write-Skip "Could not clean Start Menu registry path: $($_.Exception.Message)"
        }

        $cloudStorePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"

        if (Test-Path $cloudStorePath) {
            $startMenuKeys = Get-ChildItem -Path $cloudStorePath -Recurse -ErrorAction SilentlyContinue |
                Where-Object { ($_.PSChildName -match "windows\.data") -and ($_.PSChildName -match "start|tile|pinned") }

            foreach ($key in $startMenuKeys) {
                try {
                    Remove-RegistryKeyIfExists -Path $key.PSPath
                } catch {
                    Write-Skip "Could not clean Start Menu registry path: $($key.PSPath). $($_.Exception.Message)"
                }
            }
        } else {
            Write-Host "INFO: Registry path does not exist: $cloudStorePath"
        }

        Write-Host "INFO: Restarting Explorer to refresh Start menu and taskbar."

        try {
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Process "explorer.exe"
            Write-Host "PASS: Explorer restarted."
        } catch {
            Write-Skip "Could not restart Explorer: $($_.Exception.Message)"
        }

        Write-Host "INFO: Start Menu layout cleanup is best effort. Explorer restart, sign out, or reboot may be required before visual changes appear."
    }
}

function Remove-BaselineStoreBloat {
    Invoke-Tweak "Remove baseline Store bloat" {
        $script:BaselineStoreBloatCleanupRan = $true
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            $targetPackageNames = @(
                "Microsoft.LinkedIn",
                "MicrosoftTeams",
                "MSTeams",
                "Microsoft.Getstarted",
                "Microsoft.BingNews",
                "Microsoft.BingWeather",
                "Microsoft.WindowsFeedbackHub",
                "Microsoft.MicrosoftSolitaireCollection",
                "Clipchamp.Clipchamp"
            )

            foreach ($packageName in $targetPackageNames) {
                $packages = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue

                if (-not $packages) {
                    Write-Host "INFO: Store app not installed for current user: $packageName"
                    continue
                }

                foreach ($package in $packages) {
                    try {
                        Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop | Out-Null
                        Write-Host "PASS: Removed current-user Store app: $($package.Name)"
                    } catch {
                        Write-Host "WARN: Could not remove current-user Store app $($package.Name): $($_.Exception.Message)"
                    }
                }
            }

            if (-not (Test-IsAdmin)) {
                Write-Skip "Administrator rights are required to remove provisioned Store bloat for future users."
                return
            }

            $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            foreach ($packageName in $targetPackageNames) {
                $matches = $provisionedPackages | Where-Object { $_.DisplayName -eq $packageName }

                if (-not $matches) {
                    Write-Host "INFO: Provisioned Store app not found: $packageName"
                    continue
                }

                foreach ($package in $matches) {
                    try {
                        Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop | Out-Null
                        Write-Host "PASS: Removed provisioned Store app for future users: $($package.DisplayName)"
                    } catch {
                        Write-Host "WARN: Could not remove provisioned Store app $($package.DisplayName): $($_.Exception.Message)"
                    }
                }
            }
        } finally {
            $ProgressPreference = $previousProgressPreference
        }
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

function Disable-AppAutoStartEntries {
    Invoke-Tweak "Disable app auto-start entries for known annoying apps" {
        $startupNames = @(
            "Discord",
            "Steam",
            "OneDrive",
            "MicrosoftEdgeAutoLaunch",
            "MicrosoftEdgeUpdate",
            "Teams",
            "Spotify",
            "EpicGamesLauncher"
        )

        $userRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $machineRunPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

        foreach ($startupName in $startupNames) {
            Remove-RegistryValueIfExists -Path $userRunPath -Name $startupName
        }

        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to remove HKLM app auto-start entries."
            return
        }

        foreach ($startupName in $startupNames) {
            Remove-RegistryValueIfExists -Path $machineRunPath -Name $startupName
        }
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

        $associationsPath = Join-Path $env:TEMP "zerowin-default-apps.xml"
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

function Remove-OneDrive {
    Invoke-Tweak "Remove OneDrive" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to remove OneDrive."
            return
        }

        $oneDriveProcesses = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue

        if ($oneDriveProcesses) {
            Write-Host "Stopping OneDrive..."
            $oneDriveProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "OneDrive is not running."
        }

        $uninstallers = @(
            (Join-Path $env:SystemRoot "System32\OneDriveSetup.exe"),
            (Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe")
        )

        foreach ($uninstaller in $uninstallers) {
            if (Test-Path $uninstaller) {
                Write-Host "Running OneDrive uninstaller: $uninstaller"

                try {
                    $process = Start-Process -FilePath $uninstaller -ArgumentList "/uninstall" -Wait -PassThru

                    if ($process.ExitCode -eq 0) {
                        Write-Host "OneDrive uninstaller completed successfully."
                    } else {
                        Write-Skip "OneDrive uninstaller exited with code $($process.ExitCode): $uninstaller"
                    }
                } catch {
                    Write-Skip "Could not run OneDrive uninstaller: $uninstaller. $($_.Exception.Message)"
                }
            } else {
                Write-Host "OneDrive uninstaller not found: $uninstaller"
            }
        }

        Remove-RegistryValueIfExists -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"
        Remove-RegistryValueIfExists -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1

        $explorerIntegrationPaths = @(
            "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKLM:\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        )

        foreach ($path in $explorerIntegrationPaths) {
            if (Test-Path $path) {
                Set-RegistryDword -Path $path -Name "System.IsPinnedToNameSpaceTree" -Value 0
            } else {
                Write-Host "OneDrive Explorer integration key not found: $path"
            }
        }
    }
}

function Get-EdgeExecutablePaths {
    return @(
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe")
    )
}

function Test-EdgeExecutablePresent {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )

    return (Test-PathExists -Path $Path)
}

function Stop-EdgeProcesses {
    $edgeProcessNames = @(
        "msedge",
        "MicrosoftEdgeUpdate"
    )

    foreach ($processName in $edgeProcessNames) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($processes) {
            Write-Host "Stopping $processName..."
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "INFO: $processName is not running."
        }
    }
}

function Invoke-EdgeWingetUninstall {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Trying winget uninstall for Microsoft Edge..."
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            $wingetOutput = & winget uninstall --id Microsoft.Edge --exact --silent --disable-interactivity --accept-source-agreements 2>&1
        } finally {
            $ProgressPreference = $previousProgressPreference
        }

        $wingetExitCode = $LASTEXITCODE
        $wingetText = ($wingetOutput | Out-String).Trim()

        if ($wingetExitCode -eq 0) {
            Write-Host "PASS: winget uninstall for Microsoft Edge completed successfully."
        } elseif ($wingetText -match "No installed package found matching input criteria") {
            Write-Host "INFO: Microsoft Edge is not installed via winget."
        } else {
            Write-Host "WARN: winget uninstall for Microsoft Edge exited with code $wingetExitCode."
            if ($wingetText -and ($wingetText.Length -le 400)) {
                Write-Host $wingetText
            }
        }
    } else {
        Write-Host "INFO: winget was not found. Skipping winget uninstall for Microsoft Edge."
    }
}

function Invoke-EdgeSetupUninstallers {
    $edgeInstallerRoots = @(
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application"),
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application")
    )

    foreach ($root in $edgeInstallerRoots) {
        if (-not (Test-Path $root)) {
            Write-Host "INFO: Edge application path does not exist: $root"
            continue
        }

        $setupFiles = Get-ChildItem -Path $root -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*\Installer\setup.exe" }

        if (-not $setupFiles) {
            Write-Host "INFO: Edge setup uninstaller not found under: $root"
            continue
        }

        foreach ($setupFile in $setupFiles) {
            Write-Host "Running Edge setup uninstaller: $($setupFile.FullName)"

            try {
                $process = Start-Process -FilePath $setupFile.FullName -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -PassThru

                if ($process.ExitCode -eq 0) {
                    Write-Host "PASS: Edge setup uninstaller completed successfully."
                } else {
                    Write-Host "WARN: Edge setup uninstaller exited with code $($process.ExitCode): $($setupFile.FullName)"
                }
            } catch {
                Write-Skip "Could not run Edge setup uninstaller: $($setupFile.FullName). $($_.Exception.Message)"
            }
        }
    }
}

function Remove-EdgeShortcuts {
    $shortcutPaths = @(
        (Join-Path ([Environment]::GetFolderPath("Desktop")) "Microsoft Edge.lnk"),
        (Join-Path ([Environment]::GetFolderPath("CommonDesktopDirectory")) "Microsoft Edge.lnk"),
        (Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs\Microsoft Edge.lnk"),
        (Join-Path ([Environment]::GetFolderPath("CommonStartMenu")) "Programs\Microsoft Edge.lnk"),
        (Join-Path $env:AppData "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk")
    )

    foreach ($shortcutPath in $shortcutPaths) {
        if (Test-Path $shortcutPath) {
            try {
                Remove-Item -Path $shortcutPath -Force
                Write-Host "Removed shortcut: $shortcutPath"
            } catch {
                Write-Skip "Could not remove shortcut: $shortcutPath. $($_.Exception.Message)"
            }
        } else {
            Write-Host "INFO: Shortcut path does not exist: $shortcutPath"
        }
    }
}

function Remove-EdgeStartupEntries {
    $edgeStartupNames = @(
        "MicrosoftEdgeAutoLaunch",
        "MicrosoftEdgeUpdate",
        "Microsoft Edge"
    )

    foreach ($startupName in $edgeStartupNames) {
        Remove-RegistryValueIfExists -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $startupName
        Remove-RegistryValueIfExists -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $startupName
    }
}

function Set-EdgePolicies {
    Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "CreateDesktopShortcutDefault" -Value 0
    Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "RemoveDesktopShortcutDefault" -Value 1
    Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1
    Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Value 0
}

function Remove-Edge {
    Invoke-Tweak "Remove Microsoft Edge" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to remove Microsoft Edge."
            return
        }

        $edgeExecutablePaths = Get-EdgeExecutablePaths

        foreach ($edgeExecutablePath in $edgeExecutablePaths) {
            if (Test-Path $edgeExecutablePath) {
                Write-Host "INFO: Edge executable found: $edgeExecutablePath"
            } else {
                Write-Host "INFO: Edge executable path does not exist: $edgeExecutablePath"
            }
        }

        Stop-EdgeProcesses
        Invoke-EdgeWingetUninstall
        Invoke-EdgeSetupUninstallers

        if (Test-EdgeExecutablePresent -Path $edgeExecutablePaths) {
            Write-Host "WARN: Edge executable still present after uninstall attempts."
            Write-Host "INFO: Edge Application folder was not deleted."
        } else {
            Write-Host "PASS: Edge executable is no longer found."
        }

        Remove-EdgeShortcuts
        Remove-EdgeStartupEntries
        Set-EdgePolicies
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

function Remove-XboxGamingFeatures {
    Invoke-Tweak "Remove Xbox / Game Bar / Game DVR features" {
        Write-Host "WARN: This may remove Xbox apps, Game Bar, and recording/capture features."
        $confirmation = Read-Host "Are you sure? This may remove Game Bar recording/capture features. (y/N)"

        if ($confirmation -notin @("y", "Y")) {
            Write-Host "INFO: Xbox / Game Bar removal cancelled."
            return
        }

        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            Set-RegistryDword -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
            Set-RegistryDword -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2
            Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0

            if (Test-IsAdmin) {
                Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
            } else {
                Write-Skip "Administrator rights are required for the HKLM Game DVR policy tweak."
            }

            Write-Host "INFO: Microsoft.XboxGameCallableUI is a protected Windows component and will be left alone."

            $xboxPackagePatterns = @(
                "Microsoft.Xbox*",
                "Microsoft.GamingApp",
                "Microsoft.XboxGamingOverlay",
                "Microsoft.XboxGameOverlay",
                "Microsoft.XboxIdentityProvider",
                "Microsoft.XboxSpeechToTextOverlay"
            )

            foreach ($pattern in $xboxPackagePatterns) {
                $packages = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne "Microsoft.XboxGameCallableUI" }

                if (-not $packages) {
                    Write-Host "INFO: Xbox package not installed for current user: $pattern"
                    continue
                }

                foreach ($package in $packages) {
                    try {
                        Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop | Out-Null
                        Write-Host "PASS: Removed current-user Xbox package: $($package.Name)"
                    } catch {
                        Write-Host "WARN: Could not remove current-user Xbox package $($package.Name): $($_.Exception.Message)"
                    }
                }
            }

            if (-not (Test-IsAdmin)) {
                Write-Skip "Administrator rights are required to remove provisioned Xbox packages for future users."
                return
            }

            $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            foreach ($pattern in $xboxPackagePatterns) {
                $matches = $provisionedPackages |
                    Where-Object { ($_.DisplayName -like $pattern) -and ($_.DisplayName -ne "Microsoft.XboxGameCallableUI") }

                if (-not $matches) {
                    Write-Host "INFO: Provisioned Xbox package not found: $pattern"
                    continue
                }

                foreach ($package in $matches) {
                    try {
                        Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop | Out-Null
                        Write-Host "PASS: Removed provisioned Xbox package for future users: $($package.DisplayName)"
                    } catch {
                        Write-Host "WARN: Could not remove provisioned Xbox package $($package.DisplayName): $($_.Exception.Message)"
                    }
                }
            }
        } finally {
            $ProgressPreference = $previousProgressPreference
        }
    }
}

function Enable-RemoteDesktop {
    Invoke-Tweak "Enable Remote Desktop" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to enable Remote Desktop."
            return
        }

        $edition = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).OperatingSystemSKU
        $caption = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption

        if ($caption -match "Home") {
            Write-Host "WARN: Remote Desktop host may not be supported on Windows Home editions."
        } elseif ($caption) {
            Write-Host "INFO: Windows edition detected: $caption"
        } elseif ($edition) {
            Write-Host "INFO: Windows edition SKU detected: $edition"
        }

        try {
            Set-RegistryDword -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
            Write-Host "PASS: Remote Desktop connections enabled."
        } catch {
            Write-Host "WARN: Could not enable Remote Desktop registry setting: $($_.Exception.Message)"
        }

        try {
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop | Out-Null
            Write-Host "PASS: Remote Desktop firewall rules enabled."
        } catch {
            Write-Host "WARN: Could not enable Remote Desktop firewall rules: $($_.Exception.Message)"
        }

        $disableNla = Read-Host "Disable Network Level Authentication for compatibility? (y/N)"

        try {
            if ($disableNla -in @("y", "Y")) {
                Set-RegistryDword -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0
                Write-Host "WARN: Network Level Authentication disabled."
            } else {
                Set-RegistryDword -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
                Write-Host "PASS: Network Level Authentication enabled."
            }
        } catch {
            Write-Host "WARN: Could not update Network Level Authentication setting: $($_.Exception.Message)"
        }
    }
}

function Show-OptionalModulesMenu {
    Write-Stage "OPTIONAL MODULES"
    Write-Host "1. Remove Xbox / Game Bar / Game DVR packages and disable capture features"
    Write-Host "2. Aggressive Microsoft Store app cleanup"
    Write-Host "3. Aggressive Edge cleanup placeholder"
    Write-Host "4. Enable Remote Desktop"
    Write-Host "Q. Quit"
}

function Invoke-OptionalModulesMenu {
    while ($true) {
        Show-OptionalModulesMenu
        $selection = Read-Host "Select optional module"

        switch ($selection) {
            "1" { Remove-XboxGamingFeatures }
            "2" { Write-Host "INFO: Not implemented yet." }
            "3" { Write-Host "INFO: Not implemented yet." }
            "4" { Enable-RemoteDesktop }
            "Q" { Write-Host "INFO: Optional modules skipped."; return }
            "q" { Write-Host "INFO: Optional modules skipped."; return }
            "" { Write-Host "INFO: Optional modules skipped."; return }
            default { Write-Host "INFO: Invalid selection. Choose an option or press Enter to quit." }
        }
    }
}

Write-Stage "STAGE 00: Preflight"
Write-Host "Running as Administrator: $(Test-IsAdmin)"
Write-Host "winget available: $([bool](Get-Command winget -ErrorAction SilentlyContinue))"

Write-Stage "STAGE 01: Cleanout"
Disable-AdvertisingId
Disable-TailoredExperiences
Disable-FeedbackPrompts
Disable-ActivityHistory
Disable-ConsumerFeatures
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

Write-Stage "STAGE 02: Buildup"
Install-Chrome
Set-ChromeDefaults
Show-FileExtensions
Show-HiddenFiles
Disable-MouseAcceleration
Prefer-IPv4OverIPv6
Disable-TaskbarSearchIcon
Disable-TaskbarTaskViewIcon

Write-Stage "STAGE END: Summary"

if (Test-IsAdmin) {
    Write-SummaryItem -Status "PASS" -Message "Running as Administrator"
} else {
    Write-SummaryItem -Status "INFO" -Message "Not running as Administrator"
}

if (Test-CommandExists -Name "winget") {
    Write-SummaryItem -Status "PASS" -Message "winget available"
} else {
    Write-SummaryItem -Status "WARN" -Message "winget not found"
}

$chromePaths = @(
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe")
)

if (Test-PathExists -Path $chromePaths) {
    Write-SummaryItem -Status "PASS" -Message "Chrome found"
} else {
    Write-SummaryItem -Status "WARN" -Message "Chrome executable not found"
}

$chromeDefaultsXmlPath = Join-Path $env:TEMP "zerowin-default-apps.xml"
if (Test-Path $chromeDefaultsXmlPath) {
    Write-SummaryItem -Status "PASS" -Message "Chrome default associations XML found: $chromeDefaultsXmlPath"
} else {
    Write-SummaryItem -Status "INFO" -Message "Chrome default associations XML not found: $chromeDefaultsXmlPath"
}

$oneDriveSetupPaths = @(
    (Join-Path $env:SystemRoot "System32\OneDriveSetup.exe"),
    (Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe")
)

if (Test-PathExists -Path $oneDriveSetupPaths) {
    Write-SummaryItem -Status "WARN" -Message "OneDrive setup executable still present"
} else {
    Write-SummaryItem -Status "PASS" -Message "OneDrive setup executable not found"
}

if (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue) {
    Write-SummaryItem -Status "WARN" -Message "OneDrive process is running"
} else {
    Write-SummaryItem -Status "PASS" -Message "OneDrive process not running"
}

$edgePaths = @(
    (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe")
)

if (Test-PathExists -Path $edgePaths) {
    Write-SummaryItem -Status "WARN" -Message "Edge executable still present"
} else {
    Write-SummaryItem -Status "PASS" -Message "Edge executable not found"
}

$webView2Paths = @(
    (Join-Path $env:ProgramFiles "Microsoft\EdgeWebView\Application\msedgewebview2.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Microsoft\EdgeWebView\Application\msedgewebview2.exe")
)

if (Test-PathExists -Path $webView2Paths) {
    Write-SummaryItem -Status "INFO" -Message "WebView2 Runtime present, preserved intentionally"
} else {
    Write-SummaryItem -Status "INFO" -Message "WebView2 Runtime executable not found"
}

$ipv4Preference = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue).DisabledComponents
if ($ipv4Preference -eq 32) {
    Write-SummaryItem -Status "PASS" -Message "IPv4 preference registry value is set to 32"
} else {
    Write-SummaryItem -Status "WARN" -Message "IPv4 preference registry value is not set to 32"
}

$explorerAdvanced = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
if ($explorerAdvanced.HideFileExt -eq 0) {
    Write-SummaryItem -Status "PASS" -Message "File extensions are set to show"
} else {
    Write-SummaryItem -Status "WARN" -Message "File extensions setting is not set to show"
}

if ($explorerAdvanced.Hidden -eq 1) {
    Write-SummaryItem -Status "PASS" -Message "Hidden files are set to show"
} else {
    Write-SummaryItem -Status "WARN" -Message "Hidden files setting is not set to show"
}

$searchSettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -ErrorAction SilentlyContinue
$searchPolicy = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -ErrorAction SilentlyContinue
if (($searchSettings.BingSearchEnabled -eq 0) -or ($searchPolicy.DisableSearchBoxSuggestions -eq 1)) {
    Write-SummaryItem -Status "PASS" -Message "Bing search disabled registry value found"
} else {
    Write-SummaryItem -Status "WARN" -Message "Bing search disabled registry value not found"
}

$copilotPolicy = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -ErrorAction SilentlyContinue
if ($copilotPolicy.TurnOffWindowsCopilot -eq 1) {
    Write-SummaryItem -Status "PASS" -Message "Copilot disabled registry value found"
} else {
    Write-SummaryItem -Status "WARN" -Message "Copilot disabled registry value not found"
}

$terminalServerSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -ErrorAction SilentlyContinue
if ($terminalServerSettings.fDenyTSConnections -eq 0) {
    Write-SummaryItem -Status "INFO" -Message "Remote Desktop appears enabled"
} else {
    Write-SummaryItem -Status "INFO" -Message "Remote Desktop appears disabled"
}

$rdpTcpSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -ErrorAction SilentlyContinue
if ($rdpTcpSettings.UserAuthentication -eq 1) {
    Write-SummaryItem -Status "INFO" -Message "Remote Desktop Network Level Authentication appears enabled"
} elseif ($rdpTcpSettings.UserAuthentication -eq 0) {
    Write-SummaryItem -Status "WARN" -Message "Remote Desktop Network Level Authentication appears disabled"
} else {
    Write-SummaryItem -Status "INFO" -Message "Remote Desktop Network Level Authentication setting not found"
}

$xboxPackages = Get-AppxPackage -Name "Microsoft.Xbox*" -ErrorAction SilentlyContinue
$gameBarPackages = Get-AppxPackage -Name "Microsoft.XboxGamingOverlay" -ErrorAction SilentlyContinue
if ($xboxPackages -or $gameBarPackages) {
    Write-SummaryItem -Status "INFO" -Message "Xbox/Game Bar packages appear present"
} else {
    Write-SummaryItem -Status "INFO" -Message "Xbox/Game Bar packages not found for current user"
}

if ($script:StartMenuCleanupAttempted) {
    Write-SummaryItem -Status "INFO" -Message "Start menu cleanup attempted; sign out/restart may be required"
} else {
    Write-SummaryItem -Status "INFO" -Message "Start menu cleanup did not run"
}

if ($script:BaselineStoreBloatCleanupRan) {
    Write-SummaryItem -Status "PASS" -Message "Baseline Store bloat cleanup ran"
} else {
    Write-SummaryItem -Status "INFO" -Message "Baseline Store bloat cleanup did not run"
}

Invoke-OptionalModulesMenu
