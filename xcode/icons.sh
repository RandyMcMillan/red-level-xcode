#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ICON="${SCRIPT_DIR}/assets/icon.png"
ROOT_ICONSET="${SCRIPT_DIR}/Assets.xcassets/AppIcon.appiconset"
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

reset_iconset() {
  local iconset="$1"
  mkdir -p "${iconset}"
  find "${iconset}" -maxdepth 1 -type f -name '*.png' -delete
}

generate_icons() {
  local iconset="$1"
  shift

  reset_iconset "${iconset}"
  while (($#)); do
    local filename="$1"
    local pixels="$2"
    render_icon "${pixels}" "${iconset}/${filename}"
    shift 2
  done
}

populate_root_iconset() {
  generate_icons "${ROOT_ICONSET}" \
    appIcon-20.png 20 \
    appIcon-20@2x.png 40 \
    appIcon-20@3x.png 60 \
    appIcon-29.png 29 \
    appIcon-29@2x.png 58 \
    appIcon-29@3x.png 87 \
    appIcon-40.png 40 \
    appIcon-40@2x.png 80 \
    appIcon-40@3x.png 120 \
    appIcon-60@2x.png 120 \
    appIcon-60@3x.png 180 \
    appIcon-76.png 76 \
    appIcon-76@2x.png 152 \
    appIcon-83_5@2x.png 167 \
    appIcon-16.png 16 \
    appIcon-32.png 32 \
    appIcon-64.png 64 \
    appIcon-128.png 128 \
    appIcon-256.png 256 \
    appIcon-512.png 512 \
    appIcon-1024.png 1024
}

copy_root_iconset() {
  local destination="$1"
  rm -rf "${destination}"
  mkdir -p "$(dirname "${destination}")"
  cp -R "${ROOT_ICONSET}" "${destination}"
}

populate_root_iconset
copy_root_iconset "${SWIFTYAPP_ICONSET}"
copy_root_iconset "${TRAYAPP_ICONSET}"

echo "Icon sets populated from ${SRC_ICON}"
