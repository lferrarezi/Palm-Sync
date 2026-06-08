# Palm Sync Diagnostics: LifeDrive

Run from `projects/palm-sync-macos`.

```bash
swift run palm-probe capture --json --output ../../diagnostics/lifedrive/before.json
# connect LifeDrive and press HotSync
swift run palm-probe capture --json --output ../../diagnostics/lifedrive/after.json
swift run palm-probe compare ../../diagnostics/lifedrive/before.json ../../diagnostics/lifedrive/after.json --json --output ../../diagnostics/lifedrive/comparison.json
```

Expected evidence:

- New `/dev/cu.*` entry, if macOS exposes the Palm as serial.
- New USB hint, if macOS exposes the device in `system_profiler`.
- Empty comparison means no Palm signal was visible during that capture window.

