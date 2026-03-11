#!/usr/bin/env bash
# One-command startup for the local staging environment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STAGING_DIR="${HOME}/.openclaw-staging"
DOCKER="${DOCKER:-/usr/local/bin/docker}"

cd "$PROJECT_ROOT"

echo "=== OpenClaw Staging Environment ==="
echo ""

# 1. Sync agent workspace from VPS (latest memory, soul, sessions)
echo "[1/8] Syncing agent workspace from VPS..."
if bash "$SCRIPT_DIR/sync-workspace.sh"; then
  echo "  Workspace synced."
else
  echo "  WARNING: VPS unreachable — using existing workspace files."
  if [ ! -d "$STAGING_DIR/workspace" ]; then
    echo "  ERROR: No staging workspace exists. Run sync-from-vps.sh first."
    exit 1
  fi
fi

# 2. Generate .env.staging (secrets from 1Password + paths from shell)
echo "[2/8] Generating .env.staging..."
OP_SERVICE_ACCOUNT_TOKEN=$(<~/.op-service-account-token) \
  op inject -f --account my.1password.com \
  -i "$SCRIPT_DIR/.env.staging.tpl" \
  -o "$PROJECT_ROOT/.env.staging"
# Append non-secret env vars (paths, bind address)
cat >> "$PROJECT_ROOT/.env.staging" <<EOF
OPENCLAW_CONFIG_DIR=${STAGING_DIR}
OPENCLAW_WORKSPACE_DIR=${STAGING_DIR}/workspace
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
GOG_ACCOUNT=mhive@bigbraincap.com
EOF
chmod 600 "$PROJECT_ROOT/.env.staging"

# 3. Reconstruct gog credentials from 1Password
echo "[3/8] Setting up gog credentials..."
bash "$SCRIPT_DIR/setup-gog.sh"

# 4. Apply staging config patches
echo "[4/8] Patching openclaw.json for staging..."
bash "$SCRIPT_DIR/apply-config.sh"

# 5. Build Docker image from local source
echo "[5/8] Building Docker image..."
"$DOCKER" build -t openclaw:local "$PROJECT_ROOT"

# 6. Start services
echo "[6/8] Starting containers..."
"$DOCKER" compose \
  --env-file "$PROJECT_ROOT/.env.staging" \
  -f "$PROJECT_ROOT/docker-compose.yml" \
  -f "$PROJECT_ROOT/docker-compose.staging.yml" \
  up -d

# 7. Health check
echo "[7/8] Checking gateway health..."
sleep 5
if curl -sf http://localhost:18789/health > /dev/null 2>&1; then
  echo "Gateway healthy!"
else
  echo "Gateway not ready yet. Check logs:"
  echo "  $DOCKER compose -f docker-compose.yml -f docker-compose.staging.yml logs -f openclaw-gateway"
fi

echo ""
echo "=== Staging is running ==="
echo "  Gateway: http://localhost:18789"
echo "  Stop:    bash $SCRIPT_DIR/stop.sh"
echo "  Rebuild: bash $SCRIPT_DIR/rebuild.sh"
echo "  Sync:    bash $SCRIPT_DIR/sync.sh"
