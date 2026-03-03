---
description: "Structured tasks for upgrading repository from .NET 9 to .NET 10"
---

# Tasks: Upgrade to .NET 10

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create feature branch `001-upgrade-dotnet10` (path: /)
- [ ] T002 [P] Scan repository for `TargetFramework` and `global.json` occurrences (path: .)
- [ ] T003 Record current `dotnet --info` output and CI baseline logs (path: repository root)

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 Create or update `global.json` policy (floating/latest) and add CI step to log resolved SDK (file: global.json)
- [ ] T005 [P] Update `EmailNotionSync.AppHost` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.AppHost/EmailNotionSync.AppHost.csproj)
- [ ] T006 [P] Update `EmailNotionSync.FunctionApp` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.FunctionApp/EmailNotionSync.FunctionApp.csproj)
- [ ] T007 [P] Update `EmailNotionSync.GmailApi` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj)
- [ ] T008 [P] Update `EmailNotionSync.NotionApi` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj)
- [ ] T009 [P] Update `EmailNotionSync.ServiceDefaults` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.ServiceDefaults/EmailNotionSync.ServiceDefaults.csproj)
- [ ] T010 [P] Update `EmailNotionSync.Tests` project TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.Tests/EmailNotionSync.Tests.csproj)
- [ ] T011 [P] Find and update any remaining `.csproj` files to `net10.0` (path: EmailNotionSync/**/**/*.csproj)
- [ ] T012 Update shared MSBuild files (e.g., `Directory.Build.props`) if they pin frameworks or language versions (path: repository root or EmailNotionSync/**/Directory.Build.props)

## Phase 3: User Story 1 - Build & Unit Tests (Priority: P1)

- [ ] T013 [US1] Review and update `LangVersion` / `ImplicitUsings` where required (path: EmailNotionSync/**/*.csproj)
- [ ] T014 [US1] Restore NuGet packages with .NET 10 SDK (command: `dotnet restore EmailNotionSync/EmailNotionSync.sln`, path: repository root)
- [ ] T015 [US1] Build solution under .NET 10 (command: `dotnet build EmailNotionSync/EmailNotionSync.sln`, path: EmailNotionSync/EmailNotionSync.sln)
- [ ] T016 [US1] Run unit tests and fix failures (command: `dotnet test EmailNotionSync/EmailNotionSync.sln`, path: EmailNotionSync/EmailNotionSync.sln)
- [ ] T017 [US1] Record and implement compatibility fixes for any API changes; update PR description with changes (files: EmailNotionSync/**)

## Phase 4: User Story 2 - Containers & Local Integration (Priority: P2)

- [ ] T018 [US2] Update GmailApi `Dockerfile` to use .NET 10 SDK/runtime images (file: EmailNotionSync/EmailNotionSync.GmailApi/Dockerfile)
- [ ] T019 [US2] Update NotionApi `Dockerfile` to use .NET 10 SDK/runtime images (file: EmailNotionSync/EmailNotionSync.NotionApi/Dockerfile)
- [ ] T020 [US2] Update any other Dockerfiles to .NET 10 images (path: EmailNotionSync/**/Dockerfile)
- [ ] T021 [US2] Build containers locally and tag `ghcr.io/<owner>/<service>:dotnet10-test` (command: `docker build`, path: EmailNotionSync/**)
- [ ] T022 [US2] Run Function host and APIs locally for smoke tests (command: `func host start` and health checks, path: EmailNotionSync/EmailNotionSync.FunctionApp/bin/Debug/net10.0)

## Phase 5: User Story 3 - CI and Deployment (Priority: P3)

- [ ] T023 [US3] Update GitHub Actions workflows to install/use .NET 10 and log resolved SDK version (path: .github/workflows/**)
- [ ] T024 [US3] Update CI tasks or docker images that reference .NET SDK images to 10.x (path: .github/workflows/** and EmailNotionSync/Terraform where applicable)
- [ ] T025 [US3] Update CI cache keys if they include SDK version (path: .github/workflows/**)
- [ ] T026 [US3] Run CI on `001-upgrade-dotnet10` branch and resolve infra failures (path: .github/workflows/**)
- [ ] T027 [US3] Update release notes and README with .NET 10 requirement (file: README.md)

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T028 [P] Add migration notes in PR linking to `CONSTITUTION` changes and spec (files: .specify/memory/constitution.md, specs/001-upgrade-dotnet10/spec.md)
- [ ] T029 [P] Push test images to GHCR and validate registry authentication (path: ghcr.io)
- [ ] T030 [P] Verify health endpoints and OpenTelemetry traces operate under `net10.0` (files: EmailNotionSync/** source)
- [ ] T031 [P] Clean up temporary test tags, update CI badges if present (files: README.md, .github/workflows/**)

## Dependencies & Execution Order

- Setup (T001-T003) → Foundational (T004-T012) → US1 (T013-T017) → US2 (T018-T022) → US3 (T023-T027) → Final (T028-T031)
- Many file updates (T005-T011, T018-T020, T023-T025) are parallelizable and safe to run concurrently when coordinated.

## Parallel Examples

- Run T005,T006,T007,T008,T009,T010,T011 in parallel (each edits different `.csproj` files).
- Run T018,T019,T020 in parallel (each edits different `Dockerfile`s).
- Run T023,T024,T025 in parallel (CI workflow edits).

## Implementation Notes

- Start with T001-T003 to capture baseline and avoid surprises.
- Stop after T016/T017 to validate builds/tests before changing deployment artifacts.
- Keep PRs small and document all compatibility changes and resolved issues.

