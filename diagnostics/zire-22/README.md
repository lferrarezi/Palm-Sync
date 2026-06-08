# Palm Sync Diagnostics: Zire 22

Run from `projects/palm-sync-macos`.

```bash
swift run palm-probe capture --json --output ../../diagnostics/zire-22/before.json
# connect Zire 22 and press HotSync
swift run palm-probe capture --json --output ../../diagnostics/zire-22/after.json
swift run palm-probe compare ../../diagnostics/zire-22/before.json ../../diagnostics/zire-22/after.json --json --output ../../diagnostics/zire-22/comparison.json
```

Expected evidence:

- New `/dev/cu.*` entry, if macOS exposes the Palm as serial.
- New USB hint, if macOS exposes the device in `system_profiler`.
- Empty comparison means no Palm signal was visible during that capture window.

