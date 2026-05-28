# 003 Safe Start Menu

## Summary

Changed Windows Scrubber startup so `install.ps1` checks for Administrator rights first, exits cleanly if not elevated, and opens a main menu when elevated. Cleanup no longer runs automatically on startup.

Menu options now include:

1. Full cleanup / scrubber flow
2. Install apps

The full cleanup option preserves the existing cleanup/buildout/summary flow. The app bundle option installs Google Chrome, 7-Zip, AltDrag, and Discord with winget.

## Files Changed

- `install.ps1`
- `tweaks/baseline.ps1`
- `data/apps.json`
- `README.md`
- `dev-notes/003-safe-start-menu.md`

## Validation Performed

- Confirmed non-admin `install.ps1` launch exits with `Please run PowerShell as Administrator.`
- Confirmed the elevated path is structured to stage files, dot-source `baseline.ps1`, and call `Show-MainMenu` without invoking cleanup first.
- Confirmed menu item 1 calls `Invoke-FullCleanup`, which contains the previous full cleanup/buildout/summary flow.
- Confirmed menu item 2 installs Google Chrome, 7-Zip, AltDrag, and Discord by winget ID.
- Confirmed `install.ps1` remains the main entrypoint.
- Confirmed `README.md` reflects the new menu-first behavior.

## Risks/Notes

- Local validation environment does not have `winget`, so AltDrag package ID was checked against the public winget package index instead of local `winget search`. The selected ID is `AltDrag.AltDrag`.
- App installs still depend on winget being available on the target Windows install.
- Full cleanup still performs the same Windows changes as before once menu item 1 is selected.

## Next Suggested Step

From a fresh elevated PowerShell session after publishing, verify:

```powershell
irm https://git.yenkuri.com | iex
```

Then select option 1 for cleanup or option 2 for the app bundle.
