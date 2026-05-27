#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root (sudo)." >&2
    exit 1
fi

rm -f \
    "/Library/Google/Chrome/NativeMessagingHosts/ai.cinderlabs.shield_identity.json" \
    "/Library/Application Support/Microsoft Edge/NativeMessagingHosts/ai.cinderlabs.shield_identity.json"
rm -rf "/Library/Application Support/CinderLabs/shield-id-helper"

echo "Uninstalled shield-id-helper."
