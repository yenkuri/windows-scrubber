function Invoke-FullCleanup {
    Write-ScrubberStage "STAGE 00: Preflight"
    Write-Host "Running as Administrator: $(Test-IsAdmin)"
    Write-Host "winget available: $([bool](Get-Command winget -ErrorAction SilentlyContinue))"

    Write-ScrubberStage "STAGE 01: Cleanout"
    Disable-AdvertisingId
    Disable-TailoredExperiences
    Disable-FeedbackPrompts
    Disable-ActivityHistory
    Disable-ConsumerFeatures
    Disable-StoreConsumerChurn
    Disable-WindowsTipsAndSetupPrompts
    Disable-StoreAutoUpdates
    Optimize-WindowsSearchIndexing
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

    Write-ScrubberStage "STAGE 02: Buildup"
    Set-WindowsDarkTheme
    Set-WindowsScrubberDesktop
    Show-FileExtensions
    Show-HiddenFiles
    Disable-MouseAcceleration
    Prefer-IPv4OverIPv6
    Disable-TaskbarSearchIcon
    Disable-TaskbarTaskViewIcon
    Restart-ExplorerShell

    Write-ScrubberStage "STAGE END: Summary"

    Invoke-ScrubberSummary
}
