#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root (sudo)." >&2
    exit 1
fi

rm -f \
    "/etc/opt/chrome/native-messaging-hosts/ai.cinderlabs.shield_identity.json" \
    "/etc/chromium/native-messaging-hosts/ai.cinderlabs.shield_identity.json" \
    "/etc/opt/edge/native-messaging-hosts/ai.cinderlabs.shield_identity.json"
rm -rf "/opt/cinderlabs/shield-id-helper"

echo "Uninstalled shield-id-helper."
