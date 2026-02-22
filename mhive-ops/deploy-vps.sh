#!/bin/bash
# Deploy OpenClaw from GitHub fork to VPS.
# Usage: ./deploy-vps.sh [--skip-push] [--skip-build]
#
# Flow: push to GitHub → SSH to VPS → pull from fork → rebuild Docker → restart gateway
# Requires: SSH access to root@100.71.224.113 (Tailscale), gh CLI authenticated

set -euo pipefail

VPS_HOST="root@100.71.224.113"
VPS_PROJECT="/root/openclaw"
REMOTE="origin"
BRANCH="main"

SKIP_PUSH=false
SKIP_BUILD=false

for arg in "$@"; do
  case $arg in
    --skip-push) SKIP_PUSH=true ;;
    --skip-build) SKIP_BUILD=true ;;
    --help|-h)
      echo "Usage: $0 [--skip-push] [--skip-build]"
      echo "  --skip-push   Skip pushing to GitHub (VPS pulls whatever is on remote)"
      echo "  --skip-build  Skip Docker rebuild (just restart with existing image)"
      exit 0
      ;;
  esac
done

echo "=== OpenClaw VPS Deploy ==="

# Step 1: Push local changes to GitHub
if [ "$SKIP_PUSH" = false ]; then
  echo "→ Pushing to GitHub ($REMOTE/$BRANCH)..."
  git push "$REMOTE" "$BRANCH"
else
  echo "→ Skipping push (--skip-push)"
fi

# Step 2: Pull on VPS
echo "→ Pulling latest on VPS..."
ssh "$VPS_HOST" "cd $VPS_PROJECT && git fetch $REMOTE && git reset --hard $REMOTE/$BRANCH"

# Step 3: Rebuild Docker image
if [ "$SKIP_BUILD" = false ]; then
  echo "→ Rebuilding Docker image on VPS..."
  ssh "$VPS_HOST" "cd $VPS_PROJECT && docker build -t openclaw:local . 2>&1 | tail -5"
else
  echo "→ Skipping build (--skip-build)"
fi

# Step 4: Restart gateway
echo "→ Restarting gateway..."
ssh "$VPS_HOST" "cd $VPS_PROJECT && docker compose up -d openclaw-gateway 2>&1"

# Step 5: Wait and verify
echo "→ Waiting for startup..."
sleep 15

echo "→ Checking gateway status..."
ssh "$VPS_HOST" "docker logs --tail 10 openclaw-openclaw-gateway-1 2>&1"

echo ""
echo "=== Deploy complete ==="
