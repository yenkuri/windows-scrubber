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

function Set-WakeSignInRequirement {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Required
    )

    $value = if ($Required) { "1" } else { "0" }
    $state = if ($Required) { "enabled" } else { "disabled" }

    Invoke-PowerCfgCommand -Description "AC wake sign-in requirement $state" -Arguments @("/setacvalueindex", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", $value)
    Invoke-PowerCfgCommand -Description "DC wake sign-in requirement $state" -Arguments @("/setdcvalueindex", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", $value)
    Invoke-PowerCfgCommand -Description "Current power scheme applied" -Arguments @("/setactive", "SCHEME_CURRENT")
}

function Enable-AutoLogon {
    Invoke-Tweak "Enable automatic local sign-in" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to configure automatic local sign-in."
            return
        }

        Write-Host "WARN: This keeps the account password but allows Windows to sign in automatically at boot."
        Write-Host "WARN: Registry AutoAdminLogon stores the password in Winlogon registry values. Only use this on trusted machines."
        $confirmation = Read-Host "Continue? (y/N)"

        if ($confirmation -notin @("y", "Y")) {
            Write-Host "INFO: Automatic local sign-in setup cancelled."
            return
        }

        $username = Read-Host "Username"

        if ([string]::IsNullOrWhiteSpace($username)) {
            Write-Host "WARN: Username was empty. Automatic local sign-in was not configured."
            return
        }

        $securePassword = Read-Host "Password" -AsSecureString
        $domainName = Read-Host "Domain/computer name [$env:COMPUTERNAME]"

        if ([string]::IsNullOrWhiteSpace($domainName)) {
            $domainName = $env:COMPUTERNAME
        }

        $passwordPointer = [IntPtr]::Zero
        $plainPassword = $null

        try {
            $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)

            $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            New-ItemProperty -Path $path -Name "AutoAdminLogon" -Value "1" -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $path -Name "DefaultUserName" -Value $username -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $path -Name "DefaultPassword" -Value $plainPassword -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $path -Name "DefaultDomainName" -Value $domainName -PropertyType String -Force | Out-Null

            Set-RegistryDword -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" -Name "DevicePasswordLessBuildVersion" -Value 0
            Set-WakeSignInRequirement -Required $false

            Write-Host "PASS: Automatic local sign-in configured."
            Write-Host "PASS: Windows passwordless-only sign-in requirement disabled for local automatic sign-in."
            Write-Host "PASS: Password requirement after wake disabled for the current power scheme."
            Write-Host "INFO: Password was written to Winlogon registry values and was not printed."
        } catch {
            Write-Host "WARN: Could not configure automatic local sign-in: $($_.Exception.Message)"
        } finally {
            if ($passwordPointer -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
            }

            $plainPassword = $null
        }
    }
}

function Disable-AutoLogon {
    Invoke-Tweak "Disable automatic local sign-in" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to disable automatic local sign-in."
            return
        }

        $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

        try {
            if (-not (Test-Path $path)) {
                Write-Host "INFO: Winlogon registry path was not found."
                return
            }

            New-ItemProperty -Path $path -Name "AutoAdminLogon" -Value "0" -PropertyType String -Force | Out-Null
            Write-Host "PASS: Automatic local sign-in disabled."

            Remove-RegistryValueIfExists -Path $path -Name "DefaultPassword"
            Remove-RegistryValueIfExists -Path $path -Name "AutoLogonCount"
            Remove-RegistryValueIfExists -Path $path -Name "ForceAutoLogon"
            Set-RegistryDword -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" -Name "DevicePasswordLessBuildVersion" -Value 2
            Set-WakeSignInRequirement -Required $true
            Write-Host "INFO: Auto-logon password and related override values were removed if present."
        } catch {
            Write-Host "WARN: Could not disable automatic local sign-in: $($_.Exception.Message)"
        }
    }
}

function Show-AutoLogonMenu {
    Write-Stage "AUTOMATIC LOCAL SIGN-IN"
    Write-Host "1. Enable automatic local sign-in"
    Write-Host "2. Disable automatic local sign-in"
    Write-Host "Q. Back"
}

function Invoke-AutoLogonMenu {
    while ($true) {
        Show-AutoLogonMenu
        $selection = Read-Host "Select automatic sign-in option"

        switch ($selection) {
            "1" { Enable-AutoLogon; return }
            "2" { Disable-AutoLogon; return }
            "Q" { Write-Host "INFO: Returning to optional modules."; return }
            "q" { Write-Host "INFO: Returning to optional modules."; return }
            "" { Write-Host "INFO: Returning to optional modules."; return }
            default { Write-Host "INFO: Invalid selection. Choose an option or press Enter to go back." }
        }
    }
}

function Invoke-PowerCfgCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    try {
        $output = & powercfg @Arguments 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Host "PASS: $Description"
        } else {
            Write-Host "WARN: $Description failed with exit code $exitCode."
            $outputText = ($output | Out-String).Trim()

            if ($outputText -and ($outputText.Length -le 400)) {
                Write-Host $outputText
            }
        }
    } catch {
        Write-Host "WARN: $Description failed: $($_.Exception.Message)"
    }
}

function Get-PowerCfgAcSetting {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subgroup,

        [Parameter(Mandatory = $true)]
        [string]$Setting
    )

    try {
        $output = & powercfg /query SCHEME_CURRENT $Subgroup $Setting 2>&1
        $text = $output -join "`n"
        $match = [regex]::Match($text, "Current AC Power Setting Index:\s*0x([0-9a-fA-F]+)")

        if ($match.Success) {
            return [Convert]::ToInt32($match.Groups[1].Value, 16)
        }
    } catch {
        return $null
    }

    return $null
}

function Set-NoSleepPowerPlan {
    Invoke-Tweak "Configure no-sleep power plan" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required to configure no-sleep power settings."
            return
        }

        Write-Host "WARN: This disables sleep, display timeout, and hibernation. Best for desktops/bench machines."
        $confirmation = Read-Host "Apply no-sleep power settings? (y/N)"

        if ($confirmation -notin @("y", "Y")) {
            Write-Host "INFO: No-sleep power plan setup cancelled."
            return
        }

        Invoke-PowerCfgCommand -Description "Hibernation disabled" -Arguments @("/hibernate", "off")
        Invoke-PowerCfgCommand -Description "AC sleep timeout disabled" -Arguments @("/change", "standby-timeout-ac", "0")
        Invoke-PowerCfgCommand -Description "DC sleep timeout disabled" -Arguments @("/change", "standby-timeout-dc", "0")
        Invoke-PowerCfgCommand -Description "AC display timeout disabled" -Arguments @("/change", "monitor-timeout-ac", "0")
        Invoke-PowerCfgCommand -Description "DC display timeout disabled" -Arguments @("/change", "monitor-timeout-dc", "0")
        Invoke-PowerCfgCommand -Description "AC disk timeout disabled" -Arguments @("/change", "disk-timeout-ac", "0")
        Invoke-PowerCfgCommand -Description "DC disk timeout disabled" -Arguments @("/change", "disk-timeout-dc", "0")
        Invoke-PowerCfgCommand -Description "AC hybrid sleep disabled" -Arguments @("/setacvalueindex", "SCHEME_CURRENT", "SUB_SLEEP", "HYBRIDSLEEP", "0")
        Invoke-PowerCfgCommand -Description "DC hybrid sleep disabled" -Arguments @("/setdcvalueindex", "SCHEME_CURRENT", "SUB_SLEEP", "HYBRIDSLEEP", "0")
        Invoke-PowerCfgCommand -Description "Current power scheme applied" -Arguments @("/setactive", "SCHEME_CURRENT")
    }
}


function Show-OptionalModulesMenu {
    Write-ScrubberStage "Extra scrubbers"
    Write-Host "Choose an extra scrubber, or press Q to quit."
    Write-Host ""
    Write-Host "[1] Remove Xbox / Game Bar / Game DVR packages and disable capture features"
    Write-Host "[2] Aggressive Microsoft Store app cleanup (coming soon)"
    Write-Host "[3] Aggressive Edge cleanup (coming soon)"
    Write-Host "[4] Enable Remote Desktop"
    Write-Host "[5] Configure automatic local sign-in"
    Write-Host "[6] Reserved / coming soon"
    Write-Host "[7] Configure no-sleep power plan"
    Write-Host "[Q] Quit"
}

function Invoke-OptionalModulesMenu {
    while ($true) {
        Show-OptionalModulesMenu
        $selection = Read-Host "Choose an option"

        switch ($selection) {
            "1" { Remove-XboxGamingFeatures }
            "2" { Write-Host "INFO: Not implemented yet." }
            "3" { Write-Host "INFO: Not implemented yet." }
            "4" { Enable-RemoteDesktop }
            "5" { Invoke-AutoLogonMenu }
            "7" { Set-NoSleepPowerPlan }
            "Q" { Write-Host "INFO: See you next time! :)"; return }
            "q" { Write-Host "INFO: See you next time! :)"; return }
            "" { Write-Host "INFO: See you next time! :)"; return }
            default { Write-Host "INFO: Invalid selection. Choose an option or press Enter to quit." }
        }
    }
}
