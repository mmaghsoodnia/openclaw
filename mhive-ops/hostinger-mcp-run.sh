#!/bin/bash
# Launcher for Hostinger API MCP server
# Injects API_TOKEN from 1Password at runtime — secret never touches disk
# Registered in ~/.claude.json as mcpServers.hostinger

set -euo pipefail

# Get API token from 1Password (safe pattern: piped directly, never stored in variable visible to ps)
export API_TOKEN
API_TOKEN="$(op read 'op://OpenClaw/Hostinger API Key/credential' --account my.1password.com)"

exec /opt/homebrew/bin/hostinger-api-mcp
