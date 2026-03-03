# Admin approval: steps to grant provisioning identity permissions

This document lists tenant-admin steps to grant the provisioning principal the minimal role required to create Azure AD applications.

## Recommended role

- **Application Administrator** — allows creating and managing app registrations and service principals.

## Portal (manual) steps

1. Sign in to the Azure Portal as a tenant administrator.
2. Navigate to **Azure Active Directory** → **Roles and administrators**.
3. Search for **Application Administrator** and open the role.
4. Click **Add assignment** → search for the provisioning principal (service principal name or display name) → select → **Add**.
5. Record the approval ticket/PR number and the timestamp; capture Azure AD Audit Log entry for the assignment.

## PowerShell (scripted) steps

Run these as a tenant admin with Microsoft Graph PowerShell module installed.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes Directory.ReadWrite.All

# Find the Directory Role
$role = Get-MgDirectoryRole | Where-Object { $_.displayName -eq 'Application Administrator' }

# Find service principal object id for the provisioning principal (replace <clientId>)
$sp = Get-MgServicePrincipal -Filter "appId eq '<clientId>'"

# Add the service principal to the role
Add-MgDirectoryRoleMember -DirectoryRoleId $role.Id -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($sp.Id)" }
```

## Verification

- Confirm the role assignment is visible in Azure Portal under the role members list.
- Check Azure AD audit logs for the assignment action and record the evidence in the PR.

## Rollback

- To remove the assignment, use the Portal UI or PowerShell `Remove-MgDirectoryRoleMember` with the same parameters.

## Governance note

- Assignments must be least-privilege and temporary where possible. Record the reason, approver, and expected expiry in the PR.
