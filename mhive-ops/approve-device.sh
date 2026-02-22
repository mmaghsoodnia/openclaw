#!/bin/bash
# Approve pending OpenClaw device pairing requests on VPS.
# Generates proper device tokens so browsers don't need to re-pair after approval.
ssh root@100.71.224.113 "python3 << 'PYEOF'
import json, time, secrets, os

paired_path = '/root/.openclaw/devices/paired.json'
pending_path = '/root/.openclaw/devices/pending.json'

with open(pending_path) as f:
    pending = json.load(f)

if not pending:
    print('No pending devices.')
    exit(0)

with open(paired_path) as f:
    paired = json.load(f)

# paired.json is keyed by deviceId
paired_by_device = {v['deviceId']: v for v in paired.values() if isinstance(v, dict) and 'deviceId' in v}

now = int(time.time() * 1000)
approved = 0

for rid, d in pending.items():
    device_id = d.get('deviceId')
    role = d.get('role', 'operator')
    scopes = d.get('scopes', ['operator.admin', 'operator.approvals', 'operator.pairing'])

    # Merge with existing paired entry if any (same device, new keypair)
    existing = paired_by_device.get(device_id, {})
    tokens = existing.get('tokens', {})

    # Generate a new token for this role (mirrors approveDevicePairing in device-pairing.ts)
    tokens[role] = {
        'token': secrets.token_hex(16),
        'role': role,
        'scopes': scopes,
        'createdAtMs': existing.get('tokens', {}).get(role, {}).get('createdAtMs', now),
        'rotatedAtMs': now if role in existing.get('tokens', {}) else None,
        'revokedAtMs': None,
        'lastUsedAtMs': existing.get('tokens', {}).get(role, {}).get('lastUsedAtMs'),
    }

    entry = {
        'deviceId': device_id,
        'publicKey': d.get('publicKey'),
        'displayName': d.get('displayName'),
        'platform': d.get('platform'),
        'clientId': d.get('clientId'),
        'clientMode': d.get('clientMode'),
        'role': role,
        'roles': d.get('roles', [role]),
        'scopes': scopes,
        'remoteIp': d.get('remoteIp'),
        'tokens': tokens,
        'createdAtMs': existing.get('createdAtMs', now),
        'approvedAtMs': now,
    }

    # Key by deviceId to avoid duplicates from multiple pending requests per device
    paired[device_id] = entry
    print(f'Approved: {rid[:8]} | {d.get(\"remoteIp\",\"?\")} | token issued')
    approved += 1

with open(paired_path, 'w') as f:
    json.dump(paired, f, indent=2)
with open(pending_path, 'w') as f:
    json.dump({}, f)

print(f'Done. Approved {approved} device(s). Total paired: {len(paired)}')
PYEOF"
