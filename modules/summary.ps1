function Invoke-ScrubberSummary {
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
    
    $sevenZipPaths = @(
        (Join-Path $env:ProgramFiles "7-Zip\7z.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "7-Zip\7z.exe")
    )
    
    if (Test-PathExists -Path $sevenZipPaths) {
        Write-SummaryItem -Status "PASS" -Message "7-Zip found"
    } else {
        Write-SummaryItem -Status "WARN" -Message "7-Zip executable not found"
    }
    
    $chromeDefaultsXmlPath = Join-Path $env:TEMP "windows-scrubber-default-apps.xml"
    if (Test-Path $chromeDefaultsXmlPath) {
        Write-SummaryItem -Status "PASS" -Message "Chrome default associations XML found: $chromeDefaultsXmlPath"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Chrome default associations XML not found: $chromeDefaultsXmlPath"
    }
    
    $desktopAdvanced = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
    if ($desktopAdvanced.HideIcons -eq 1) {
        Write-SummaryItem -Status "PASS" -Message "Desktop icons hidden setting is enabled"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Desktop icons hidden setting is not enabled"
    }

    $themePersonalize = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ErrorAction SilentlyContinue
    if (($themePersonalize.AppsUseLightTheme -eq 0) -and ($themePersonalize.SystemUsesLightTheme -eq 0)) {
        Write-SummaryItem -Status "PASS" -Message "Windows app and system theme are set to dark"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows app and system theme are not both set to dark"
    }
    
    $wallpaperPath = Join-Path (Join-Path $env:TEMP "windows-scrubber") "wallpaper.png"
    if (Test-Path $wallpaperPath) {
        Write-SummaryItem -Status "PASS" -Message "Windows Scrubber wallpaper file found: $wallpaperPath"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows Scrubber wallpaper file not found: $wallpaperPath"
    }
    
    if ($script:DesktopShortcutCleanupAttempted) {
        Write-SummaryItem -Status "INFO" -Message "Desktop shortcut cleanup attempted"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Desktop shortcut cleanup did not run"
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
    
    $winlogonSettings = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue
    if ($winlogonSettings.AutoAdminLogon -eq "1") {
        Write-SummaryItem -Status "WARN" -Message "Automatic local sign-in appears enabled"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Automatic local sign-in appears disabled"
    }

    $passwordlessDeviceSettings = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" -ErrorAction SilentlyContinue
    if ($passwordlessDeviceSettings.DevicePasswordLessBuildVersion -eq 0) {
        Write-SummaryItem -Status "INFO" -Message "Windows passwordless-only sign-in requirement appears disabled"
    } elseif ($passwordlessDeviceSettings.DevicePasswordLessBuildVersion -eq 2) {
        Write-SummaryItem -Status "INFO" -Message "Windows passwordless-only sign-in requirement appears enabled"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows passwordless-only sign-in requirement setting not found"
    }

    $wakeSignInRequirement = Get-PowerCfgAcSetting -Subgroup "SUB_NONE" -Setting "CONSOLELOCK"
    if ($wakeSignInRequirement -eq 0) {
        Write-SummaryItem -Status "INFO" -Message "AC wake sign-in requirement appears disabled"
    } elseif ($wakeSignInRequirement -eq 1) {
        Write-SummaryItem -Status "INFO" -Message "AC wake sign-in requirement appears enabled"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Could not check AC wake sign-in requirement"
    }
    
    try {
        $powerAvailability = (& powercfg /a 2>&1) -join "`n"
    
        if ($powerAvailability -match "Hibernation has not been enabled|The hiberfile type does not support hibernation") {
            Write-SummaryItem -Status "PASS" -Message "Hibernation appears disabled"
        } else {
            Write-SummaryItem -Status "INFO" -Message "Hibernation may be available or enabled"
        }
    } catch {
        Write-SummaryItem -Status "INFO" -Message "Could not check hibernation status"
    }
    
    $acStandbyTimeout = Get-PowerCfgAcSetting -Subgroup "SUB_SLEEP" -Setting "STANDBYIDLE"
    if ($null -ne $acStandbyTimeout) {
        Write-SummaryItem -Status "INFO" -Message "Current AC standby timeout: $acStandbyTimeout seconds"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Current AC standby timeout could not be read"
    }
    
    $acMonitorTimeout = Get-PowerCfgAcSetting -Subgroup "SUB_VIDEO" -Setting "VIDEOIDLE"
    if ($null -ne $acMonitorTimeout) {
        Write-SummaryItem -Status "INFO" -Message "Current AC monitor timeout: $acMonitorTimeout seconds"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Current AC monitor timeout could not be read"
    }
    
    $windowsSearchService = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($windowsSearchService) {
        Write-SummaryItem -Status "INFO" -Message "Windows Search service exists"
    
        if ($windowsSearchService.Status -eq "Running") {
            Write-SummaryItem -Status "INFO" -Message "Windows Search service is running"
        } else {
            Write-SummaryItem -Status "INFO" -Message "Windows Search service status: $($windowsSearchService.Status)"
        }
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows Search service not found"
    }
    
    if ($script:SearchIndexingOptimizationAttempted) {
        Write-SummaryItem -Status "INFO" -Message "Windows Search indexing optimisation attempted"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows Search indexing optimisation skipped; no non-system fixed drives found"
    }
    
    $cloudContentPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ErrorAction SilentlyContinue
    $contentDeliverySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -ErrorAction SilentlyContinue
    if (($cloudContentPolicy.DisableWindowsConsumerFeatures -eq 1) -or (($contentDeliverySettings.SilentInstalledAppsEnabled -eq 0) -and ($contentDeliverySettings.ContentDeliveryAllowed -eq 0))) {
        Write-SummaryItem -Status "PASS" -Message "Consumer app provisioning cleanup appears applied"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Consumer app provisioning cleanup not fully detected"
    }
    
    $userProfileEngagement = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -ErrorAction SilentlyContinue
    if (($userProfileEngagement.ScoobeSystemSettingEnabled -eq 0) -and ($contentDeliverySettings.SoftLandingEnabled -eq 0)) {
        Write-SummaryItem -Status "PASS" -Message "Windows tips/setup prompts cleanup appears applied"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Windows tips/setup prompts cleanup not fully detected"
    }
    
    $storePolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -ErrorAction SilentlyContinue
    if ($storePolicy.AutoDownload -eq 2) {
        Write-SummaryItem -Status "WARN" -Message "Microsoft Store auto-updates policy appears disabled"
    } elseif ($null -ne $storePolicy.AutoDownload) {
        Write-SummaryItem -Status "INFO" -Message "Microsoft Store auto-updates policy configured with value $($storePolicy.AutoDownload)"
    } else {
        Write-SummaryItem -Status "INFO" -Message "Microsoft Store auto-updates policy not configured"
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
    
    Write-Host ""
    Write-Host "Standard scrub complete."
    Write-Host "Returning to the Windows Scrubber menu."
}
