# Windows Scrubber

A small PowerShell scrubber for fresh Windows installs. It cleans up noisy defaults, installs a few workstation basics, then offers utility tools you can run only if you want them.

## Quick Run

Run from an elevated PowerShell session:

```powershell
irm https://git.yenkuri.com | iex
```

Compatibility alias:

```powershell
irm https://git.yenkuri.com/run | iex
```

Explicit/full installer form:

```powershell
irm https://git.yenkuri.com/install.ps1 | iex
```

The root endpoint and `/run` are only tiny launcher endpoints. `install.ps1` remains the real installer, and PowerShell should be run as Administrator.

The installer checks for Administrator rights, stages the required files under `%TEMP%\windows-scrubber\`, keeps the same repo folder layout, sets execution policy bypass for the current PowerShell process only, then opens the interactive menu.

It downloads only:

- `tweaks/baseline.ps1`
- `lib/helpers.ps1`
- `modules/cleanout.ps1`
- `modules/buildup.ps1`
- `modules/optional.ps1`
- `modules/summary.ps1`
- `modules/full-cleanup.ps1`
- `modules/app-bundle.ps1`
- `modules/main-menu.ps1`

## What Happens

Windows Scrubber exits cleanly with `Please run PowerShell as Administrator.` if PowerShell is not elevated. When run as Administrator, it opens a menu without running cleanup automatically:

1. Full cleanup / scrubber flow
2. Install apps
3. Enable Remote Desktop
4. Configure automatic local sign-in
5. Configure no-sleep power plan

The full cleanup / scrubber flow runs the existing stages:

- `STAGE 00: Preflight`: checks Administrator status and `winget`.
- `STAGE 01: Cleanout`: applies privacy, search, recommendations, Start menu, Store bloat, Widgets, Copilot, OneDrive, Edge, startup, Store auto-update, and Windows Search indexing cleanup.
- `STAGE 02: Buildup`: sets desktop/wallpaper and dark theme preferences, shows file extensions and hidden files, disables mouse acceleration, prefers IPv4, and applies taskbar preferences.
- `STAGE END: Summary`: prints PASS/WARN/INFO checks for the important bits.

The cleanup flow does not install apps. Some changes need Explorer restart, sign out, or a reboot before Windows fully shows them.

The install apps option installs:

- Google Chrome
- 7-Zip
- AltDrag
- Discord

The Remote Desktop, automatic local sign-in, and no-sleep power plan options are available directly from the main menu. Automatic local sign-in can enable or disable the saved local login configuration.

## Utility Options

The starting menu also includes utility tools:

- Enable Remote Desktop
- Configure automatic local sign-in, including local/offline account boot sign-in and wake sign-in requirements
- Configure a no-sleep power plan
- Leave the menu with `Q`, `q`, or Enter

Utility tools are not part of the cleanup flow, and the risky ones ask before doing anything exciting.

## Project Layout

- `index.html`: root GitHub Pages launcher for `install.ps1`.
- `run`: compatibility GitHub Pages launcher for `install.ps1`.
- `install.ps1`: remote launcher and temp staging.
- `tweaks/baseline.ps1`: entrypoint loader for helpers and modules.
- `lib/helpers.ps1`: shared helper functions.
- `modules/main-menu.ps1`: starting menu loop and menu routing.
- `modules/full-cleanup.ps1`: full cleanup / scrubber flow.
- `modules/app-bundle.ps1`: app bundle installation.
- `modules/cleanout.ps1`: cleanup stage functions.
- `modules/buildup.ps1`: setup/buildout stage functions.
- `modules/optional.ps1`: utility tools used by main menu options.
- `modules/summary.ps1`: final summary checks.

`baseline.ps1` loads helpers and modules with paths based on `$PSScriptRoot`, and fails clearly if a required file is missing.

## Safety Notes

- It is meant for fresh installs and rebuilds.
- It does not delete user documents, downloads, images, or folders.
- Desktop cleanup removes only `.lnk` shortcuts from the current and Public Desktop.
- Desktop setup sets the current user's app and system theme to dark.
- Automatic local sign-in stores the account password in Winlogon registry values and disables wake sign-in for the current power scheme.
- OneDrive removal does not delete files from OneDrive folders.
- Edge cleanup preserves WebView2 Runtime and user browser data.
- Microsoft Store, App Installer/winget, common system apps, and protected Windows components are intentionally preserved.
- Non-admin runs exit before staging or making changes.

Have a look through the scripts before running them on a machine you care about. Tiny bit boring, very worth it.
