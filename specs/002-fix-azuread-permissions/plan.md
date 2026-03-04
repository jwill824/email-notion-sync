```markdown
# Implementation Plan: Fix AzureAD permissions causing Terraform 403

**Branch**: `002-fix-azuread-permissions` | **Date**: 2026-03-02 | **Spec**: [spec.md](specs/002-fix-azuread-permissions/spec.md)
**Input**: Feature specification from `/specs/002-fix-azuread-permissions/spec.md`

## Summary

Terraform runs in HashiCorp Cloud (HCP) fail to create the Azure AD application resource `azuread_application.github_oidc_app` with a 403 Authorization_RequestDenied error. Primary approach: grant the HCP/Terraform provisioning identity the minimal Azure AD permission(s) required to create an application (apply only to CI/HCP). Research will identify the exact Graph permissions or Azure AD role and whether admin consent is required; then we implement a minimal, auditable permission change and a pipeline pre-check.

## Technical Context

**Language/Version**: Terraform (HCL), Terraform CLI/HCP workspace environment
**Primary Dependencies**: `hashicorp/azuread` provider (used in EmailNotionSync.Terraform/azure/main.tf), `hashicorp/azurerm` where relevant
**Storage**: N/A
**Testing**: HCP staging workspace, Terraform plan/apply; pipeline run in CI (GitHub Actions or HCP pipeline)
**Target Platform**: HashiCorp Cloud (HCP) Terraform applying to Azure tenant
**Project Type**: Infrastructure-as-Code (Terraform)
**Performance Goals**: N/A
**Constraints**: Must not broaden privileges beyond CI/HCP without approval; tenant-admin intervention may be required for admin consent or role assignment
**Scale/Scope**: Single provisioning identity used by HCP/Terraform for this repo; rollout CI/HCP-only initially

## Constitution Check

Gates (evaluated):

- **Data Fidelity & Safety**: N/A (no user data transformations). PASS.
- **Library-First**: N/A (infrastructure change). PASS.
- **Test-First**: Plan includes reproducible staging runs and pipeline pre-checks before merging. PASS (tests planned).
- **Observability & Health**: Plan includes pipeline logging and explicit diagnostic messages; add telemetry to pipeline logs where possible. PASS (will implement).
- **Security & Deployment**: This feature touches tenant permissions (secrets/privileges). We will document Key Vault usage, require tenant admin approval, and limit scope to CI/HCP. This is a potential policy-sensitive change and is justified (see Complexity Tracking). PARTIAL PASS — requires governance approval during implementation.

Any open violations are listed in Complexity Tracking below.

## Project Structure

This change is focused on the repo's Terraform infra:

``text
EmailNotionSync.Terraform/azure/
├── main.tf        # existing Terraform that defines azuread_application
├── variables.tf   # tenant / identity inputs
└── terraform.tfvars
```

Additional files to add for this feature (in repo):

``text
specs/002-fix-azuread-permissions/
├── plan.md        # this file
├── research.md    # Phase 0 research output (identify exact permissions)
├── tasks.md       # concrete implementation tasks (Terraform edits, admin steps)
└── quickstart.md  # how to verify in staging
```

**Structure Decision**: Keep changes contained to `EmailNotionSync.Terraform/azure/` and `specs/002-fix-azuread-permissions/` documentation; do not alter application code.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Tenant permission change | Granting permission to create applications requires elevated privileges or admin consent. | Alternative (pre-create app and reference it) reduces privileges but requires manual lifecycle management and may complicate automation. We chose granting minimal permission scoped to provisioning identity to preserve CI automation.

Justification: The CI pipeline must be fully automated; pre-creating an app shifts operational burden and complicates rotation/ownership. The permission change will be narrowly scoped, audited, and limited to the HCP provisioning identity.

## Implementation Plan (Phases)

Phase 0 — Research (owner: infra engineer)
- Identify exact permission(s) required to create an Azure AD Application via the `azuread` Terraform provider (likely Graph permission `Application.ReadWrite.All` or an equivalent Azure AD role). Determine if admin consent is required and whether a role assignment (e.g., Application Administrator) is preferable.
- Produce `research.md` documenting the permission, scope, admin consent steps, and security implications.

Phase 1 — Design & Tests
- Draft Terraform or IaC changes needed to assign the permission to the provisioning identity (or provide documented manual admin-consent steps if automation is not possible).
- Design a pipeline pre-check script (shell/Python) to verify the provisioning identity has the required permissions before running `terraform apply`.
- Write an integration test plan to run `terraform plan` and `terraform apply` in a staging HCP workspace and verify the `azuread_application` resource is created and matches expectations.

Phase 2 — Implementation
- Add pipeline pre-check to CI job that runs in HCP before `terraform apply`.
- Apply Terraform changes or follow the manual admin consent flow (documented) in staging (requires tenant-admin to perform/approve).
- Run `terraform apply` in staging and capture logs; if successful, run 3 consecutive pipeline runs to validate stability.

Phase 3 — Documentation & PR
- Add `quickstart.md` and `tasks.md` with step-by-step verification instructions and the runbook for remediation.
- Open PR: include spec link, research findings, exact changes, and request tenant-admin review/approval.

Phase 4 — Monitor & Close
- Monitor CI for 3 successful consecutive runs; collect logs and tag PR for merge/approval.

## Deliverables

- `specs/002-fix-azuread-permissions/research.md` — permissions and admin-consent steps
- `specs/002-fix-azuread-permissions/tasks.md` — exact implementation steps and checklist
- `EmailNotionSync.Terraform/azure/*` — minimal Terraform edits or documented manual steps
- CI pipeline change: pre-check script and updated job
- `specs/002-fix-azuread-permissions/quickstart.md` — verification steps

## Risks & Mitigations

- Risk: Tenant admins decline permission change. Mitigation: fallback to pre-creating the Azure AD application and documenting manual lifecycle instructions.
- Risk: Granting broader-than-intended permissions. Mitigation: request least-privilege, audit after assignment, and document scope and expiration (if temporary).

## Next Action (recommended)

Start Phase 0: create `research.md` and identify the exact permission(s) and admin consent steps. I can begin that research and draft `research.md` now — confirm and I'll proceed.

``` 
