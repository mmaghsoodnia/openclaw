#!/usr/bin/env bash
# Rebuild the Docker image from local source and restart the gateway.
# Use this after making code changes to test them in staging.
# Does NOT resync from VPS — just rebuilds and restarts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STAGING_DIR="${HOME}/.openclaw-staging"
DOCKER="${DOCKER:-/usr/local/bin/docker}"

cd "$PROJECT_ROOT"

# Re-inject .env.staging so keys are always fresh
echo "Regenerating .env.staging..."
OP_SERVICE_ACCOUNT_TOKEN=$(<~/.op-service-account-token) \
  op inject -f --account my.1password.com \
  -i "$SCRIPT_DIR/.env.staging.tpl" \
  -o "$PROJECT_ROOT/.env.staging"
cat >> "$PROJECT_ROOT/.env.staging" <<EOF
OPENCLAW_CONFIG_DIR=${STAGING_DIR}
OPENCLAW_WORKSPACE_DIR=${STAGING_DIR}/workspace
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
GOG_ACCOUNT=mhive@bigbraincap.com
EOF
chmod 600 "$PROJECT_ROOT/.env.staging"

echo "Rebuilding Docker image from local source..."
"$DOCKER" build -t openclaw:local "$PROJECT_ROOT"

echo "Restarting gateway..."
"$DOCKER" compose \
  --env-file "$PROJECT_ROOT/.env.staging" \
  -f "$PROJECT_ROOT/docker-compose.yml" \
  -f "$PROJECT_ROOT/docker-compose.staging.yml" \
  up -d --force-recreate openclaw-gateway

sleep 5
if curl -sf http://localhost:18789/health > /dev/null 2>&1; then
  echo "Gateway healthy after rebuild!"
else
  echo "Gateway not ready yet. Check logs:"
  echo "  $DOCKER compose -f docker-compose.yml -f docker-compose.staging.yml logs -f openclaw-gateway"
fi
