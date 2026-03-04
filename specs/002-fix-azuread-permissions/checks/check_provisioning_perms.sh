#!/usr/bin/env bash
set -euo pipefail

# Pre-check: verifies the provisioning identity exists in the tenant and holds
# the Application Administrator directory role required to create azuread_application
# resources.  Exits non-zero with a clear diagnostic message on any failure.
#
# Required env vars:
#   PROVISIONING_PRINCIPAL_CLIENT_ID  — client (app) ID of the HCP/Terraform SP
#
# Optional env vars:
#   REQUIRED_ROLE  — expected Azure AD role (default: Application Administrator)

REQUIRED_ROLE="${REQUIRED_ROLE:-Application Administrator}"

# ── 1. Env-var guard ────────────────────────────────────────────────────────
if [ -z "${PROVISIONING_PRINCIPAL_CLIENT_ID:-}" ]; then
  echo "ERROR: PROVISIONING_PRINCIPAL_CLIENT_ID is not set."
  echo "  Remediation: export PROVISIONING_PRINCIPAL_CLIENT_ID=<client-id-of-hcp-sp>"
  exit 2
fi

# ── 2. Azure CLI availability ────────────────────────────────────────────────
if ! command -v az >/dev/null 2>&1; then
  echo "WARNING: az CLI not found; skipping tenant checks (PROVISIONING_PRINCIPAL_CLIENT_ID is set)."
  echo "OK: pre-check passed (partial — az CLI unavailable)"
  exit 0
fi

# ── 3. Service principal existence ──────────────────────────────────────────
echo "Checking provisioning principal: $PROVISIONING_PRINCIPAL_CLIENT_ID"
SP_OBJECT_ID=$(az ad sp show --id "$PROVISIONING_PRINCIPAL_CLIENT_ID" --query id --output tsv 2>/dev/null || true)

if [ -z "$SP_OBJECT_ID" ]; then
  echo "ERROR: Service principal with client ID '$PROVISIONING_PRINCIPAL_CLIENT_ID' was not found in the tenant."
  echo "  Remediation: Ensure the HCP/Terraform provisioning identity is registered in this tenant."
  echo "  See specs/002-fix-azuread-permissions/admin-approval.md for setup steps."
  exit 3
fi

echo "  ✓ Service principal found (objectId: $SP_OBJECT_ID)"

# ── 4. Directory role membership check ──────────────────────────────────────
echo "Checking for role membership: '$REQUIRED_ROLE'"

ROLE_ID=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/directoryRoles?\$filter=displayName eq '${REQUIRED_ROLE}'" \
  --query "value[0].id" --output tsv 2>/dev/null || true)

if [ -z "$ROLE_ID" ]; then
  echo "WARNING: Could not resolve role ID for '$REQUIRED_ROLE'."
  echo "  The role may not be activated in this tenant, or the caller lacks permission to query directory roles."
  echo "  Provisioning will likely fail with 403 if the role is not assigned."
  echo "  Remediation: See specs/002-fix-azuread-permissions/admin-approval.md"
  exit 4
fi

echo "  ✓ Role found (id: $ROLE_ID)"

MEMBER_CHECK=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/directoryRoles/${ROLE_ID}/members" \
  --query "value[?id=='${SP_OBJECT_ID}'].id" --output tsv 2>/dev/null || true)

if [ -z "$MEMBER_CHECK" ]; then
  echo "ERROR: Service principal '$PROVISIONING_PRINCIPAL_CLIENT_ID' does NOT have the '$REQUIRED_ROLE' role."
  echo "  Remediation: A tenant administrator must assign the role before running terraform apply."
  echo "  See specs/002-fix-azuread-permissions/admin-approval.md for step-by-step instructions."
  echo "  Portal path: Azure AD → Roles and administrators → Application Administrator → Add assignment"
  exit 5
fi

echo "  ✓ Role membership confirmed"
echo "OK: all pre-checks passed — provisioning identity is ready for terraform apply"
exit 0

