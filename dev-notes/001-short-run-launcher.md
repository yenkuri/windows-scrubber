# 001 Short Run Launcher

## Summary

Added a root-level extensionless `run` PowerShell launcher so the GitHub Pages endpoint can support:

```powershell
irm https://windows.yenkuri.com/run | iex
```

`install.ps1` remains the main installer.

## Files Changed

- `run`
- `README.md`
- `dev-notes/001-short-run-launcher.md`

## Validation Performed

- Confirmed the repo root contains `run`.
- Confirmed `README.md` references `https://windows.yenkuri.com/run`.
- Confirmed `install.ps1` was not changed.
- Confirmed the extensionless `run` file is static PowerShell text that GitHub Pages should publish from the repo root and serve as downloadable script content.

## Risks/Notes

- `/run` intentionally duplicates no installer logic; it only delegates to `https://windows.yenkuri.com/install.ps1`.
- PowerShell should be run as Administrator for the installer to apply elevated Windows changes.
- GitHub Pages MIME type for an extensionless file may be generic, but `irm ... | iex` relies on the response body text.

## Next Suggested Step

After GitHub Pages publishes `main`, verify from a fresh elevated PowerShell session:

```powershell
irm https://windows.yenkuri.com/run | iex
```
