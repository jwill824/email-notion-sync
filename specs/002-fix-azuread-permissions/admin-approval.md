# Admin approval: steps to grant provisioning identity permissions

This document lists tenant-admin steps to grant the provisioning principal the minimal role required to create Azure AD applications.

> **Solo-tenant note**: If you created your Azure tenant with a personal Microsoft account, your account is already the **Global Administrator**. You can perform all steps below yourself — no separate approver is needed. To confirm, run:
> ```bash
> az rest --method GET \
>   --uri "https://graph.microsoft.com/v1.0/me/memberOf/microsoft.graph.directoryRole" \
>   --query "value[].displayName" --output json
> ```
> If `"Global Administrator"` appears, proceed as the approver.

## Why this cannot be managed by Terraform

These role assignments are **bootstrap steps**. Terraform authenticates to Azure *as the HCP service principal* (`email-notion-sync-prod-sp`). Until that SP has Application Administrator, Terraform cannot create Azure AD app registrations — which means Terraform cannot grant itself that role either. The initial grant must be done manually by a Global Administrator. After that, Terraform can manage everything else.

## Required role

- **Application Administrator** — allows creating and managing app registrations and service principals.
- Do **not** assign Global Administrator; it is far broader than needed.

## Portal steps: assign Application Administrator

1. Sign in to the Azure Portal as a tenant administrator.
2. Navigate to **Azure Active Directory** → **Roles and administrators**.
3. Search for **Application Administrator** and open the role.
4. Click **Add assignment** → search for `email-notion-sync-prod-sp` → select → **Add**.
5. Record the approval ticket/PR number and timestamp; capture Azure AD Audit Log entry.

## Portal steps: remove Global Administrator (scoping down)

> Perform this **after** verifying Application Administrator is assigned.

1. Sign in to the Azure Portal as a tenant administrator.
2. Navigate to **Azure Active Directory** → **Roles and administrators**.
3. Search for **Global Administrator** and open the role.
4. Find `email-notion-sync-prod-sp` in the members list.
5. Select it → click **Remove assignment** → confirm.
6. Capture the Audit Log entry for the removal.

## PowerShell steps (alternative to Portal)

Run these as a tenant admin with Microsoft Graph PowerShell module installed.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes Directory.ReadWrite.All

$spObjectId = "eb22353c-c007-4736-b1cf-78024d946b57"

# Add Application Administrator
$aaRole = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq 'Application Administrator' }
Add-MgDirectoryRoleMember -DirectoryRoleId $aaRole.Id `
  -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$spObjectId" }

# Remove Global Administrator
$gaRole = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq 'Global Administrator' }
Remove-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id -DirectoryObjectId $spObjectId
```

## Verification

- Confirm Application Administrator is visible in Azure Portal under the role members list.
- Confirm Global Administrator no longer lists `email-notion-sync-prod-sp`.
- Check Azure AD audit logs for both the assignment and removal actions.

## Rollback

To restore the previous state (not recommended): assign Global Administrator again via the Portal or `Add-MgDirectoryRoleMember`.

## Governance note

Assignments must be least-privilege. Record the reason, approver, and date in the PR. For solo tenants, "approver = account owner" is acceptable — document it explicitly.
