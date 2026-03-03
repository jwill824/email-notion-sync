# Feature Specification: Upgrade to .NET 10

**Feature Branch**: `001-upgrade-dotnet10`
**Created**: 2026-02-28
**Status**: Draft
**Input**: Upgrade repository projects from .NET 9 to .NET 10, update Dockerfiles, CI, and verify runtime compatibility.

## Clarifications

### Session 2026-02-28

- Q: Preference for `global.json` SDK pinning strategy? → A: C — Use floating/latest (no pin). CI must ensure the expected SDK is installed and emit the resolved SDK version in logs for reproducibility.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build & Tests (Priority: P1)

Developers and CI need the repository to build and all unit tests to pass when using the .NET 10 SDK.

**Why this priority**: Ensures basic correctness and determinism before changing runtime/deployment artifacts.

**Independent Test**: Run `dotnet build EmailNotionSync/EmailNotionSync.sln` and `dotnet test EmailNotionSync/EmailNotionSync.sln` under .NET 10 SDK.

### User Story 2 - Containers & Local Integration (Priority: P2)

Container images should use .NET 10 base images and local services must start and respond to basic health checks.

**Independent Test**: Build each Dockerfile and run smoke checks against `/health` endpoints.

### User Story 3 - CI & Deployment (Priority: P3)

CI workflows must install the .NET 10 SDK, build, test, and publish artifacts/images compatible with deployment targets (Function App staging slot, Container Apps).

**Independent Test**: Run CI workflow or emulate locally and verify images are published and a staging deployment completes health checks.

## Edge Cases

- Azure Functions runtime incompatibility or missing support for `net10.0` in the targeted deployment platform.
- Third-party NuGet packages that are not compatible with .NET 10.
- CI runners missing new SDK or caching causing builds to restore outdated assets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All projects MUST target `net10.0` or document why a project remains on an earlier TFM.
- **FR-002**: `global.json` (if present) MAY leave the SDK floating to the latest .NET 10 release (no pin). When floating is used, CI MUST ensure the expected SDK is installed and record the resolved SDK version in build logs to aid reproducibility.
- **FR-003**: Dockerfiles MUST use official .NET 10 images for build/runtime stages.
- **FR-004**: CI workflows MUST be updated to install/use `.NET 10` and any cache keys referencing SDK version MUST be updated.
- **FR-005**: Health endpoints and OpenTelemetry spans MUST remain functional after migration.

### Key Entities

- Not applicable (repository/tooling migration).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dotnet build` on the solution completes with exit code 0 under .NET 10.
- **SC-002**: All unit tests pass (`dotnet test` exit code 0) on .NET 10.
- **SC-003**: Docker images build using .NET 10 base images and service health checks return healthy in smoke runs.
- **SC-004**: CI workflows succeed on feature branch using .NET 10 and publish test images.
