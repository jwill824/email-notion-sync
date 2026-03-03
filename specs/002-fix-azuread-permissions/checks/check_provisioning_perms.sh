#!/usr/bin/env bash
set -euo pipefail

# Basic pre-check for provisioning principal presence.
# - Exits non-zero if required env var is missing or if 'az' is available but the service principal is not found.

if [ -z "${PROVISIONING_PRINCIPAL_CLIENT_ID:-}" ]; then
  echo "ERROR: PROVISIONING_PRINCIPAL_CLIENT_ID environment variable is not set"
  exit 2
fi

if command -v az >/dev/null 2>&1; then
  if az ad sp show --id "$PROVISIONING_PRINCIPAL_CLIENT_ID" >/dev/null 2>&1; then
    echo "Provisioning principal exists in tenant"
  else
    echo "ERROR: provisioning principal with client id $PROVISIONING_PRINCIPAL_CLIENT_ID not found in tenant"
    exit 3
  fi
else
  echo "az CLI not available; PROVISIONING_PRINCIPAL_CLIENT_ID is set. Skipping tenant lookup."
fi

echo "OK: pre-check passed"
exit 0
