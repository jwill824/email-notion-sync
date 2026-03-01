---
description: "Task list for upgrading repository from .NET 9 to .NET 10"
---

# Tasks: Upgrade to .NET 10

**Input**: Repository source in repository root
**Prerequisites**: Backup current state, ensure working CI baseline

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create feature branch for upgrade: `feat/001-upgrade-dotnet10` (path: /)
- [ ] T002 [P] Run an initial scan for `TargetFramework` and `global.json` occurrences: repository root (`.`)
- [ ] T003 [P] Record current `dotnet --info` output and CI baseline logs: repository root (`.`)

---

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 Update or create `global.json` to pin SDK to a known 10.0.x version (file: global.json)
- [ ] T005 [P] Update `EmailNotionSync/EmailNotionSync.AppHost/EmailNotionSync.AppHost.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.AppHost/EmailNotionSync.AppHost.csproj)
- [ ] T006 [P] Update `EmailNotionSync/EmailNotionSync.FunctionApp/EmailNotionSync.FunctionApp.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.FunctionApp/EmailNotionSync.FunctionApp.csproj)
- [ ] T007 [P] Update `EmailNotionSync/EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj)
- [ ] T008 [P] Update `EmailNotionSync/EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj)
- [ ] T009 [P] Update `EmailNotionSync/EmailNotionSync.ServiceDefaults/EmailNotionSync.ServiceDefaults.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.ServiceDefaults/EmailNotionSync.ServiceDefaults.csproj)
- [ ] T010 [P] Update `EmailNotionSync/EmailNotionSync.Tests/EmailNotionSync.Tests.csproj` TargetFramework to `net10.0` (file: EmailNotionSync/EmailNotionSync.Tests/EmailNotionSync.Tests.csproj)
- [ ] T011 [P] Search for other `.csproj` files and update their `TargetFramework` to `net10.0` (path: EmailNotionSync/**/**/*.csproj)
- [ ] T012 Update `Directory.Build.props` or other shared MSBuild files if they pin framework or language version (path: repository root or EmailNotionSync/**/Directory.Build.props)

**Checkpoint**: All project files target `net10.0` and `global.json` pins SDK to a 10.x SDK.

---

## Phase 3: User Story 1 - Build & Unit Tests (Priority: P1) 🎯 MVP

**Goal**: All projects build and unit tests pass under .NET 10 locally.

**Independent Test**: Running `dotnet build EmailNotionSync/EmailNotionSync.sln` and `dotnet test EmailNotionSync/EmailNotionSync.sln` completes successfully on a machine with .NET 10 SDK.

- [ ] T013 [US1] Update any direct `LangVersion` or `ImplicitUsings` settings needed in `*.csproj` files (path: EmailNotionSync/**/*.csproj)
- [ ] T014 [US1] Restore NuGet packages using .NET 10 SDK: run in repository root (`dotnet restore EmailNotionSync/EmailNotionSync.sln`)
- [ ] T015 [US1] Build solution: `dotnet build EmailNotionSync/EmailNotionSync.sln` (path: EmailNotionSync/EmailNotionSync.sln)
- [ ] T016 [US1] Run unit tests: `dotnet test EmailNotionSync/EmailNotionSync.sln` and fix test failures (path: EmailNotionSync/EmailNotionSync.sln)
- [ ] T017 [US1] Address any API/compatibility regressions (update code or package refs) and record changes in PR description (files: src files in EmailNotionSync/**)

**Checkpoint**: Solution builds and unit tests pass under .NET 10.

---

## Phase 4: User Story 2 - Containers & Local Integration (Priority: P2)

**Goal**: Dockerfiles and local container builds use .NET 10 base images and run services locally.

**Independent Test**: Build each container and run a quick smoke test against the service endpoints.

- [ ] T018 [US2] Update `EmailNotionSync/EmailNotionSync.GmailApi/Dockerfile` to use `mcr.microsoft.com/dotnet/asp:10.0` runtime and `mcr.microsoft.com/dotnet/sdk:10.0` for build stage (file: EmailNotionSync/EmailNotionSync.GmailApi/Dockerfile)
- [ ] T019 [US2] Update `EmailNotionSync/EmailNotionSync.NotionApi/Dockerfile` to use .NET 10 images (file: EmailNotionSync/EmailNotionSync.NotionApi/Dockerfile)
- [ ] T020 [US2] Update any Dockerfiles used by other projects (path: EmailNotionSync/**/Dockerfile)
- [ ] T021 [US2] Build containers locally and tag as `ghcr.io/<owner>/...:dotnet10-test` (run from repository root, path: EmailNotionSync/**/Dockerfile)
- [ ] T022 [US2] Run the Function host and APIs locally and perform smoke checks (FunctionApp: run via `func host start` in `EmailNotionSync/EmailNotionSync.FunctionApp/bin/Debug/net10.0`)

**Checkpoint**: Containers build with .NET 10 base images and services start locally for smoke testing.

---

## Phase 5: User Story 3 - CI and Deployment (Priority: P3)

**Goal**: CI pipelines use .NET 10 SDK; container images built and published with .NET 10; deploy flows updated if they reference SDK versions.

**Independent Test**: Run CI workflow on a feature branch or emulate CI locally to verify builds and image publish steps complete with .NET 10.

- [ ] T023 [US3] Update GitHub Actions workflows to use `actions/setup-dotnet` with `dotnet-version: '10.0.x'` (files: .github/workflows/**)
- [ ] T024 [US3] Update any pipeline tasks that reference `dotnet` Docker images to use .NET 10 (files: .github/workflows/** and EmailNotionSync/Terraform where relevant)
- [ ] T025 [US3] Update CI caching keys if they include SDK version (files: .github/workflows/**)
- [ ] T026 [US3] Run CI on feature branch and resolve any infra-only failures (path: .github/workflows/**)
- [ ] T027 [US3] Update release notes and deployment instructions (file: README.md)

**Checkpoint**: CI builds and publishes artifacts/images using .NET 10 successfully.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T028 [P] Update documentation in `README.md` to note .NET 10 requirement (file: README.md)
- [ ] T029 [P] Update `Dockerfile` image tags and push a test image to GHCR (path: EmailNotionSync/**/Dockerfile)
- [ ] T030 [P] Add migration notes in PR and link to `CONSTITUTION` changes (files: .specify/memory/constitution.md, PR description)
- [ ] T031 [P] Verify health endpoints and OpenTelemetry spans still work under net10.0 (files: EmailNotionSync/** source)

---

## Dependencies & Execution Order

- **Setup (Phase 1)**: T001-T003 - can run immediately; T002 and T003 are parallelizable.
- **Foundational (Phase 2)**: Blocks user story development until T011 and T012 complete.
- **User Story 1 (P1)**: Starts after Foundational; build & tests must pass before US2 and US3 proceed to deployment.
- **User Story 2 (P2)**: Can proceed in parallel after Foundational; depends on US1 for compatibility fixes.
- **User Story 3 (P3)**: Depends on successful builds and container images from US1/US2.

## Parallel Execution Examples

- While preserving safety, you can run the following in parallel:
  - T005, T006, T007, T008, T009, T010 (update individual `.csproj` files)
  - T018, T019, T020 (update Dockerfiles)
  - T023, T024, T025 (update CI workflows)

## Implementation Strategy

- MVP: Complete Phase 1 + Phase 2 + Phase 3 (US1: build & test). Stop and validate that solution builds and unit tests pass. Ship this as the minimal safe migration.
- Incremental delivery: After MVP, update Dockerfiles and CI (US2 & US3). Keep changes small and documented.

---

**Files changed by tasks (expected):**

- `global.json` (if present)
- `EmailNotionSync/**/*.csproj`
- `EmailNotionSync/**/*.Dockerfile`
- `.github/workflows/**/*.yml`
- `README.md`

