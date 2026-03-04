# Runbook: Fix and remediate AzureAD Terraform provisioning errors

## Scope

This runbook covers failure modes encountered while getting `terraform apply` to succeed in HCP:

1. **Terraform code error** — `application_id` attribute mismatch on `azuread_application_federated_identity_credential` (parsing error).
2. **Permission error** — provisioning identity receives `403 Authorization_RequestDenied` when creating/updating `azuread_application`.
3. **Terraform code error** — `azurerm_role_assignment.principal_id` used `.id` (OData path) instead of `.object_id` (GUID).
4. **RBAC gap** — HCP SP has `Contributor` but not `User Access Administrator`; cannot create role assignments.
5. **App Service quota = 0** — new PAYG subscriptions default to 0 quota for all App Service SKUs in a region.

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

---

## Failure 3: `azurerm_role_assignment` 403 — malformed principal ID

**Symptom:**
```
Error: unexpected status 403 (403 Forbidden)
AuthorizationFailed: does not have authorization to perform action
'Microsoft.Authorization/roleAssignments/write'
```

**Root cause:** `azurerm_role_assignment.principal_id` was set to `azuread_service_principal.github_oidc_sp.id` which returns the OData path `/servicePrincipals/{guid}`. The ARM API requires a plain GUID.

**Fix:** Already applied. Corrected line in `main.tf`:
```hcl
principal_id = azuread_service_principal.github_oidc_sp.object_id
```

**General rule:** When passing a service principal reference to any `azurerm_*` resource, always use `.object_id`, never `.id`.

---

## Failure 4: HCP SP lacks `roleAssignments/write` (403 on role assignment)

**Symptom:** Same 403 as above but after the code fix — HCP SP genuinely lacks the permission.

**Root cause:** `Contributor` role excludes all `Microsoft.Authorization/*` actions. Creating role assignments requires `Owner` or `User Access Administrator`.

**Fix:** Grant `User Access Administrator` to the HCP SP on the resource group:
```bash
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/resourceGroups/email-notion-sync-rg/providers/Microsoft.Authorization/roleAssignments/{newGuid}?api-version=2022-04-01" \
  --body '{
    "properties": {
      "roleDefinitionId": "/subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
      "principalId": "eb22353c-c007-4736-b1cf-78024d946b57",
      "principalType": "ServicePrincipal"
    }
  }'
```

**Verification:**
```bash
az role assignment list \
  --assignee eb22353c-c007-4736-b1cf-78024d946b57 \
  --scope /subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/resourceGroups/email-notion-sync-rg \
  --query "[].roleDefinitionName" --output tsv
# Expected: User Access Administrator (and Contributor)
```

---

## Failure 5: App Service Plan quota = 0 (401 Unauthorized)

**Symptom:**
```
Error: creating App Service Plan: unexpected status 401 (401 Unauthorized)
Current Limit (Basic VMs): 0   (or Dynamic VMs: 0)
```

**Root cause:** New Azure PAYG subscriptions default to quota 0 for all App Service SKUs in each region. This applies to F1, D1, B1–B3, S1–S3, Y1, EP1–EP3, and more — even for Pay-As-You-Go subscriptions.

**Diagnosis — check all SKU quotas for a region:**
```bash
az quota list \
  --scope "subscriptions/{subId}/providers/Microsoft.Web/locations/eastus2" \
  --output json | python3 -c "
import json, sys
for item in json.loads(sys.stdin.read()):
    name = item['name']
    val = item['properties']['limit']['value']
    print(f'{name}: {val}')
"
```

**Fix:**
1. Determine which SKU you need (Y1 for Consumption, B1 for Basic, S1 for Standard).
2. Go to **Azure Portal → Help + Support → New support request**:
   - Issue type: Service and subscription limits (quotas)
   - Quota type: App Service
   - Select subscription, region, SKU → request new limit of **1**
3. Approval is typically instant for PAYG subscriptions.
4. Verify: re-run the diagnosis command above and confirm the SKU limit > 0.

**Additional constraint for Y1 (Consumption):** Consumption plans do not support deployment slots. Remove `azurerm_linux_function_app_slot` resources and update any deploy workflows to deploy directly to production.

---

## Failure 6: Drift on container app resources

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

