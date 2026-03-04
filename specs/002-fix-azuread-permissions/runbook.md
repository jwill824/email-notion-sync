# Runbook: Fix and remediate AzureAD Terraform provisioning errors

## Scope

This runbook covers two failure modes:

1. **Terraform code error** — `application_id` attribute mismatch on `azuread_application_federated_identity_credential` (parsing error).
2. **Permission error** — provisioning identity receives `403 Authorization_RequestDenied` when creating/updating `azuread_application`.

---

## Failure 1: `application_id` parsing error

**Symptom:**
```
Error: parsing "d5eb67b9-...": parsing the Application ID: the number of segments didn't match
  with azuread_application_federated_identity_credential.github_actions_credential
  on main.tf line 91
```

**Root cause:** `application_id` was set to `azuread_application.github_oidc_app.client_id` (bare GUID) instead of `.id` (OData path `/applications/{objectId}`).

**Fix:** Already applied in commit for T000. The corrected line is:
```hcl
application_id = azuread_application.github_oidc_app.id
```

**Verification:** Run `terraform plan` in HCP and confirm no parsing errors.

---

## Failure 2: 403 Authorization_RequestDenied on azuread_application

**Symptom:**
```
Error: Authorization_RequestDenied: Insufficient privileges to complete the operation.
  with azuread_application.github_oidc_app
```

**Root cause:** The HCP provisioning service principal lacks the **Application Administrator** Azure AD directory role.

**Resolution steps (requires tenant admin):**

1. Identify the HCP provisioning service principal's client ID from the HCP workspace variables (`HCP_SP_CLIENT_ID`).
2. Follow `admin-approval.md` to assign the **Application Administrator** role.
3. Run the pre-check to verify:
   ```bash
   export PROVISIONING_PRINCIPAL_CLIENT_ID=<client-id>
   bash specs/002-fix-azuread-permissions/checks/check_provisioning_perms.sh
   ```
4. Re-trigger the Terraform plan/apply in HCP.

**Rollback:** Remove the role assignment if it was temporary:
```powershell
Connect-MgGraph -Scopes Directory.ReadWrite.All
$role = Get-MgDirectoryRole | Where-Object { $_.displayName -eq 'Application Administrator' }
$sp = Get-MgServicePrincipal -Filter "appId eq '<clientId>'"
Remove-MgDirectoryRoleMember -DirectoryRoleId $role.Id -DirectoryObjectId $sp.Id
```

---

## Failure 3: Drift on container app resources

**Symptom:** Plan shows drift on `azurerm_container_app.gmail_api` or `azurerm_container_app.notion_api`.

**Root cause:** Deploy workflows update the container image tag outside of Terraform. This is expected.

**Resolution:** Accept the drift on next apply, or move image tags to workspace variables updated by CI. See `outputs/drift-analysis.md` for the full analysis.

---

## Escalation

If the tenant admin is unavailable or declines the role assignment, fall back to the pre-created application approach: manually create the Azure AD application and provide Terraform with the application ID as a variable (remove `azuread_application` from `main.tf` and use a `data` source or hardcoded ID instead).

Contact: open a GitHub issue on this repo and assign the label `infrastructure` + `permissions`.

---

## Removing temporary elevated permissions (T020)

If the Application Administrator role was granted as a **temporary** assignment to unblock initial provisioning, remove it once the `azuread_application`, `azuread_service_principal`, and `azuread_application_federated_identity_credential` resources are confirmed stable in the tenant.

**Portal steps:**
1. Azure Portal → Azure Active Directory → Roles and administrators → Application Administrator.
2. Find the HCP provisioning service principal in the Members list.
3. Click the `...` menu → Remove assignment.

**PowerShell steps (tenant admin):**
```powershell
Connect-MgGraph -Scopes Directory.ReadWrite.All
$role = Get-MgDirectoryRole | Where-Object { $_.displayName -eq 'Application Administrator' }
$sp = Get-MgServicePrincipal -Filter "appId eq '<HCP_SP_CLIENT_ID>'"
Remove-MgDirectoryRoleMember -DirectoryRoleId $role.Id -DirectoryObjectId $sp.Id
```

**Verification after removal:**
```bash
export PROVISIONING_PRINCIPAL_CLIENT_ID=<HCP_SP_CLIENT_ID>
bash specs/002-fix-azuread-permissions/checks/check_provisioning_perms.sh
# Expected: exit code 5 (role membership not found) — confirms removal
```

Record the removal in the PR or as a follow-up commit to `outputs/verify_staging.md` with the timestamp and approver name.

