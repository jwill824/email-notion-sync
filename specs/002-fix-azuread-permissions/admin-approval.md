# Admin approval: bootstrap steps for provisioning and deployment

This document records the manual steps that **cannot be managed by Terraform or CI** and must be performed by a subscription/tenant owner before `terraform apply` and the deploy pipelines will succeed.

> **Solo-tenant note**: If you created your Azure tenant with a personal Microsoft account, your account is already the **Global Administrator** and subscription owner. You can perform all steps below yourself. To confirm your role, run:
> ```bash
> az rest --method GET \
>   --uri "https://graph.microsoft.com/v1.0/me/memberOf/microsoft.graph.directoryRole" \
>   --query "value[].displayName" --output json
> ```

---

## Action 1: Grant Application Administrator to HCP Service Principal

### Why this cannot be managed by Terraform

Terraform authenticates as the HCP service principal (`email-notion-sync-prod-sp`). Until that SP has Application Administrator, Terraform cannot create Azure AD app registrations — which means it cannot grant itself that role. The initial grant must be done manually by a Global Administrator.

### Required role

- **Application Administrator** — allows creating and managing app registrations and service principals.
- Do **not** assign Global Administrator; it is far broader than needed.

> **Completed state**: The HCP SP (`email-notion-sync-prod-sp`) was found with **Global Administrator** initially assigned (broader than needed). Application Administrator has since been assigned and Global Administrator has been removed. The steps below are retained as the reference procedure.

### Portal steps: assign Application Administrator

1. Sign in to the Azure Portal as a tenant administrator.
2. Navigate to **Azure Active Directory** → **Roles and administrators**.
3. Search for **Application Administrator** and open the role.
4. Click **Add assignment** → search for `email-notion-sync-prod-sp` → select → **Add**.
5. Record the approval ticket/PR number and timestamp; capture Azure AD Audit Log entry.

### Portal steps: remove Global Administrator (scoping down)

> Perform this **after** verifying Application Administrator is assigned.

1. Navigate to **Azure Active Directory** → **Roles and administrators**.
2. Search for **Global Administrator** and open the role.
3. Find `email-notion-sync-prod-sp` → click **Remove assignment** → confirm.
4. Capture the Audit Log entry for the removal.

### PowerShell steps (alternative to Portal)

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

### Verification

```bash
# Confirm Application Administrator is assigned; Global Administrator is absent
az rest --method GET \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/eb22353c-c007-4736-b1cf-78024d946b57/memberOf" \
  --query "value[].displayName" --output json
```

---

## Action 2: Request App Service quota increase

### Why this is a manual step

New Pay-As-You-Go subscriptions default to **0 quota for all App Service SKUs** in every region. Terraform cannot create an App Service Plan until the quota is non-zero. Quota increases are granted by Azure Support and cannot be automated.

### What we changed in Terraform first

Before requesting quota, switch `azurerm_service_plan.main` to the Y1 Consumption SKU (no per-instance charge, free tier covers ~1M executions/month):

```hcl
# EmailNotionSync.Terraform/azure/main.tf
resource "azurerm_service_plan" "main" {
  sku_name = "Y1"   # was B1; Y1 = Consumption (Dynamic VMs quota type)
  ...
}
```

Also remove any `azurerm_linux_function_app_slot` resources — Consumption plans do not support deployment slots.

### Portal steps: request Dynamic VMs quota increase

> **Completed state**: Quota approved 2026-03-04. East US 2 — Dynamic VMs limit is now 1.

1. Sign in to the Azure Portal as the subscription owner.
2. Navigate to **Help + Support** → **New support request**.
3. Select **Issue type: Service and subscription limits (quotas)**.
4. Select your subscription → **Quota type: App Service**.
5. Click **Next: Solutions** → then **Next: Details**.
6. Select region **East US 2** → resource type **Dynamic VMs** → new limit **1**.
7. Submit. For Pay-As-You-Go subscriptions, approval is typically instant.

### Verification

```bash
# Confirm Dynamic VMs quota is non-zero in eastus2
az quota list \
  --scope "subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/providers/Microsoft.Web/locations/eastus2" \
  --query "[?name.value=='Dynamic'].{name:name.value, limit:properties.limit, used:properties.currentValue}" \
  --output table
```

Expected output: `limit` ≥ 1.

---

## Action 3: Grant User Access Administrator to HCP Service Principal

### Why this is a manual step

`Contributor` (the baseline HCP SP role) explicitly excludes `Microsoft.Authorization/roleAssignments/write`. Terraform needs to create role assignments (e.g., granting GitHub Actions Contributor on the resource group), so the HCP SP also needs `User Access Administrator` at resource group scope.

> **Completed state**: Role assignment created 2026-03-04. Assignment ID: `e9163508-1470-3350-aaeb-64c293cf7f26`.

### Azure CLI steps

```bash
HCP_SP_OBJECT_ID="eb22353c-c007-4736-b1cf-78024d946b57"
RG_ID="/subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/resourceGroups/email-notion-sync-rg"

az role assignment create \
  --assignee-object-id "$HCP_SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "User Access Administrator" \
  --scope "$RG_ID"
```

If `az role assignment create` is unavailable (insufficient caller permissions on the CLI token), use `az rest`:

```bash
ASSIGNMENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
az rest --method PUT \
  --uri "${RG_ID}/providers/Microsoft.Authorization/roleAssignments/${ASSIGNMENT_ID}?api-version=2022-04-01" \
  --body "{
    \"properties\": {
      \"roleDefinitionId\": \"${RG_ID}/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9\",
      \"principalId\": \"${HCP_SP_OBJECT_ID}\",
      \"principalType\": \"ServicePrincipal\"
    }
  }"
```

### Verification

```bash
az role assignment list \
  --assignee "eb22353c-c007-4736-b1cf-78024d946b57" \
  --scope "/subscriptions/4bf812ab-554d-4a16-8241-578e13632bb3/resourceGroups/email-notion-sync-rg" \
  --query "[].{role:roleDefinitionName}" --output table
```

Expected: `Contributor` and `User Access Administrator` both listed.

---

## Governance note

All actions above must be least-privilege. Record the reason, approver, and date in the PR or commit message. For solo tenants, "approver = account owner" is acceptable — document it explicitly.

## Rollback

- **Action 1**: Re-assign Global Administrator (not recommended); or simply remove Application Administrator if the Azure AD resources are no longer managed by Terraform.
- **Action 2**: Quota reductions require a support request; in practice, simply stop using the App Service Plan.
- **Action 3**: `az role assignment delete --ids <assignment-id>` to remove User Access Administrator from the HCP SP.

