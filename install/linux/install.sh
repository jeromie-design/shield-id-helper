#!/usr/bin/env bash
# Shield Identity Helper installer (Linux).
#
# Drops the binary under /opt/cinderlabs and writes the Chrome native-messaging
# manifest to the system-wide locations for Chrome and Chromium so all users on
# the box can use it.
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
    echo "Run as root (sudo)." >&2
    exit 1
fi

SRC_BIN="$(dirname "$0")/shield-id-helper"
if [[ ! -f "$SRC_BIN" ]]; then
    echo "Helper binary not found: $SRC_BIN" >&2
    echo "Run build.ps1 and copy dist/linux-amd64/shield-id-helper next to this script." >&2
    exit 1
fi

INSTALL_DIR="/opt/cinderlabs/shield-id-helper"
BIN_PATH="$INSTALL_DIR/shield-id-helper"
mkdir -p "$INSTALL_DIR"
install -m 0755 "$SRC_BIN" "$BIN_PATH"

# System-wide native-messaging-host paths. Chrome and Chromium use different
# directories; install to both so either browser picks up the helper.
TARGETS=(
    "/etc/opt/chrome/native-messaging-hosts"
    "/etc/chromium/native-messaging-hosts"
    "/etc/opt/edge/native-messaging-hosts"
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
echo "Restart Chrome/Chromium for the extension to pick up the helper."
