# 005 Cleanup Returns Main Menu

## Summary

Changed the full cleanup / scrubber flow so it returns to the starting Windows Scrubber menu after completing the summary.

The cleanup flow no longer drops into the older optional modules menu automatically.

## Files Changed

- `tweaks/baseline.ps1`
- `dev-notes/005-cleanup-returns-main-menu.md`

## Validation Performed

- Confirmed `Invoke-FullCleanup` no longer calls `Invoke-OptionalModulesMenu`.
- Confirmed main menu option 1 calls `Invoke-FullCleanup` without returning from `Show-MainMenu`.
- Confirmed `tweaks/baseline.ps1` parses successfully.
- Confirmed the main menu still renders the expected starting options.

## Risks/Notes

- The old optional modules menu remains in `modules/optional.ps1` for compatibility, but it is no longer reached automatically after cleanup.
- Main menu items now own the utility flows directly, including Remote Desktop, automatic local sign-in, and no-sleep power plan.

## Next Suggested Step

Run the cleanup flow from an elevated session and confirm it returns to the starting menu after the summary:

```powershell
irm https://git.yenkuri.com | iex
```
