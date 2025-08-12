using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var gmailApi = builder.AddProject<Projects.EmailNotionSync_GmailApi>("gmailapi");
var notionApi = builder.AddProject<Projects.EmailNotionSync_NotionApi>("notionapi");

builder.AddProject<Projects.EmailNotionSync_FunctionApp>("functionapp")
    .WithReference(gmailApi)
    .WithReference(notionApi)
    .WithEnvironment("ASPNETCORE_URLS", "http://localhost:18888")
    .WithEnvironment("ASPIRE_DASHBOARD_OTLP_HTTP_ENDPOINT_URL", "http://localhost:4318")
    .WithEnvironment("ASPIRE_ALLOW_UNSECURED_TRANSPORT", "true");

builder.Build().Run();