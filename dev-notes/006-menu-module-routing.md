# 006 Menu Module Routing

## Summary

Split the startup menu into its own module so every action returns to the same starting Windows Scrubber menu.

`modules/main-menu.ps1` now owns `Show-MainMenu`. Menu items route to separate modules:

- `modules/full-cleanup.ps1` for full cleanup / scrubber flow
- `modules/app-bundle.ps1` for app installs
- `modules/optional.ps1` for Remote Desktop, automatic local sign-in, and no-sleep power plan utilities

## Files Changed

- `install.ps1`
- `tweaks/baseline.ps1`
- `modules/main-menu.ps1`
- `modules/full-cleanup.ps1`
- `modules/app-bundle.ps1`
- `modules/summary.ps1`
- `README.md`
- `dev-notes/006-menu-module-routing.md`

## Validation Performed

- Confirmed `install.ps1` stages the new menu, cleanup, and app-bundle modules.
- Confirmed `baseline.ps1` loads the new modules and no longer defines menu or action entry functions inline.
- Confirmed `Show-MainMenu` lives in `modules/main-menu.ps1`.
- Confirmed cleanup no longer calls `Invoke-OptionalModulesMenu`.
- Confirmed the summary message now says it is returning to the Windows Scrubber menu.
- Confirmed PowerShell parse checks pass for the changed scripts.
- Confirmed the starting menu renders from the new menu module.
- Confirmed a mocked cleanup selection returns to the same starting menu before quitting.

## Risks/Notes

- `Invoke-OptionalModulesMenu` remains in `modules/optional.ps1` for compatibility, but the main flow no longer calls it.
- The installed temp copy must include the three new module files, so `install.ps1` now downloads them explicitly.
- After GitHub Pages publishes, old temp files can be overwritten by rerunning the launcher.

## Next Suggested Step

From an elevated PowerShell session, run cleanup and confirm it returns to the starting menu after the summary:

```powershell
irm https://git.yenkuri.com | iex
```
