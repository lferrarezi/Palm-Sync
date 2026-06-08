#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/validate-version-policy.sh"

(
  cd "$ROOT_DIR/projects/palm-sync-macos"
  swift build
  swift run palm-probe >/tmp/palmisalive-palm-probe-check.log
)

echo "Release check OK"

