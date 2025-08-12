using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var gmailApi = builder.AddProject<Projects.EmailNotionSync_GmailApi>("gmailapi");
var notionApi = builder.AddProject<Projects.EmailNotionSync_NotionApi>("notionapi");

builder.AddProject<Projects.EmailNotionSync_FunctionApp>("functionapp")
    .WithReference(gmailApi)
    .WithReference(notionApi);

builder.Build().Run();