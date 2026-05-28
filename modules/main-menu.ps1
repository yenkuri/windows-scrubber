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
