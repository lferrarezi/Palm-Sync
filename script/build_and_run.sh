#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="PalmSyncMac"
BUNDLE_NAME="Palm Sync"
BUNDLE_ID="com.lferrarezi.PalmIsAlive.PalmSyncMac"
MIN_SYSTEM_VERSION="15.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/projects/palm-sync-macos"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
INSTALL_DIR="$HOME/Applications/Palm Sync"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$BUNDLE_NAME.app"
INSTALLED_APP="$INSTALL_DIR/$BUNDLE_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

kill_existing() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_bundle() {
  (
    cd "$PROJECT_DIR"
    swift build --product "$APP_NAME"
  )

  BUILD_BINARY="$(cd "$PROJECT_DIR" && swift build --show-bin-path)/$APP_NAME"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS"
  cp "$BUILD_BINARY" "$APP_BINARY"
  chmod +x "$APP_BINARY"

  /usr/bin/plutil -create xml1 "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleExecutable -string "$APP_NAME" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleName -string "$BUNDLE_NAME" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleDisplayName -string "$BUNDLE_NAME" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleShortVersionString -string "$VERSION" "$INFO_PLIST"
  /usr/bin/plutil -insert CFBundleVersion -string "1" "$INFO_PLIST"
  /usr/bin/plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
  /usr/bin/plutil -insert LSApplicationCategoryType -string "public.app-category.productivity" "$INFO_PLIST"
  /usr/bin/plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"

  mkdir -p "$INSTALL_DIR"
  rm -rf "$INSTALLED_APP"
  cp -R "$APP_BUNDLE" "$INSTALLED_APP"
}

open_app() {
  /usr/bin/open -n "$INSTALLED_APP"
}

kill_existing
build_bundle

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$INSTALLED_APP/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "Installed: $INSTALLED_APP"
    echo "Process verified: $APP_NAME"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
