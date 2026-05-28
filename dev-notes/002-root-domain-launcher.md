# 002 Root Domain Launcher

## Summary

Added a root-level `index.html` launcher so the GitHub Pages root domain can support:

```powershell
irm https://git.yenkuri.com | iex
```

Despite the `.html` extension, `index.html` contains plain PowerShell only. `install.ps1` remains the real installer, and `run` remains as a compatibility alias.

## Files Changed

- `index.html`
- `run`
- `README.md`
- `dev-notes/002-root-domain-launcher.md`

## Validation Performed

- Confirmed the repo root contains `index.html` with plain PowerShell only.
- Confirmed the repo root contains `run` with plain PowerShell only.
- Confirmed both `index.html` and `run` point to `https://git.yenkuri.com/install.ps1`.
- Confirmed `install.ps1` was not changed.
- Confirmed `README.md` references the new root command, compatibility alias, and explicit installer command.
- Confirmed GitHub Pages should serve `https://git.yenkuri.com` from root `index.html` as the launcher response body.

## Risks/Notes

- `index.html` intentionally contains no HTML; this is deliberate so `irm https://git.yenkuri.com | iex` evaluates PowerShell directly.
- GitHub Pages may serve `index.html` with an HTML content type, but `irm ... | iex` relies on the response body text.
- PowerShell should be run as Administrator for the installer to apply elevated Windows changes.

## Next Suggested Step

After GitHub Pages publishes `main`, verify from a fresh elevated PowerShell session:

```powershell
irm https://git.yenkuri.com | iex
```
