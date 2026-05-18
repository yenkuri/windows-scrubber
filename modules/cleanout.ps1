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


function Disable-ConsumerFeatures {
    Invoke-Tweak "Disable Consumer Features" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Consumer Features policy tweaks."
            return
        }

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    }
}

function Disable-StoreConsumerChurn {
    Invoke-Tweak "Disable Store consumer app churn" {
        if (Test-IsAdmin) {
            Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
            Write-Host "PASS: HKLM consumer feature policy applied."
        } else {
            Write-Skip "Administrator rights are required for HKLM consumer feature policy."
        }

        $contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        $contentValues = @{
            SilentInstalledAppsEnabled = 0
            ContentDeliveryAllowed = 0
            OemPreInstalledAppsEnabled = 0
            PreInstalledAppsEnabled = 0
            PreInstalledAppsEverEnabled = 0
            SystemPaneSuggestionsEnabled = 0
            "SubscribedContent-338388Enabled" = 0
            "SubscribedContent-338389Enabled" = 0
            "SubscribedContent-338393Enabled" = 0
            "SubscribedContent-353694Enabled" = 0
            "SubscribedContent-353696Enabled" = 0
        }

        foreach ($name in $contentValues.Keys) {
            Set-RegistryDword -Path $contentPath -Name $name -Value $contentValues[$name]
        }

        Write-Host "PASS: Current-user Store consumer content settings applied."
        Write-Host "INFO: Microsoft Store auto-updates are not disabled by baseline."
    }
}

function Disable-WindowsTipsAndSetupPrompts {
    Invoke-Tweak "Disable Windows tips and setup prompts" {
        $contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        $contentValues = @{
            "SubscribedContent-310093Enabled" = 0
            "SubscribedContent-338387Enabled" = 0
            "SubscribedContent-338388Enabled" = 0
            "SubscribedContent-338389Enabled" = 0
            "SubscribedContent-338393Enabled" = 0
            "SubscribedContent-353694Enabled" = 0
            "SubscribedContent-353696Enabled" = 0
            SoftLandingEnabled = 0
            RotatingLockScreenEnabled = 0
            RotatingLockScreenOverlayEnabled = 0
            SystemPaneSuggestionsEnabled = 0
            ContentDeliveryAllowed = 0
        }

        foreach ($name in $contentValues.Keys) {
            Set-RegistryDword -Path $contentPath -Name $name -Value $contentValues[$name]
        }

        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Value 0
        Write-Host "PASS: Current-user Windows tips and setup prompt settings applied."

        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Windows tips/setup prompt policies."
            return
        }

        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1
        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1
        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableLogonBackgroundImage" -Value 0
        Write-Host "PASS: HKLM Windows tips and setup prompt policies applied."
        Write-Host "INFO: Windows Update, Microsoft Store, and installed apps were not disabled or removed."
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

        Write-Host "INFO: Start Menu layout cleanup is best effort. Explorer restart, sign out, or reboot may be required before visual changes appear."
    }
}

function Restart-ExplorerShell {
    Invoke-Tweak "Restart Explorer shell" {
        Write-Host "INFO: Restarting Explorer to refresh Start menu, desktop, and taskbar changes."

        try {
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Process "explorer.exe"
            Write-Host "PASS: Explorer restarted."
        } catch {
            Write-Skip "Could not restart Explorer: $($_.Exception.Message)"
        }
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


function Optimize-WindowsSearchIndexing {
    Invoke-Tweak "Optimise Windows Search indexing" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to optimise Windows Search indexing."
            return
        }

        Write-Host "WARN: This reduces Windows indexing scope. It should improve background load, but file search may become less complete."
        $confirmation = Read-Host "Optimise Windows Search indexing? (y/N)"

        if ($confirmation -notin @("y", "Y")) {
            Write-Host "INFO: Windows Search indexing optimisation cancelled."
            return
        }

        $script:SearchIndexingOptimizationAttempted = $true
        $searchService = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue

        if ($searchService) {
            Write-Host "INFO: Windows Search service is preserved. Current status: $($searchService.Status)"
        } else {
            Write-Host "INFO: Windows Search service was not found."
        }

        $systemDrive = $env:SystemDrive.TrimEnd("\")
        $fixedDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction SilentlyContinue

        foreach ($drive in $fixedDrives) {
            $driveRoot = $drive.DeviceID.TrimEnd("\")

            if ($driveRoot -ieq $systemDrive) {
                Write-Host "INFO: Skipping system drive indexing attribute change: $driveRoot"
                continue
            }

            try {
                $attribTarget = "$driveRoot\*"
                $attribOutput = & attrib -I $attribTarget /S /D 2>&1
                $attribExitCode = $LASTEXITCODE

                if ($attribExitCode -eq 0) {
                    Write-Host "PASS: Disabled indexing attribute on fixed drive: $driveRoot"
                } else {
                    Write-Host "WARN: attrib indexing update exited with code $attribExitCode for $driveRoot"
                    $attribText = ($attribOutput | Out-String).Trim()

                    if ($attribText -and ($attribText.Length -le 400)) {
                        Write-Host $attribText
                    }
                }
            } catch {
                Write-Host "WARN: Could not update indexing attribute on ${driveRoot}: $($_.Exception.Message)"
            }
        }

        # Keep search service enabled, but reduce web suggestions and noisy indexing scope.
        Set-RegistryDword -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0

        # Do not index encrypted items.
        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowIndexingEncryptedStoresOrItems" -Value 0

        # Avoid indexing uncached Exchange folders when applicable.
        Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "PreventIndexingUncachedExchangeFolders" -Value 1

        $rebuild = Read-Host "Rebuild Windows Search index now? This can take time. (y/N)"

        if ($rebuild -notin @("y", "Y")) {
            Write-Host "INFO: Windows Search index rebuild skipped."
            return
        }

        if (-not $searchService) {
            Write-Host "INFO: Windows Search service was not found; index restart skipped."
            return
        }

        try {
            Stop-Service -Name "WSearch" -ErrorAction Stop
            Start-Service -Name "WSearch" -ErrorAction Stop
            Write-Host "PASS: Windows Search service restarted for index rebuild."
        } catch {
            Write-Host "WARN: Could not restart Windows Search service: $($_.Exception.Message)"
        }
    }
}

function Disable-StoreAutoUpdates {
    Invoke-Tweak "Disable Microsoft Store auto-updates" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to disable Microsoft Store auto-updates."
            return
        }

        Write-Host "WARN: Disabling Store auto-updates can reduce background churn, but may leave Store apps/App Installer components outdated."
        $confirmation = Read-Host "Disable Microsoft Store auto-updates? (y/N)"

        if ($confirmation -notin @("y", "Y")) {
            Write-Host "INFO: Microsoft Store auto-update change cancelled."
            return
        }

        try {
            Set-RegistryDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value 2
            Write-Host "PASS: Microsoft Store auto-updates policy disabled."
            Write-Host "INFO: Microsoft Store itself was not disabled or removed."
        } catch {
            Write-Host "WARN: Could not set Microsoft Store auto-updates policy: $($_.Exception.Message)"
        }
    }
}

