function Show-MainMenu {
    while ($true) {
        Write-ScrubberStage "Windows Scrubber"
        Write-Host "Choose an option."
        Write-Host ""
        Write-Host "[1] Full cleanup / scrubber flow"
        Write-Host "[2] Install apps"
        Write-Host "[3] Install PC testing utilities"
        Write-Host "[4] Enable Remote Desktop"
        Write-Host "[5] Configure automatic local sign-in"
        Write-Host "[Q] Quit"

        $selection = Read-Host "Choose an option"

        if ([string]::IsNullOrWhiteSpace($selection)) {
            Write-Host "INFO: See you next time! :)"
            return
        }

        switch ($selection) {
            "1" { Invoke-FullCleanup }
            "2" { Install-WorkstationAppBundle }
            "3" { Install-PcTestingUtilityBundle }
            "4" { Enable-RemoteDesktop }
            "5" { Invoke-AutoLogonMenu }
            "Q" { Write-Host "INFO: See you next time! :)"; return }
            "q" { Write-Host "INFO: See you next time! :)"; return }
            default { Write-Host "INFO: Invalid selection. Choose an option or press Enter to quit." }
        }
    }
}
