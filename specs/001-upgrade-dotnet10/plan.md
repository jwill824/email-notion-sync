````markdown
# Implementation Plan: Upgrade to .NET 10

**Branch**: `001-upgrade-dotnet10` | **Date**: 2026-02-28 | **Spec**: [specs/001-upgrade-dotnet10/spec.md](specs/001-upgrade-dotnet10/spec.md)
**Input**: Feature specification from `/specs/001-upgrade-dotnet10/spec.md`

## Summary

Upgrade repository projects, CI, and container images from .NET 9 to .NET 10. Goal is a minimally invasive migration that preserves behavior and observability while ensuring builds and tests are successful under the new SDK.

Primary deliverables:
- Update `TargetFramework` to `net10.0` for all source projects (AppHost, FunctionApp, GmailApi, NotionApi, ServiceDefaults, Tests).
- Update GitHub Actions to install/use .NET 10 and record the resolved SDK.
- Update Dockerfiles to use .NET 10 images and verify container smoke tests.
- Validate: `dotnet restore`, `dotnet build`, `dotnet test`, local container runs, CI runs.

## Technical Context

**Language/Version**: C# / .NET 10 (net10.0)
**Primary Dependencies**: ASP.NET Core, Azure Functions Worker, OpenTelemetry, Aspire.Hosting libraries
**Storage**: N/A for migration (No DB schema changes planned)
**Testing**: xUnit (`EmailNotionSync.Tests`), `Aspire.Hosting.Testing` for integration scenarios
**Target Platform**: Linux containers (GHCR + Container Apps), Azure Functions (Linux), local dev macOS (arm64)
**Project Type**: Multi-project .NET solution (services + function host + shared library + tests)
**Performance Goals**: None specific to migration (keep parity)
**Constraints**: Preserve data fidelity; no secrets in repo; CI must log resolved SDK; avoid breaking production behavior
**Scale/Scope**: Small codebase across 6 primary projects

## Constitution Check

Gates from `.specify/memory/constitution.md` considered during planning:

- **Data Fidelity & Safety**: Migration is limited to build/runtime changes; plan documents that no data model changes will be made. PASS (no data migrations required).
- **Library-First**: Shared logic remains in `EmailNotionSync.ServiceDefaults` and library references are unchanged. PASS.
- **Test-First**: Plan requires running unit and integration tests before and after change; CI-excluded tests will be marked with `SkipOnCiFact` if necessary. PASS (tests required and documented).
- **Observability & Health**: Plan includes smoke checks for `/health` and verification of OpenTelemetry traces. PASS (test steps included).
- **Security & Deployment**: No secrets will be added to repo; deployment workflows already use OIDC. PASS (follow existing Key Vault patterns).

Any open violations MUST be documented in Complexity Tracking below.

## Project Structure

Selected structure (actual repo layout):

``text
EmailNotionSync/
  EmailNotionSync.AppHost/
  EmailNotionSync.FunctionApp/
  EmailNotionSync.GmailApi/
  EmailNotionSync.NotionApi/
  EmailNotionSync.ServiceDefaults/
  EmailNotionSync.Tests/
```

**Structure Decision**: Keep existing multi-project layout and migrate in-place to `net10.0`.

## Complexity Tracking

No constitution violations identified that require design changes. The only notable risk is third-party package compatibility; mitigation: run `dotnet restore` and fix or pin package versions as needed. If a package cannot be upgraded, document exception and consider using binding redirects or separate compatibility builds.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | n/a | n/a |

## Phases & Tasks (high-level)

Phase 0 — Research (completed):
- Scan repository for `.csproj`, `global.json`, Dockerfiles, workflows. (T002)
- Decide SDK policy (floating/latest chosen). (spec clarification)

Phase 1 — Foundational (blocking):
- Update project `TargetFramework` entries to `net10.0` (T005–T011). Commit to `001-upgrade-dotnet10`.
- Update any shared MSBuild or `Directory.Build.props` settings if they pin frameworks (T012).

Phase 2 — Build & Tests (P1):
- Restore and build solution under .NET 10 (T014–T015).
- Run unit tests and fix failures (T016).
- Document any compatibility patches (T017).

Phase 3 — Containers & Local Integration (P2):
- Update Dockerfiles to use .NET 10 SDK/runtime images and build test images (T018–T021).
- Run Function host and APIs locally and perform health checks (T022).

Phase 4 — CI & Deployment (P3):
- Update GitHub Actions to use .NET 10 and log `dotnet --info` (T023). Already applied to `build-and-test.yml` and Function App workflow.
- Run CI on feature branch and resolve infra issues (T026).

Phase 5 — Polish & Documentation:
- Push test images to GHCR and validate auth (T029).
- Update `README.md` with .NET 10 developer instructions (T027).
- Open PR with migration notes linking to `CONSTITUTION` and spec (T028).

## Execution Plan & Milestones

1. Ensure feature branch `001-upgrade-dotnet10` exists and is pushed. (Done)
2. Apply `TargetFramework` edits to project files and commit. (Done)
3. Run `dotnet restore`, `dotnet build`, `dotnet test` locally and fix issues. (Done)
4. Update CI workflows to use .NET 10 and log resolved SDK. (Done)
5. Update Dockerfiles and build test images, run smoke tests.
6. Run CI on branch; resolve infra and package issues.
7. Prepare PR with migration notes, link spec and constitution, reference umbrella issue.

## Rollback Plan

- If builds/tests fail irreconcilably in CI, revert the `001-upgrade-dotnet10` branch or open a fixup PR. Because changes are limited to project file TFMs and CI scripts, rollback is a simple revert.

## Risks & Mitigations

- Third-party package incompatibility: Mitigate by pinning package versions, opening issues/prs for replacements, or maintaining a compatibility shim.
- Azure Functions runtime mismatch: Confirm Azure Functions host supports `net10.0` in target deployment. If not supported, consider keeping FunctionApp on `net9.0` until platform upgrade is available and document exception.

## Acceptance Criteria

- All `TargetFramework` entries are `net10.0` (or documented exceptions).
- CI uses .NET 10 and logs resolved SDK version.
- `dotnet restore`, `dotnet build`, and `dotnet test` succeed on the feature branch.
- Docker images build with .NET 10 and pass basic health checks.

## Notes

- The plan follows the project's constitution: data fidelity is preserved (no data migrations), test-first validation is enforced, and observability checks are included.

````
