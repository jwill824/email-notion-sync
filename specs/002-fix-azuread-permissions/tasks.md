---
description: "Task list for feature 002-fix-azuread-permissions"
---

# Tasks: Fix AzureAD permissions causing Terraform 403

**Input**: Design documents from `/specs/002-fix-azuread-permissions/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare infrastructure repo for minimal permission changes and testing in staging HCP workspace

- [ ] T001 Create `specs/002-fix-azuread-permissions/research.md` documenting required Azure AD permissions and admin-consent steps (research.md)
- [ ] T002 [P] Add CI credentials / secrets checklist in `.github/workflows/` and `EmailNotionSync.Terraform/azure/variables.tf` (specs/002-fix-azuread-permissions/tasks.md)
- [ ] T003 [P] Verify HCP Terraform workspace configuration exists for a staging workspace and document its name in `specs/002-fix-azuread-permissions/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Ensure the provisioning identity can be granted the minimal privileges safely and pipeline checks are in place

- [ ] T004 [US1] Draft the exact permission change: propose least-privilege Graph permission(s) or Azure AD role to assign to the provisioning identity; add to `specs/002-fix-azuread-permissions/research.md`
- [ ] T005 [US1] Create `specs/002-fix-azuread-permissions/tasks.md` section 'admin-approval' describing the tenant-admin steps required (who, where, commands)
- [ ] T006 [P] Implement pipeline pre-check script `specs/002-fix-azuread-permissions/checks/check_provisioning_perms.sh` that verifies the provisioning identity has required permissions and exits non-zero otherwise
- [ ] T007 [P] Add pipeline job modification in `.github/workflows/terraform.yml` (or equivalent) to run the pre-check before `terraform apply` in HCP

**Checkpoint**: Foundational tasks complete — provisioning identity permission change and pipeline pre-check are ready (admin approval pending as needed)

---

## Phase 3: User Story 1 - Apply in HCP (Priority: P1) 🎯 MVP

**Goal**: Ensure `terraform apply` in HCP completes successfully and creates `azuread_application.github_oidc_app`

**Independent Test**: Run `terraform apply` in the staging HCP workspace and verify the `azuread_application` resource exists

- [ ] T008 [US1] With tenant-admin, perform the permission assignment for the provisioning identity (manual admin step documented in `specs/002-fix-azuread-permissions/tasks.md#admin-approval`)
- [ ] T009 [US1] Run `terraform plan` in staging HCP workspace and validate no permission errors (capture output to `specs/002-fix-azuread-permissions/outputs/plan_staging.txt`)
- [ ] T010 [US1] Run `terraform apply` in staging HCP workspace and save logs to `specs/002-fix-azuread-permissions/outputs/apply_staging.txt`
- [ ] T011 [US1] Verify created resource in tenant: record app id, display name, and owners in `specs/002-fix-azuread-permissions/outputs/verify_staging.md`
- [ ] T012 [US1] Run the pipeline job 3 consecutive times to validate stability (document in `specs/002-fix-azuread-permissions/outputs/pipeline_runs.md`)

---

## Phase 4: User Story 2 - CI / Pipeline Reliability (Priority: P2)

**Goal**: Make CI resilient by failing fast with clear diagnostics if permissions are missing and avoid partial apply runs

**Independent Test**: Execute the pipeline job that runs Terraform in staging and verify it completes successfully 3 times

- [ ] T013 [US2] Add clear error messaging in the pre-check script when permissions are missing (update `checks/check_provisioning_perms.sh`)
- [ ] T014 [US2] Add automated verification step to pipeline that POSTs apply logs to `specs/002-fix-azuread-permissions/outputs/` for auditability
- [ ] T015 [US2] Add retry/backoff logic to pipeline (optional) when transient authentication issues are detected

---

## Phase 5: User Story 3 - Documentation and Runbook (Priority: P3)

**Goal**: Provide runbook and operator documentation for verifying and remediating permission issues

**Independent Test**: A reviewer follows the runbook and verifies permissions in a test tenant

- [ ] T016 [US3] Create `specs/002-fix-azuread-permissions/quickstart.md` with verification steps and example commands
- [ ] T017 [US3] Create `specs/002-fix-azuread-permissions/runbook.md` with remediation steps, tenant-admin commands, and rollback guidance
- [ ] T018 [US3] Add security notes and audit steps into `specs/002-fix-azuread-permissions/security.md` (who to notify, approvals required)

---

## Phase N: Polish & Cross-Cutting Concerns

- [ ] T019 [P] Update repository README with a short note linking to the spec and runbook
- [ ] T020 [P] Remove any temporary elevated permissions after validation if a temporary scope was used (document steps in `runbook.md`)
- [ ] T021 [P] Finalize PR description and checklist for reviewers

---

## Dependencies & Execution Order

- Setup (Phase 1) → Foundational (Phase 2) → User Stories (Phase 3+) → Polish
- Admin approval (T008) may be required before T010 and T011 can succeed

## Parallel Opportunities

- T002 and T003 can run in parallel
- T006 and T007 (pre-check implementation and pipeline wiring) can run in parallel
- Documentation tasks (T016-T018) can be created while staging runs are in progress

---

## Implementation Strategy

- MVP: Complete Phases 1-3 for US1 first (T001–T012). Validate success and then proceed to US2 and US3.

---
