# Drift Analysis — 2026-03-03 plan run

Eight resources reported drift during the `terraform plan` run on 2026-03-03. Drift means the live resource state in Azure/AzureAD has diverged from what Terraform last recorded in remote state.

## Drifted resources

| Resource | Assessment | Action |
|---|---|---|
| `azurerm_key_vault.main` | Key Vault property drift (likely `soft_delete_retention_days`, tags, or network rules changed out-of-band). | Let Terraform reconcile on next apply. Review if any policy was applied externally. |
| `azurerm_container_app_environment.main` | Environment properties (infrastructure subnet, log analytics workspace) may have changed. | Let Terraform reconcile. Confirm no manual scale or network changes were applied. |
| `azuread_application.github_oidc_app` | Application registration properties (e.g., reply URLs, API permissions) may have changed. | Let Terraform reconcile after the `application_id` fix (T000) is applied. |
| `azurerm_container_app.gmail_api` | Container image tag or scaling rules may have drifted from deployment CI. | Expected: deploy workflows update the image tag outside of Terraform. Accept this drift; consider moving image tag into a Terraform variable updated by CI, or exclude the image from Terraform state. |
| `azurerm_container_app.notion_api` | Same as `gmail_api`. | Same as above. |
| `azuread_service_principal.github_oidc_sp` | Service principal properties (tags, preferred token signing key) may have changed. | Let Terraform reconcile; confirm no manual credential rotation was done. |
| `azurerm_key_vault_secret.gmail_api_key` | Secret value or metadata updated out-of-band. | Accept if intentional rotation occurred; otherwise let Terraform reconcile on next apply to ensure `terraform.tfvars` value matches the vault. |
| `azurerm_key_vault_secret.notion_api_key` | Same as `gmail_api_key`. | Same as above. |

## Recommended action

Run `terraform plan` after the T000 fix is merged and review the plan diff for each drifted resource before approving the apply. For container app image tags, consider whether Terraform should own the image tag or whether deploy workflows should update a separate variable file.
