# Feature Specification: Fix AzureAD permissions causing Terraform 403

**Feature Branch**: `002-fix-azuread-permissions`  
**Created**: 2026-03-02  
**Status**: Complete  
**Input**: User description: "Fix azure terraform resource creation issue causing 403 Forbidden on azuread_application: Authorization_RequestDenied: Insufficient privileges to complete the operation."

## Current State (from `terraform plan` run 2026-03-03)

A `terraform plan` was executed against the HCP workspace and produced the following findings:

**Blocking error (must fix before apply succeeds):**

```
Error: parsing "d5eb67b9-9b04-4688-9a45-6dfdacc40727": parsing the Application ID: the number of segments didn't match

Expected a Application ID that matched (containing 2 segments):
  /applications/applicationId

However this value was provided (which was parsed into 0 segments):
  d5eb67b9-9b04-4688-9a45-6dfdacc40727

  with azuread_application_federated_identity_credential.github_actions_credential,
  on main.tf line 91, in resource "azuread_application_federated_identity_credential":
  91:   application_id = azuread_application.github_oidc_app.client_id
```

Root cause: `azuread_application_federated_identity_credential.application_id` requires the OData-style path (`/applications/{objectId}`) returned by `azuread_application.id`, not the bare GUID returned by `azuread_application.client_id`.

**Fix**: change line 91 of `EmailNotionSync.Terraform/azure/main.tf` from:
```hcl
application_id = azuread_application.github_oidc_app.client_id
```
to:
```hcl
application_id = azuread_application.github_oidc_app.id
```

**Status of original 403 error**: The `azuread_application.github_oidc_app` resource refreshed successfully from state (`id=/applications/600f9303-d545-4c7c-a03f-d538055423ee`), indicating the original Authorization_RequestDenied 403 has already been resolved (the app exists in the tenant).

**Drift detected** on the following resources (non-blocking but should be reviewed):
- `azurerm_key_vault.main`
- `azurerm_container_app_environment.main`
- `azuread_application.github_oidc_app`
- `azurerm_container_app.gmail_api`
- `azurerm_container_app.notion_api`
- `azuread_service_principal.github_oidc_sp`
- `azurerm_key_vault_secret.gmail_api_key`
- `azurerm_key_vault_secret.notion_api_key`

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Apply in HCP (Priority: P1)

An operator runs the Terraform HCP workspace that provisions Azure resources (including `azuread_application.github_oidc_app`) and expects the apply to complete successfully without a 403 Forbidden error.

**Why this priority**: This is the immediate blocker preventing infrastructure from being provisioned in CI/CD (HCP) — high operational impact.

**Independent Test**: Run the failing Terraform configuration in the HCP workspace or equivalent test environment and observe `terraform apply` completes with exit code 0 and the `azuread_application` resource exists in the tenant.

**Acceptance Scenarios**:

1. **Given** a Terraform HCP workspace configured to apply the repository's `main.tf` (including `azuread_application.github_oidc_app`), **When** the operator runs `terraform apply` in HCP, **Then** the apply completes successfully and no `403 Forbidden` (Authorization_RequestDenied) errors are returned.
2. **Given** the resource was not previously present, **When** the apply completes, **Then** the new Azure AD Application is visible in the tenant and matches the expected attributes (display name, reply URLs, etc.).

---

### User Story 2 - CI / Pipeline Reliability (Priority: P2)

The CI pipeline that invokes Terraform should be resilient to this permission issue: operators should be able to run pipeline jobs that provision or update the GitHub OIDC app without manual intervention.

**Why this priority**: Ensures continuous delivery and reduces manual fixes during deployment.

**Independent Test**: Execute the pipeline job that runs Terraform in a staging HCP workspace and verify it completes successfully across at least 3 consecutive runs.

**Acceptance Scenarios**:

1. **Given** the pipeline credentials and HCP workspace are configured, **When** the pipeline runs Terraform, **Then** it completes successfully at least 3 times in a row without 403 errors.

---

### User Story 3 - Documentation and Runbook (Priority: P3)

Operators and maintainers need clear documentation: what permissions are required, how to verify them, and steps to remediate in case of failures.

**Why this priority**: Reduces time-to-resolution for future incidents and on-call churn.

**Independent Test**: A third-party reviewer can follow the runbook to verify permissions and remediate in a test tenant.

**Acceptance Scenarios**:

1. **Given** the runbook and documentation, **When** a new operator follows the steps, **Then** they can verify the provisioning identity's permissions and either fix them or validate that provisioning will succeed.

---

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- Terraform identity has read-only permissions or only user-consent but not application permissions: provisioning should fail with clear diagnostics in logs.
- Tenant policy (PIM, Conditional Access, AAD settings) blocks creation of applications by service principals: document and detect this condition and surface remediation guidance.
- Resource already exists but owned by another principal: apply should either adopt (if allowed) or fail with a deterministic error that points to ownership.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: The infrastructure provisioning process MUST successfully create the `azuread_application.github_oidc_app` resource in the target tenant when executed from the HCP Terraform workspace.
- **FR-002**: The provisioning process MUST not return an HTTP 403 Authorization_RequestDenied error for the `azuread_application` resource during normal runs.
- **FR-003**: When permission-related errors occur, the system MUST produce clear, actionable diagnostics in logs and pipeline output describing which privilege is missing and suggested remediation steps.
- **FR-004**: The fix MUST include an automated or documented verification step that confirms the provisioning identity has the minimum required permissions before attempting creation.
- **FR-005**: The change MUST be covered by an automated integration test or pipeline check that validates successful resource creation in a repeatable staging environment.
- **FR-006**: The remediation approach WILL be to grant the provisioning identity the required permission to create the Azure AD application (chosen option: grant provisioning identity required permissions). This requires tenant admin approval and a security review; changes will be limited to the provisioning identity used by HCP/Terraform.
- **FR-007**: The scope of the change WILL be limited to CI/HCP environments initially (chosen option: CI/HCP only). Local developer workflows will remain unchanged unless a separate follow-up change is approved.
- **FR-008**: `EmailNotionSync.Terraform/azure/main.tf` MUST be corrected so that `azuread_application_federated_identity_credential.github_actions_credential` references `azuread_application.github_oidc_app.id` (the OData path `/applications/{objectId}`) instead of `azuread_application.github_oidc_app.client_id` (bare GUID). This is the immediate blocker for `terraform plan`/`apply` to succeed.
- **FR-009**: After the Terraform code fix is applied, the operator MUST review and reconcile the drift detected on `azurerm_key_vault`, `azurerm_container_app_environment`, `azuread_application`, `azurerm_container_app.gmail_api`, `azurerm_container_app.notion_api`, `azuread_service_principal`, and both Key Vault secrets. Each drifted resource should either be brought back into Terraform's desired state or have the drift documented and accepted.

### Key Entities *(include if feature involves data)*

- **Azure AD Application**: Represents the `azuread_application.github_oidc_app` resource — key attributes include display name, identifiers, reply URLs, owners.
- **Provisioning Identity**: The principal (service principal, managed identity, or HCP-managed identity) used by Terraform/HCP to create Azure AD resources.
- **HCP Terraform Workspace**: The HashiCorp Cloud (HCP) Terraform workspace that runs `terraform apply`.
- **Azure Tenant / Directory**: The target Azure AD tenant where applications are created.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: `terraform apply` in the designated HCP workspace completes with exit code 0 and without `403 Forbidden` errors for `azuread_application` in 100% of test runs (3/3 consecutive runs) in staging.
- **SC-002**: The created Azure AD Application is present in the tenant and matches the expected configuration (display name and identifiers) in 100% of verification checks.
- **SC-003**: The pipeline job that previously failed due to 403 now completes successfully in CI for at least 3 consecutive runs.
- **SC-004**: Documentation and runbook added; an operator can verify and remediate the issue in under 15 minutes following the runbook.

## Assumptions

- The HCP Terraform workspace can authenticate to the target tenant using a provisioning identity capable of being granted permissions.
- The failure observed is caused by missing privileges for the provisioning identity rather than a transient Azure service outage.
- Changing permissions or referencing a pre-created app is acceptable within current security policies after review.

## Acceptance Tests / Validation

1. **[New — highest priority]** Fix `main.tf` line 91: change `application_id = azuread_application.github_oidc_app.client_id` to `application_id = azuread_application.github_oidc_app.id`.
2. Run `terraform plan` in the HCP workspace and confirm no errors are emitted for `azuread_application_federated_identity_credential.github_actions_credential`.
3. Reproduce the original failure in a staging workspace (capture `terraform apply` logs showing 403 and the resource path `azuread_application.github_oidc_app`).
4. Apply the remediation (as per selected approach in FR-006) in the staging workspace.
5. Run `terraform apply` and verify it completes successfully and the `azuread_application` resource exists.
6. Run the pipeline job 3 times; verify no 403 errors and consistent success.
7. Review drift on all 8 drifted resources listed in FR-009 and bring them back to desired state or document accepted divergence.
8. Confirm runbook and documentation are added to the repo and that a reviewer can follow them to verify permissions.

## Additional Blockers Discovered During Apply

The following issues were discovered only after `terraform apply` started running in HCP — they were not visible from `terraform plan` alone.

### Blocker A: `azurerm_role_assignment` used `.id` instead of `.object_id`

**Error:**
```
Error: unexpected status 403 (403 Forbidden)
AuthorizationFailed: The client '...' does not have authorization to perform action
'Microsoft.Authorization/roleAssignments/write'
```

**Root cause (misleading):** The 403 initially suggested missing RBAC permissions, but the actual root cause was a second `azuread` provider attribute bug. `azurerm_role_assignment.principal_id` was set to `azuread_service_principal.github_oidc_sp.id` (OData path `/servicePrincipals/{objectId}`) instead of `.object_id` (bare GUID). The ARM API rejected the malformed principal ID.

**Fix:** Applied in `main.tf` line 101:
```hcl
# Before (wrong)
principal_id = azuread_service_principal.github_oidc_sp.id
# After (correct)
principal_id = azuread_service_principal.github_oidc_sp.object_id
```

**Pattern:** AzureRM resources expect plain GUIDs for `principal_id`/`object_id` fields; `azuread` provider `.id` attributes return OData paths (`/servicePrincipals/{guid}`). Always use `.object_id` when passing a service principal to an `azurerm_*` resource.

---

### Blocker B: HCP SP lacked `Microsoft.Authorization/roleAssignments/write`

**Error (after fixing Blocker A):**
```
Error: unexpected status 403 (403 Forbidden)
AuthorizationFailed: does not have authorization to perform action
'Microsoft.Authorization/roleAssignments/write'
```

**Root cause:** The HCP service principal had `Contributor` at subscription scope. `Contributor` explicitly excludes `Microsoft.Authorization/*` actions — creating role assignments requires `Owner` or `User Access Administrator`.

**Fix:** Granted `User Access Administrator` to the HCP SP on the resource group scope:
```bash
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/{subId}/resourceGroups/email-notion-sync-rg/providers/Microsoft.Authorization/roleAssignments/{newGuid}?api-version=2022-04-01" \
  --body '{"properties":{"roleDefinitionId":"/subscriptions/{subId}/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9","principalId":"eb22353c-c007-4736-b1cf-78024d946b57","principalType":"ServicePrincipal"}}'
```

Note: `User Access Administrator` role definition ID is always `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` (built-in, subscription-invariant).

---

### Blocker C: App Service Plan quota = 0 for all non-Premium tiers

**Error:**
```
Error: creating App Service Plan: unexpected status 401 (401 Unauthorized)
Current Limit (Basic VMs): 0
```

Then after switching to Y1:
```
Current Limit (Dynamic VMs): 0
```

**Root cause:** New Pay-As-You-Go Azure subscriptions default to quota 0 for all App Service SKUs in a given region. Every SKU from F1 through EP3 had quota=0 in `eastus2`. Only Premium V4 tiers (P0v4+, ~$140+/month) had quota=30.

**Fix:**
1. Changed `sku_name = "B1"` → `"Y1"` (Consumption plan — free for low-usage Functions)
2. Removed `azurerm_linux_function_app_slot.staging` — Consumption plans do not support deployment slots
3. Updated `deploy-function-app.yml` to deploy directly to production instead of staging slot + swap
4. Requested Y1 (Dynamic VMs) quota increase via Azure Portal → Help + Support → Quota → App Service → East US 2 → requested 1 instance → approved

**Quota verification:**
```bash
az quota list \
  --scope "subscriptions/{subId}/providers/Microsoft.Web/locations/eastus2" \
  --output json | python3 -c "
import json, sys
for item in json.loads(sys.stdin.read()):
    name = item['name']
    val = item['properties']['limit']['value']
    if val > 0:
        print(f'{name}: {val}')
"
```

**Cost impact of Y1:** Azure Functions Consumption plan bills per-execution and per GB-second. With a timer trigger firing every minute:
- ~43,200 executions/month — well under the 1M free-tier grant
- ~22,000 GB-seconds/month — well under the 400K free-tier grant
- **Estimated monthly cost: $0.00**

---

## Notes / Implementation Constraints

- This specification intentionally describes the problem and acceptance criteria; implementation details (exact permission names, Terraform code changes) will be documented in the tasks and PR that implement the fix.
- The `azuread` provider consistently uses OData paths for `.id` attributes; always use `.object_id` when an `azurerm_*` resource expects a plain GUID.
