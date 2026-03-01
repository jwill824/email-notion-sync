<!--
Sync Impact Report

- Version change: unknown -> 0.1.0
- Modified principles:
 	- placeholder (unspecified) -> Data Fidelity & Safety
 	- placeholder (unspecified) -> Library-First & Service-Backed Architecture
 	- placeholder (unspecified) -> Test-First & Deterministic CI
 	- placeholder (unspecified) -> Observability & Health
 	- placeholder (unspecified) -> Simplicity, Versioning & Compatibility
- Added sections: Security & Deployment Constraints, Development Workflow
- Removed sections: none
- Templates requiring updates: .specify/templates/plan-template.md (✅ updated by this change), .specify/templates/spec-template.md (⚠ pending review), .specify/templates/tasks-template.md (⚠ pending review)
- Follow-up TODOs: RATIFICATION_DATE needs confirmation (TODO(RATIFICATION_DATE))
-->

# email-notion-sync Constitution

## Core Principles

### Data Fidelity & Safety
All email content and metadata that is synchronized MUST be preserved accurately and reproducibly. The project MUST treat source email as the ground truth: transformations are allowed only when recorded. Sensitive data handling MUST follow least-privilege principles; secrets and API keys MUST be stored in a secrets manager (Azure Key Vault) and never checked into source. Rationale: data loss or unintended redaction would violate user expectations and downstream workflows.

### Library-First & Service-Backed Architecture
Core logic MUST live in reusable libraries (packages) and be callable from both the Gmail and Notion services and the Function host. Services (GmailApi, NotionApi, FunctionApp) are thin wrappers that MUST wire libraries, config, and service defaults (for example, call `builder.AddServiceDefaults()`). Rationale: enables testability, reuse, and consistent runtime behavior across environments.

### Test-First & Deterministic CI
New features and bug fixes MUST include tests that express the expected behavior (unit tests for library logic, integration/contract tests for service boundaries). Tests that require infrastructure not present in CI SHOULD use explicit skip attributes (e.g., `SkipOnCiFact`) and document prerequisites. CI runs MUST be deterministic: avoid flaky timing-based assertions and rely on test doubles for external systems when possible.

### Observability & Health
All services MUST expose health endpoints (`/health` and `/alive`) and integrate OpenTelemetry-compatible tracing. Structured logging (JSON) MUST be emitted for important events, and application metrics for sync success/failure rates MUST be recorded. Rationale: operational visibility is critical for a sync system that processes user data.

### Simplicity, Versioning & Compatibility
Prefer the minimal viable design that safely meets requirements (YAGNI). Public APIs and stored artifacts MUST use semantic versioning (MAJOR.MINOR.PATCH). Backwards-incompatible changes MUST bump MAJOR and include a migration plan and tests demonstrating the migration path.

## Security & Deployment Constraints
- Authentication for CI-to-cloud deployments MUST use OIDC (GitHub Actions federated identity) where supported.
- Secrets MUST be stored in Azure Key Vault and accessed via managed identities; service principals with long-lived secrets are disallowed for runtime use.
- Container images for GmailApi and NotionApi MUST be published to GHCR and deployed via the repository's prescribed flow.

## Development Workflow
- All services and libraries MUST call `AddServiceDefaults()` to ensure consistent health checks, telemetry, and service discovery behavior.
- Pull requests that modify sync behavior MUST include tests and an explanation of data migration or compatibility impact in the PR description.
- Changes that affect runtime configuration, secrets, or deployment paths MUST include an explicit rollout and rollback plan.

## Governance
Amendments to this constitution follow the process below:

- Propose: Create a descriptive PR that updates `.specify/memory/constitution.md` and includes a migration/impact note.
- Review: At least one repository owner or codeowner MUST approve the change; CI MUST be green for the PR before merge.
- Ratify: For non-breaking clarifications or editorial fixes, merge after one approval. For changes that add/remove principles or create new obligations, obtain explicit approval from project owners (majority of listed owners) and include a version bump following the Versioning Policy below.

Versioning Policy:

- Increment `CONSTITUTION_VERSION` using semantic versioning:
	- MAJOR: removal or redefinition of existing principles (backwards-incompatible governance change).
	- MINOR: addition of new principle or materially expanded guidance.
	- PATCH: editorial clarifications, non-normative wording, or typo fixes.

**Version**: 0.1.0 | **Ratified**: TODO(RATIFICATION_DATE): requires project owner confirmation | **Last Amended**: 2026-02-28

