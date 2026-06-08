#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
APP_VERSION_FILE="$ROOT_DIR/projects/palm-sync-macos/Sources/PalmSyncMac/Generated/AppVersionInfo.swift"

EXPECTED_VERSION="${1:-}"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: VERSION file not found" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

if [[ -n "$EXPECTED_VERSION" && "$VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "ERROR: VERSION is $VERSION, expected $EXPECTED_VERSION" >&2
  exit 1
fi

if [[ ! "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "ERROR: VERSION must be semver X.Y.Z, got $VERSION" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

if (( MINOR % 2 == 1 )); then
  RELEASE_KIND="prerelease"
else
  RELEASE_KIND="release"
fi

if ! rg -q "## $VERSION\b" "$CHANGELOG_FILE"; then
  echo "ERROR: CHANGELOG.md does not contain entry for $VERSION" >&2
  exit 1
fi

if ! rg -q "Release kind: $RELEASE_KIND\b" "$CHANGELOG_FILE"; then
  echo "ERROR: CHANGELOG.md does not declare Release kind: $RELEASE_KIND" >&2
  exit 1
fi

if ! rg -q "static let version = \"$VERSION\"" "$APP_VERSION_FILE"; then
  echo "ERROR: AppVersionInfo.swift version does not match $VERSION" >&2
  exit 1
fi

if ! rg -q "static let releaseKind = \"$RELEASE_KIND\"" "$APP_VERSION_FILE"; then
  echo "ERROR: AppVersionInfo.swift releaseKind does not match $RELEASE_KIND" >&2
  exit 1
fi

echo "version=$VERSION"
echo "major=$MAJOR"
echo "minor=$MINOR"
echo "patch=$PATCH"
echo "release_kind=$RELEASE_KIND"
echo "Version policy OK: $VERSION => $RELEASE_KIND lane"

