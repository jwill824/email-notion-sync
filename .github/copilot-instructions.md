# Copilot Instructions

## Architecture

This is a **early-stage** .NET 9 / .NET Aspire application that syncs Gmail emails into a Notion database.

### Service layout

- **`EmailNotionSync.AppHost`** — .NET Aspire orchestrator. Wires together all services with service discovery and references. This is the entry point for local development.
- **`EmailNotionSync.FunctionApp`** — Azure Functions v4 (isolated worker). Contains a timer-triggered function (`TimerTriggerSyncEmails`) that fires every minute and will eventually call GmailApi and NotionApi.
- **`EmailNotionSync.GmailApi`** — Minimal ASP.NET Core API (port 5001 locally). Exposes `GET /emails` backed by `GmailService`. Currently a stub.
- **`EmailNotionSync.NotionApi`** — Minimal ASP.NET Core API (port 5002 locally). Exposes `POST /emails` backed by `NotionService`. Currently a stub.
- **`EmailNotionSync.ServiceDefaults`** — Shared Aspire defaults (OpenTelemetry, health checks, service discovery, HTTP resilience). Must be referenced by all service projects and called via `builder.AddServiceDefaults()`.
- **`EmailNotionSync.Tests`** — xUnit v3 integration tests using `Aspire.Hosting.Testing`, referencing AppHost.

### Infrastructure (Terraform)

- `EmailNotionSync.Terraform/azure/` — Azure infrastructure: Linux Function App (+ staging slot), Azure Container Apps for GmailApi and NotionApi, Key Vault, Application Insights, OIDC setup for GitHub Actions.
- `EmailNotionSync.Terraform/github/` — GitHub-side Terraform config.
- Managed via **HCP Terraform** (org: `Thingstead`, workspace: `email-notion-sync-azure`). Run `terraform` commands from within the relevant subdirectory.

## Build, Test, and Run

```bash
# Build solution
dotnet build EmailNotionSync/EmailNotionSync.sln

# Run all tests
dotnet test EmailNotionSync/EmailNotionSync.sln

# Run a single test
dotnet test EmailNotionSync/EmailNotionSync.sln --filter "FullyQualifiedName~<TestName>"

# Run locally via Aspire (starts all services with service discovery)
dotnet run --project EmailNotionSync/EmailNotionSync.AppHost
```

For the Function App specifically, VS Code tasks (`build (functions)` + `func host start`) build and launch it using Azure Functions Core Tools. Azurite must be running locally for `AzureWebJobsStorage`.

## Key Conventions

### ServiceDefaults pattern
Every service project must call `builder.AddServiceDefaults()` in `Program.cs` and `app.MapDefaultEndpoints()` on the built app. This registers health checks at `/health` and `/alive`, OpenTelemetry, and service discovery.

### Health endpoints
`/health` — all checks must pass (readiness). `/alive` — only checks tagged `live` (liveness). Both are only exposed in Development environments.

### Test skipping in CI
Use `[SkipOnCiFact]` (instead of `[Fact]`) for tests that require infrastructure not available in GitHub Actions. It checks for `GITHUB_ACTIONS=true`.

### Docker build context
Dockerfiles for GmailApi and NotionApi use the **repo root** as the build context (not the project directory). The `COPY` instructions reference paths like `EmailNotionSync/EmailNotionSync.GmailApi/...`. This matters when building manually:

```bash
docker build -f EmailNotionSync/EmailNotionSync.GmailApi/Dockerfile .
```

### Container images
Images are published to GHCR: `ghcr.io/<owner>/gmailapi:latest` and `ghcr.io/<owner>/notionapi:latest`.

### Azure auth (GitHub Actions → Azure)
GitHub Actions authenticates to Azure via **OIDC** (no stored credentials). The federated identity is scoped to pushes on `main`. Required secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.

### Secrets management
API keys (`GmailApiKey`, `NotionApiKey`) are stored in Azure Key Vault. Each service's system-assigned managed identity has `Get`/`List` permissions. The HCP Terraform service principal has full `Get`/`Set`/`List`/`Delete` access for provisioning.

### Deployment flow
- **GmailApi / NotionApi**: Build Docker image → push to GHCR → `az containerapp update` with new image.
- **Function App**: `dotnet publish` → zip → deploy to `staging` slot → health check → swap to `production`.
- Deploy workflows trigger on push to `main` with path filters per service.
- Build-and-test workflow runs on all branches **except** `main`.

### Terraform naming
Most Azure resource names are derived from `var.github_repo` (e.g., `${var.github_repo}-rg`, `${var.github_repo}-kv`).
