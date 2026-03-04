# PR: Fix AzureAD Terraform provisioning errors (002-fix-azuread-permissions)

## Summary

Fixes two issues blocking the HCP Terraform workspace from successfully applying the Azure infrastructure configuration:

1. **Terraform code bug (blocking)** — `azuread_application_federated_identity_credential.github_actions_credential` referenced `azuread_application.github_oidc_app.client_id` (a bare GUID) instead of `.id` (the OData path `/applications/{objectId}` required by the provider). This caused a plan-time parsing error.

2. **Permission documentation** — Adds a pre-check script, GitHub Actions workflow, runbook, and security notes to help operators verify and remediate permission issues for the HCP provisioning identity.

## Changes

| File | Change |
|------|--------|
| `EmailNotionSync.Terraform/azure/main.tf` | Fix: `.client_id` → `.id` on `azuread_application_federated_identity_credential` |
| `EmailNotionSync.Terraform/azure/variables.tf` | Add required CI secrets/variables documentation |
| `.github/workflows/terraform-precheck.yml` | New: pre-check workflow that validates provisioning identity permissions before HCP apply |
| `.gitignore` | Add .NET, Terraform, and common ignore patterns |
| `.terraformignore` | New: exclude .NET build artifacts from HCP upload context |
| `specs/002-fix-azuread-permissions/checks/check_provisioning_perms.sh` | Enhanced: adds role membership check with actionable error messages |
| `specs/002-fix-azuread-permissions/quickstart.md` | New: verification steps and HCP workspace info |
| `specs/002-fix-azuread-permissions/runbook.md` | New: remediation steps for both failure modes + permission removal |
| `specs/002-fix-azuread-permissions/security.md` | New: permission scope, approval matrix, audit trail |
| `specs/002-fix-azuread-permissions/outputs/drift-analysis.md` | New: drift classification for 8 drifted resources |
| `specs/002-fix-azuread-permissions/outputs/plan_staging.txt` | New: captured terraform plan output (exit 0, no errors) |
| `README.md` | Add infra section with link to runbook |

## Verification

`terraform plan` was run against the HCP workspace after the `main.tf` fix and produced:

- ✅ No errors
- ✅ `azuread_application_federated_identity_credential` shows correct `application_id = "/applications/600f9303-d545-4c7c-a03f-d538055423ee"`
- ✅ Plan: 6 to add, 0 to change, 0 to destroy

Full plan output: `specs/002-fix-azuread-permissions/outputs/plan_staging.txt`

## Pending (require human action)

- [ ] **T008** — Tenant admin must assign the **Application Administrator** role to the HCP provisioning SP before `terraform apply` will succeed. See `specs/002-fix-azuread-permissions/admin-approval.md`.
- [ ] **T010** — Trigger `terraform apply` in the HCP workspace after T008 is complete.
- [ ] **T011** — Verify created resources and record in `outputs/verify_staging.md`.
- [ ] **T012** — Run pipeline 3× to confirm stability and document in `outputs/pipeline_runs.md`.
- [ ] **T020** — Remove Application Administrator role from HCP SP once resources are confirmed stable (see `runbook.md#removing-temporary-elevated-permissions`).

## Reviewer checklist

- [ ] `main.tf` line 91: confirms `application_id = azuread_application.github_oidc_app.id` (not `.client_id`)
- [ ] Pre-check script exits non-zero for missing role (check exit codes 2–5 in the script)
- [ ] `terraform-precheck.yml` uses OIDC login (no stored credentials)
- [ ] `.terraformignore` does not accidentally exclude Terraform source files
- [ ] `.gitignore` does not accidentally ignore `terraform.tfvars` that should be committed (it should not be committed if it contains secrets — confirm current state)
- [ ] Security review: Application Administrator role scope is understood and approved by tenant admin
- [ ] Link to tenant admin approval ticket/record: ___________
