#!/usr/bin/env bash
# Syncs VPS OpenClaw state to local staging directory.
# Excludes credentials (injected from 1Password) and heavy media/browser dirs.
set -euo pipefail

STAGING_DIR="${HOME}/.openclaw-staging"
VPS="root@100.71.224.113"

if [ ! -d "$STAGING_DIR" ]; then
  echo "Creating staging directory at $STAGING_DIR"
  mkdir -p "$STAGING_DIR"/{workspace,credentials,agents,memory,media,sessions,logs}
fi

echo "Syncing VPS state to $STAGING_DIR ..."
rsync -avz \
  --exclude='credentials/' \
  --exclude='*.bak' \
  --exclude='media/' \
  --exclude='browser/' \
  --exclude='canvas/' \
  --exclude='completions/' \
  "$VPS:/root/.openclaw/" "$STAGING_DIR/"

echo "Done. Synced VPS state to $STAGING_DIR"
echo "Run apply-config.sh next to patch for staging."
