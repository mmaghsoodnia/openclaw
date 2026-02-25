#!/usr/bin/env bash
# Pull latest VPS state, patch config, and restart gateway.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER="${DOCKER:-/usr/local/bin/docker}"

echo "Syncing from VPS..."
bash "$SCRIPT_DIR/sync-from-vps.sh"

echo "Applying staging config..."
bash "$SCRIPT_DIR/apply-config.sh"

echo "Restarting gateway..."
"$DOCKER" compose \
  --env-file "$PROJECT_ROOT/.env.staging" \
  -f "$PROJECT_ROOT/docker-compose.yml" \
  -f "$PROJECT_ROOT/docker-compose.staging.yml" \
  restart openclaw-gateway

sleep 5
if curl -sf http://localhost:18789/health > /dev/null 2>&1; then
  echo "Gateway healthy after sync!"
else
  echo "Gateway not ready yet."
fi
