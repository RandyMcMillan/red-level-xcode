#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ICON="${SCRIPT_DIR}/assets/icon.png"

SWIFTYAPP_ICONSET="${SCRIPT_DIR}/swiftyapp/swiftyapp/Assets.xcassets/AppIcon.appiconset"
TRAYAPP_ICONSET="${SCRIPT_DIR}/trayapp/trayapp/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "${SRC_ICON}" ]]; then
  echo "Source icon not found: ${SRC_ICON}" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips not found on PATH" >&2
  exit 127
fi

render_icon() {
  local size="$1"
  local output="$2"

  mkdir -p "$(dirname "${output}")"
  sips -z "${size}" "${size}" "${SRC_ICON}" --out "${output}" >/dev/null
}

populate_swiftyapp() {
  render_icon 1024 "${SWIFTYAPP_ICONSET}/AppIcon-1024.png"
}

populate_trayapp() {
  render_icon 16 "${TRAYAPP_ICONSET}/appIcon-16.png"
  render_icon 32 "${TRAYAPP_ICONSET}/appIcon-32.png"
  render_icon 64 "${TRAYAPP_ICONSET}/appIcon-64.png"
  render_icon 128 "${TRAYAPP_ICONSET}/appIcon-128.png"
  render_icon 256 "${TRAYAPP_ICONSET}/appIcon-256.png"
  render_icon 512 "${TRAYAPP_ICONSET}/appIcon-512.png"
  render_icon 1024 "${TRAYAPP_ICONSET}/appIcon-1024.png"
}

populate_swiftyapp
populate_trayapp

echo "Icon sets populated from ${SRC_ICON}"
