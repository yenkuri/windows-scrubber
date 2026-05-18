$ErrorActionPreference = "Stop"

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

Disable-AdvertisingId
Disable-TailoredExperiences
Disable-FeedbackPrompts
Disable-ActivityHistory
Disable-StartMenuBingSearch
Show-FileExtensions
Show-HiddenFiles
Disable-MouseAcceleration
Disable-ConsumerFeatures
Disable-LocationTracking
Disable-Widgets
Disable-Copilot
Disable-StartMenuRecommendations
Disable-TaskbarSearchIcon
Disable-TaskbarTaskViewIcon
Disable-AppAutoStartEntries
