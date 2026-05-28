# 004 Main Menu Utility Options

## Summary

Added Remote Desktop, automatic local sign-in, and no-sleep power plan options back to the main Windows Scrubber menu.

The tools still use the existing implementations from `modules/optional.ps1`; no duplicate setup logic was added.

Moved app-specific work out of the cleanup flow. The scrubber cleanup no longer installs Chrome or 7-Zip and no longer applies Chrome defaults; app installation and Chrome default setup now live behind the install apps menu item.

## Files Changed

- `tweaks/baseline.ps1`
- `README.md`
- `dev-notes/004-main-menu-remote-login.md`

## Validation Performed

- Confirmed `Enable-RemoteDesktop`, `Invoke-AutoLogonMenu`, and `Set-NoSleepPowerPlan` already exist in `modules/optional.ps1`.
- Confirmed the main menu now lists options 3, 4, and 5.
- Confirmed menu option 3 calls `Enable-RemoteDesktop`.
- Confirmed menu option 4 calls `Invoke-AutoLogonMenu`.
- Confirmed menu option 5 calls `Set-NoSleepPowerPlan`.
- Confirmed cleanup no longer calls `Install-Chrome`, `Install-7Zip`, or `Set-ChromeDefaults`.
- Confirmed install apps still installs Google Chrome, 7-Zip, AltDrag, and Discord.
- Confirmed `README.md` documents the restored menu options.

## Risks/Notes

- Remote Desktop and automatic local sign-in still require Administrator rights; `install.ps1` already exits before the menu if PowerShell is not elevated.
- Automatic local sign-in keeps using the existing warning and confirmation prompts before writing Winlogon values.
- No-sleep power plan keeps using the existing warning and confirmation prompt before changing power settings.
- Chrome default setup runs after the install apps bundle, so it only happens when app installation is selected.

## Next Suggested Step

From an elevated PowerShell session, launch Windows Scrubber and verify options 3, 4, and 5 open the expected flows:

```powershell
irm https://git.yenkuri.com | iex
```
