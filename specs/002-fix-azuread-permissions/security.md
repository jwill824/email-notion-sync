# Security Notes: AzureAD provisioning permissions

## Permission scope

The provisioning identity (HCP service principal) requires the **Application Administrator** Azure AD directory role to create and manage `azuread_application` and `azuread_service_principal` resources via Terraform.

**Scope of this role:** Tenant-wide. The role allows creating, reading, updating, and deleting application registrations and service principals in the entire Azure AD tenant. It does NOT grant rights to manage Azure subscription resources (that is handled by the Contributor role assignment on the resource group).

## Least-privilege principle

- **Application Administrator** is the narrowest role that grants application creation rights without requiring Global Administrator.
- An alternative (`Cloud Application Administrator`) has the same scope over app registrations but cannot manage on-premises proxied applications. Either role is acceptable; prefer `Cloud Application Administrator` if the tenant admin is willing to evaluate it.
- Do not grant `Global Administrator` or `Application.ReadWrite.OwnedBy` application permissions unless specifically required and approved.

## Credential management

- The HCP provisioning identity authenticates to Azure using a **federated identity credential** (OIDC token from HCP Terraform) — no long-lived client secret is used.
- The GitHub Actions OIDC workflow (`deploy-*` workflows) also uses OIDC federated credentials (no stored secrets).
- API keys for GmailApi and NotionApi are stored in **Azure Key Vault** and accessed by container app managed identities via `Get`/`List` access policies only.

## Approval requirements

| Change | Approver required |
|--------|------------------|
| Assign Application Administrator role to HCP SP | Tenant administrator |
| Grant `Application.ReadWrite.All` Graph app permission | Tenant administrator + admin consent |
| Add new Key Vault access policy | Repo owner |
| Add new role assignment (subscription scope) | Subscription owner |

## Audit trail

- Azure AD role assignments are recorded in the Azure AD Audit Log under **Directory** → **AuditLogs** → category `RoleManagement`.
- Record the assignment in the PR that implements the fix: include the tenant admin's name, the date, and the Azure AD audit log event ID.

## Notification list

If permissions are changed or a new identity is granted access, notify:
- Repository owner / infra lead (via PR review)
- Security team (if tenant-wide role is involved) — open a security review ticket and link it from the PR.

## Temporary vs. permanent assignment

If the role is granted temporarily (e.g., for initial provisioning only), document the expected expiry in the PR and schedule removal. Use the rollback steps in `runbook.md` to remove the role once the Azure AD resources are fully provisioned and stable.
