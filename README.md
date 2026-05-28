# Windows Scrubber

A small PowerShell scrubber for fresh Windows installs. It cleans up noisy defaults, installs a few workstation basics, then offers optional extras you can run only if you want them.

## Quick Run

Run from an elevated PowerShell session:

```powershell
irm https://windows.yenkuri.com/run | iex
```

Explicit/full installer form:

```powershell
irm https://windows.yenkuri.com/install.ps1 | iex
```

`/run` is only a tiny launcher endpoint. `install.ps1` remains the real installer, and PowerShell should be run as Administrator.

The installer stages the required files under `%TEMP%\windows-scrubber\`, keeps the same repo folder layout, sets execution policy bypass for the current PowerShell process only, then runs `tweaks/baseline.ps1`.

It downloads only:

- `tweaks/baseline.ps1`
- `lib/helpers.ps1`
- `modules/cleanout.ps1`
- `modules/buildup.ps1`
- `modules/optional.ps1`
- `modules/summary.ps1`

## What Happens

Windows Scrubber runs in stages:

- `STAGE 00: Preflight`: checks Administrator status and `winget`.
- `STAGE 01: Cleanout`: applies privacy, search, recommendations, Start menu, Store bloat, Widgets, Copilot, OneDrive, Edge, startup, Store auto-update, and Windows Search indexing cleanup.
- `STAGE 02: Buildup`: installs Chrome and 7-Zip, prepares Chrome defaults, sets desktop/wallpaper and dark theme preferences, shows file extensions and hidden files, disables mouse acceleration, prefers IPv4, and applies taskbar preferences.
- `STAGE END: Summary`: prints PASS/WARN/INFO checks for the important bits.

Some changes need Explorer restart, sign out, or a reboot before Windows fully shows them.

## Optional Extras

After the baseline, you can run extra tools from a menu:

- Remove Xbox / Game Bar / Game DVR packages and disable capture features
- Enable Remote Desktop
- Configure automatic local sign-in, including local/offline account boot sign-in and wake sign-in requirements
- Configure a no-sleep power plan
- Leave the menu with `Q`, `q`, or Enter

Optional tools are not part of the default baseline, and the risky ones ask before doing anything exciting.

## Project Layout

- `run`: short GitHub Pages launcher for `install.ps1`.
- `install.ps1`: remote launcher and temp staging.
- `tweaks/baseline.ps1`: entrypoint, prompts, module loading, and stage order.
- `lib/helpers.ps1`: shared helper functions.
- `modules/cleanout.ps1`: cleanup stage functions.
- `modules/buildup.ps1`: setup/buildout stage functions.
- `modules/optional.ps1`: optional menu and extra tools.
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
- Non-admin runs skip admin-only changes where possible.

Have a look through the scripts before running them on a machine you care about. Tiny bit boring, very worth it.
