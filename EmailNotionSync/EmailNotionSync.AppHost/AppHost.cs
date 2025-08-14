var builder = DistributedApplication.CreateBuilder(args);

var gmailApi = builder.AddProject<Projects.EmailNotionSync_GmailApi>("gmailapi")
    .WithHttpEndpoint(port: 5001);

var notionApi = builder.AddProject<Projects.EmailNotionSync_NotionApi>("notionapi")
    .WithHttpEndpoint(port: 5002);

builder.AddProject<Projects.EmailNotionSync_FunctionApp>("functionapp")
    .WithReference(gmailApi)
    .WithReference(notionApi);

builder.Build().Run();