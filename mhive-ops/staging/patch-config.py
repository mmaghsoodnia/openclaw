#!/usr/bin/env python3
"""
Patches a synced openclaw.json for local staging use.

Expected env vars (injected by `op run`):
  STAGING_TELEGRAM_BOT_TOKEN  — bot token for staging Telegram bot
  STAGING_GATEWAY_TOKEN       — gateway auth token (optional override)

Usage:
  op run --account my.1password.com -- python3 patch-config.py ~/.openclaw-staging/openclaw.json
"""
import json
import os
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: patch-config.py <path-to-openclaw.json>", file=sys.stderr)
        sys.exit(1)

    config_path = sys.argv[1]

    # Read env vars
    staging_bot_token = os.environ.get("STAGING_TELEGRAM_BOT_TOKEN", "")
    staging_gw_token = os.environ.get("STAGING_GATEWAY_TOKEN", "")

    if not staging_bot_token:
        print("WARNING: STAGING_TELEGRAM_BOT_TOKEN not set — Telegram will not work", file=sys.stderr)

    # Load config
    with open(config_path, "r") as f:
        cfg = json.load(f)

    # --- Telegram: replace all accounts with one staging account ---
    telegram = cfg.setdefault("channels", {}).setdefault("telegram", {})
    telegram["enabled"] = True

    # Keep the same dmPolicy and allowFrom as production mhive
    prod_mhive = telegram.get("accounts", {}).get("mhive", {})
    allow_from = prod_mhive.get("allowFrom", ["217834570"])

    telegram["accounts"] = {
        "staging": {
            "dmPolicy": "allowlist",
            "botToken": staging_bot_token,
            "allowFrom": allow_from,
            "groupPolicy": "disabled",
        }
    }

    # --- Bindings: single binding for staging ---
    cfg["bindings"] = [
        {
            "agentId": "main",
            "match": {
                "channel": "telegram",
                "accountId": "staging",
            }
        }
    ]

    # --- WhatsApp: disabled ---
    cfg.setdefault("channels", {})["whatsapp"] = {
        "dmPolicy": "disabled",
        "groupPolicy": "disabled",
    }
    plugins = cfg.setdefault("plugins", {}).setdefault("entries", {})
    plugins["whatsapp"] = {"enabled": False}
    plugins["telegram"] = {"enabled": True}

    # --- Gateway ---
    gateway = cfg.setdefault("gateway", {})
    # Remove gateway.bind from config — handled by CLI --bind flag via env var.
    # Older image versions don't have this field in the config schema.
    gateway.pop("bind", None)

    # Override gateway auth token if provided
    if staging_gw_token:
        gateway.setdefault("auth", {})["token"] = staging_gw_token

    # Write patched config
    with open(config_path, "w") as f:
        json.dump(cfg, f, indent=2)

    print(f"OK: Patched {config_path} for staging")
    print(f"  - Telegram: 1 account (staging), allowFrom={allow_from}")
    print(f"  - WhatsApp: disabled")
    print(f"  - Gateway bind: via CLI --bind flag (OPENCLAW_GATEWAY_BIND env var)")
    if staging_gw_token:
        print(f"  - Gateway token: overridden from env")

if __name__ == "__main__":
    main()
