```markdown
# Feature Specification: Fix AzureAD permissions causing Terraform 403

**Feature Branch**: `001-fix-azuread-permissions`  
**Created**: 2026-03-02  
**Status**: Draft  
**Input**: User description: "Fix azure terraform resource creation issue causing 403 Forbidden on azuread_application: Authorization_RequestDenied: Insufficient privileges to complete the operation."

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
- **FR-006**: The remediation approach SHOULD be one of the following options: grant the provisioning identity the required permission to create the application, or switch to using a pre-created, managed application that Terraform can reference. [NEEDS CLARIFICATION: choose remediation approach — grant provisioning identity elevated rights, or pre-create app and reference it?]
- **FR-007**: The scope of the change SHOULD be limited to CI/HCP environments initially; broader production rollout requires a separate approval. [NEEDS CLARIFICATION: Should the fix be applied only to CI/HCP, or also to ad-hoc local dev usage?]

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

1. Reproduce the original failure in a staging workspace (capture `terraform apply` logs showing 403 and the resource path `azuread_application.github_oidc_app`).
2. Apply the remediation (as per selected approach in FR-006) in the staging workspace.
3. Run `terraform apply` and verify it completes successfully and the `azuread_application` resource exists.
4. Run the pipeline job 3 times; verify no 403 errors and consistent success.
5. Confirm runbook and documentation are added to the repo and that a reviewer can follow them to verify permissions.

## Notes / Implementation Constraints

- This specification intentionally describes the problem and acceptance criteria; implementation details (exact permission names, Terraform code changes) will be documented in the tasks and PR that implement the fix.

``` 
