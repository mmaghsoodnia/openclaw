#!/usr/bin/env bash
# Syncs agent workspace from VPS to staging.
#
# Workflow:
#   1. SSH to VPS → run backup-workspace.sh (creates tar excluding venvs/node_modules)
#   2. SCP the tar to local machine
#   3. Extract into ~/.openclaw-staging/workspace/
#
# This ensures staging agents have the latest memory, soul, and session data.
# Run this before starting any task that involves staging.
set -euo pipefail

VPS="root@100.71.224.113"
VPS_BACKUP="/root/.openclaw/workspace-backup.tar.gz"
STAGING_DIR="${HOME}/.openclaw-staging"
LOCAL_TAR="/tmp/workspace-backup.tar.gz"

echo "  [1/3] Creating workspace backup on VPS..."
ssh -o ConnectTimeout=10 "$VPS" "bash /root/openclaw/mhive-ops/backup-workspace.sh"

echo "  [2/3] Downloading backup..."
scp -o ConnectTimeout=10 "$VPS:$VPS_BACKUP" "$LOCAL_TAR"

echo "  [3/3] Extracting to staging workspace..."
mkdir -p "$STAGING_DIR"
tar xzf "$LOCAL_TAR" -C "$STAGING_DIR"
rm -f "$LOCAL_TAR"

echo "  Workspace synced to $STAGING_DIR/workspace/"
