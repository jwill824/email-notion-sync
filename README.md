# email-notion-sync

Syncs Gmail emails into a Notion database.

## Local Development

**Prerequisites**: .NET 9 SDK, Docker Desktop, [Azure Functions Core Tools](https://learn.microsoft.com/azure/azure-functions/functions-run-local)

```bash
# Build
dotnet build EmailNotionSync/EmailNotionSync.sln

# Run tests
dotnet test EmailNotionSync/EmailNotionSync.sln

# Run all services locally via Aspire (starts AppHost + service discovery)
dotnet run --project EmailNotionSync/EmailNotionSync.AppHost
```

For the Function App specifically, use the VS Code tasks `build (functions)` + `func host start`. Azurite must be running locally for `AzureWebJobsStorage`.

## Infrastructure

Azure resources are managed via Terraform in `EmailNotionSync.Terraform/azure/`, applied through an HCP Terraform workspace (`Thingstead / email-notion-sync-azure`). Applies run automatically on push to `main`.

For troubleshooting `terraform apply` failures (permission errors, quota issues, attribute mismatches), see the runbook:
[`specs/002-fix-azuread-permissions/runbook.md`](specs/002-fix-azuread-permissions/runbook.md)
