#!/usr/bin/env bash
# Patches the synced openclaw.json with staging-specific overrides.
# Reads bot tokens from 1Password via `op run`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAGING_DIR="${HOME}/.openclaw-staging"
CONFIG="$STAGING_DIR/openclaw.json"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: $CONFIG not found. Run sync-from-vps.sh first." >&2
  exit 1
fi

echo "Patching $CONFIG for staging..."

# Use op run to inject secrets as env vars, then call patch-config.py
op run --account my.1password.com \
  --env-file <(cat <<'OPENV'
STAGING_TELEGRAM_BOT_TOKEN=op://OpenClaw/Staging Telegram Bot/credential
STAGING_GATEWAY_TOKEN=op://OpenClaw/Staging Gateway Token/credential
OPENV
) -- python3 "$SCRIPT_DIR/patch-config.py" "$CONFIG"
