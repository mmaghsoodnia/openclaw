#!/usr/bin/env bash
# Rebuild the Docker image from local source and restart the gateway.
# Use this after making code changes to test them in staging.
# Does NOT resync from VPS — just rebuilds and restarts.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCKER="${DOCKER:-/usr/local/bin/docker}"

cd "$PROJECT_ROOT"

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
