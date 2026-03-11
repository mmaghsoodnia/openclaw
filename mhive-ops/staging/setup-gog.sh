#!/usr/bin/env bash
# Reconstructs the gogcli config directory from 1Password for staging Docker.
#
# The staging container needs three things at /home/node/.config/gogcli/:
#   1. config.json           — static (keyring_backend: file)
#   2. credentials.json      — OAuth client_id + client_secret (from 1Password)
#   3. keyring/token:*       — encrypted OAuth refresh tokens (from 1Password, base64-encoded)
#
# All secrets come from 1Password vault "OpenClaw" via service account token.
# The keyring tokens are stored base64-encoded in the "GOG OAuth Tokens" item
# to avoid issues with colons in filenames.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOG_DIR="${HOME}/.openclaw-staging/gogcli"

# Load 1Password service account token (no Touch ID needed)
export OP_SERVICE_ACCOUNT_TOKEN=$(<~/.op-service-account-token)

echo "  Setting up gog credentials from 1Password..."

mkdir -p "$GOG_DIR/keyring"

# 1. Static config — not a secret
echo '{"keyring_backend": "file"}' > "$GOG_DIR/config.json"

# 2. OAuth client credentials from 1Password
#    Uses op read + printf instead of op inject to avoid newline injection in JSON values
printf '{"client_id":"%s","client_secret":"%s"}\n' \
  "$(op read 'op://OpenClaw/Google Workspace OAuth/client_id' --account my.1password.com | tr -d '\n\r')" \
  "$(op read 'op://OpenClaw/Google Workspace OAuth/client_secret' --account my.1password.com | tr -d '\n\r')" \
  > "$GOG_DIR/credentials.json"

# 3. Keyring tokens from 1Password (stored as base64)
op read "op://OpenClaw/GOG OAuth Tokens/default_token" --account my.1password.com \
  | base64 -d > "$GOG_DIR/keyring/token:default:mhive@bigbraincap.com"

op read "op://OpenClaw/GOG OAuth Tokens/account_token" --account my.1password.com \
  | base64 -d > "$GOG_DIR/keyring/token:mhive@bigbraincap.com"

# Lock down permissions
chmod 700 "$GOG_DIR" "$GOG_DIR/keyring"
chmod 600 "$GOG_DIR/config.json" "$GOG_DIR/credentials.json" "$GOG_DIR/keyring/"*

echo "  gog credentials ready at $GOG_DIR"
