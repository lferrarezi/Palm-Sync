#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/validate-version-policy.sh"

(
  cd "$ROOT_DIR/projects/palm-sync-macos"
  swift test --parallel
  swift build
  swift run palm-probe --json >/tmp/palm-sync-probe-check.json
)

echo "Release check OK"
