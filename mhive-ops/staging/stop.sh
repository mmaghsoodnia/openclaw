#!/usr/bin/env bash
# Clean shutdown of the staging environment.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCKER="${DOCKER:-/usr/local/bin/docker}"

cd "$PROJECT_ROOT"

echo "Stopping staging containers..."
"$DOCKER" compose \
  -f "$PROJECT_ROOT/docker-compose.yml" \
  -f "$PROJECT_ROOT/docker-compose.staging.yml" \
  down

echo "Staging stopped."
