# Quickstart: Verifying provisioning permissions and running Terraform

This document explains how to verify the provisioning identity's permissions and validate the Terraform configuration before triggering an apply via HCP.

## Prerequisites

- Azure CLI (`az`) installed and authenticated as a user with at least **Directory.Read.All** Graph delegated permission (or a tenant admin).
- Access to the HCP Terraform workspace `email-notion-sync-azure` in the `Thingstead` organization.
- The `PROVISIONING_PRINCIPAL_CLIENT_ID` (client ID of the HCP service principal) — ask the workspace owner or retrieve from HCP workspace variables.

## 1. Verify the pre-check locally

```bash
export PROVISIONING_PRINCIPAL_CLIENT_ID=<hcp-sp-client-id>
bash specs/002-fix-azuread-permissions/checks/check_provisioning_perms.sh
```

Expected output on success:
```
Checking provisioning principal: <id>
  ✓ Service principal found (objectId: ...)
Checking for role membership: 'Application Administrator'
  ✓ Role found (id: ...)
  ✓ Role membership confirmed
OK: all pre-checks passed — provisioning identity is ready for terraform apply
```

Exit codes:
| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 2 | `PROVISIONING_PRINCIPAL_CLIENT_ID` not set |
| 3 | Service principal not found in tenant |
| 4 | Could not resolve role ID (role not activated or insufficient caller perms) |
| 5 | SP does not hold the Application Administrator role |

## 2. Run terraform plan

The HCP workspace uses VCS-driven workflow. Trigger a plan by pushing to the connected branch, or use the HCP UI:

1. Open [https://app.terraform.io/app/Thingstead/email-notion-sync-azure](https://app.terraform.io/app/Thingstead/email-notion-sync-azure).
2. Click **+ New run** → **Plan only**.
3. Review the plan output. The plan should show no errors for `azuread_application_federated_identity_credential.github_actions_credential`.

## 3. Verify resources after apply

After a successful apply, confirm:

```bash
# Azure AD Application exists
az ad app show --id <oidc_client_id from Terraform output>

# Service principal exists
az ad sp show --id <oidc_client_id>

# Federated credential exists
az ad app federated-credential list --id <oidc_client_id>
```

## 4. HCP workspace name

| Workspace | Organization | Branch |
|-----------|--------------|--------|
| `email-notion-sync-azure` | `Thingstead` | `main` (VCS-connected) |

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|-----------|
| `403 Authorization_RequestDenied` on `azuread_application` | HCP SP lacks Application Administrator role | Follow `admin-approval.md` |
| `parsing the Application ID: the number of segments didn't match` | `application_id` used `.client_id` instead of `.id` | Ensure commit with T000 fix is merged |
| Drift on container app resources | Image tag updated by deploy workflow outside Terraform | Expected; review plan diff and accept or reconcile |
