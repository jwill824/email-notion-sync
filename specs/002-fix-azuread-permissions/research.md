# Research: Azure AD permissions required to create applications

## Summary

This document records the findings for the permissions and admin-consent requirements to create Azure AD applications (the resource created by Terraform `azuread_application`). The goal is to grant the HCP/Terraform provisioning identity the minimal privilege required to create an application in the tenant while following the project's security constraints (prefer short-lived or OIDC-based credentials where possible).

## Key findings

- Azure AD application creation is controlled by Microsoft Graph permissions and Azure AD directory roles. There are two common approaches to allow automation to create applications:
  1. Grant the automation principal an Azure AD **Directory Role** such as **Application Administrator** or **Cloud Application Administrator**. These roles allow creating and managing application registrations and service principals. Assignment requires a tenant admin.
  2. Use an application/service principal with **Microsoft Graph application permission** `Application.ReadWrite.All` (application-level). This requires creating an app registration and granting admin consent for that permission (tenant admin step).

- In practice, assigning the `Application Administrator` directory role to the provisioning principal is often the simplest path for automation that needs to create/modify app registrations. The `Application Administrator` role scope is tenant-wide and therefore must be approved and audited.

## Recommended approach (preferred)

1. Use the provisioning identity that HCP/Terraform already uses (prefer an OIDC-federated credential or managed identity if available). If that principal cannot be OIDC/managed, document and limit any long-lived secret use and require governance approval.
2. Request tenant admin to assign the **Application Administrator** directory role to the provisioning principal. This provides the ability to create applications without needing to change existing app registrations.
3. Add a pipeline pre-check that verifies the provisioning principal is present and has the expected role (initially the pre-check will at least validate presence and env vars; later it can query Graph to verify role membership).

## Admin consent and security notes

- Assigning directory roles or granting `Application.ReadWrite.All` requires tenant admin consent. Coordinate with the tenant admin team and record the approval ticket/PR.
- Prefer short-lived, federated credentials for CI (GitHub Actions OIDC) or managed identities for cloud-hosted CI runners to avoid long-lived secrets. This aligns with the project constitution.
- Audit: after assignment, verify role assignment exists and capture the assignment in an audit record (Azure AD audit logs) and tag the PR with the approval reference.

## Verification commands (examples for tenant admin)

- Quick existence check (Azure CLI):

```bash
# ensure az cli is logged in with a user who can view service principals
az ad sp show --id <PROVISIONING_PRINCIPAL_CLIENT_ID>
```

- Portal (GUI) path for role assignment: Azure Portal → Azure Active Directory → Roles and administrators → Application Administrator → Add assignment → select the provisioning principal → Assign

- PowerShell (Microsoft Graph PowerShell module) example to add a directory role member (tenant admin):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes Directory.ReadWrite.All
$role = Get-MgDirectoryRole | Where-Object { $_.displayName -eq 'Application Administrator' }
# servicePrincipalObjectId is the object's id in the directory for the provisioning principal
Add-MgDirectoryRoleMember -DirectoryRoleId $role.Id -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/<servicePrincipalObjectId>" }
```

Note: PowerShell/Microsoft Graph commands require the caller to have sufficient privileges; the portal approach is an alternative if scripting is not desired.

## Fallback option

If tenant admins decline granting the Application Administrator role to the provisioning principal, the fallback is to pre-create the Azure AD application (manual or semi-automated admin step) and provide Terraform with the application ID and secret/credentials to use (or better: a client certificate). This reduces automation convenience but preserves least-privilege.

## Next steps (deliverables for Phase 0)

- Draft an `admin-approval` document with exact commands and approver role (this will be stored as `admin-approval.md`).
- Produce a one-click pre-check script stub (`checks/check_provisioning_perms.sh`) that verifies required env vars and the provisioning principal presence.
- Obtain tenant admin sign-off and record the approval ticket in the spec PR.
