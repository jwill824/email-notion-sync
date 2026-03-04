# email-notion-sync

Syncs Gmail emails into a Notion database.

## Infrastructure

Azure resources are managed via Terraform in `EmailNotionSync.Terraform/azure/`, applied through an HCP Terraform workspace (`Thingstead / email-notion-sync-azure`).

If you encounter a `403 Authorization_RequestDenied` or a Terraform parsing error on `azuread_application_federated_identity_credential`, see the runbook:
[`specs/002-fix-azuread-permissions/runbook.md`](specs/002-fix-azuread-permissions/runbook.md)
