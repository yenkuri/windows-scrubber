# Windows Scrubber

A fresh Windows setup and cleanup script for quickly turning a new install into a clean workstation.

## Quick Run

Run this from PowerShell:

```powershell
irm https://raw.githubusercontent.com/r4kk0/windows-scrubber/main/install.ps1 | iex
```

The launcher stages files under `%TEMP%\windows-scrubber\`, sets execution policy bypass for the current PowerShell process only, and runs the baseline. It downloads `tweaks/baseline.ps1` and `lib/helpers.ps1`; the baseline dot-sources helpers from `lib/helpers.ps1`.

## What It Does

Windows Scrubber runs a staged baseline:

- `STAGE 00: Preflight` checks Administrator status and `winget` availability.
- `STAGE 01: Cleanout` applies privacy, search, recommendation, app startup, OneDrive, Edge, Start menu, and baseline Store app cleanup.
- `STAGE 02: Buildup` installs Chrome, applies Chrome default association support, sets desktop/wallpaper preferences, shows file extensions and hidden files, disables mouse acceleration, prefers IPv4, and applies taskbar preferences.
- `STAGE END: Summary` prints a readable PASS/WARN/INFO summary of key settings and detected app state.

Some Windows changes may not appear immediately. Explorer restart, sign out, or a reboot may be required for certain Start menu, desktop, taskbar, default app, or policy changes.

## Optional Modules

After the baseline finishes, an optional menu is shown. These modules run only when explicitly selected:

- Remove Xbox / Game Bar / Game DVR packages and disable capture features
- Enable Remote Desktop
- Configure automatic local sign-in
- Configure a no-sleep power plan
- Placeholders for future aggressive cleanup modules

Optional modules ask for confirmation where appropriate and are not part of the default baseline.

## Safety Notes

- The script does not delete user documents, downloads, images, or folders.
- Desktop cleanup removes only `.lnk` shortcut files from the current and Public Desktop.
- Edge cleanup is conservative and diagnostic; it does not remove WebView2 Runtime or user browser data.
- OneDrive removal does not delete files from OneDrive folders.
- Microsoft Store, App Installer/winget, common system apps, and protected Windows components are intentionally preserved.
- Some HKLM/system changes require running PowerShell as Administrator; non-admin runs skip those parts where possible.

## Local Testing

From the repo root:

```powershell
.\install.ps1
```

To run the baseline script directly:

```powershell
.\tweaks\baseline.ps1
```

Review scripts before running them on a machine you care about. This project is intended for fresh installs and rebuilds where quick workstation setup matters more than preserving the default Windows experience.
