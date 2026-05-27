#!/usr/bin/env bash
# Shield Identity Helper installer (macOS).
#
# Drops the binary under /Library/Application Support/CinderLabs and registers
# the Chrome native-messaging manifest system-wide (covers all users on the box).
#
# Usage:
#   sudo ./install.sh <extension-id>

set -euo pipefail

if [[ "${1:-}" == "" ]]; then
    echo "Usage: sudo $0 <extension-id>" >&2
    exit 2
fi
EXT_ID="$1"

if [[ $EUID -ne 0 ]]; then
    echo "This installer must run as root (sudo)." >&2
    exit 1
fi

# Each release ships per-arch zip bundles, so the binary next to this script
# already matches the OS arch — no runtime arch dispatch needed.
SRC_BIN="$(dirname "$0")/shield-id-helper"
if [[ ! -f "$SRC_BIN" ]]; then
    echo "Helper binary not found: $SRC_BIN" >&2
    echo "Download the shield-id-helper-darwin-<arch>.zip release asset and run from the extracted folder." >&2
    exit 1
fi

INSTALL_DIR="/Library/Application Support/CinderLabs/shield-id-helper"
BIN_PATH="$INSTALL_DIR/shield-id-helper"
mkdir -p "$INSTALL_DIR"
install -m 0755 "$SRC_BIN" "$BIN_PATH"

# Register with Chrome (system-wide path). Chromium / Brave / Edge have their
# own dirs; add as needed.
TARGETS=(
    "/Library/Google/Chrome/NativeMessagingHosts"
    "/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
)
for dir in "${TARGETS[@]}"; do
    mkdir -p "$dir"
    cat > "$dir/ai.cinderlabs.shield_identity.json" <<EOF
{
  "name": "ai.cinderlabs.shield_identity",
  "description": "Shield endpoint identity helper",
  "path": "$BIN_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXT_ID/"]
}
EOF
done

echo "Installed shield-id-helper to $BIN_PATH"
echo "Registered native-messaging host for extension $EXT_ID"
echo "Restart Chrome/Edge for the extension to pick up the helper."
