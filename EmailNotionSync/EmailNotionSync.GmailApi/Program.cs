using EmailNotionSync.ServiceDefaults;
using EmailNotionSync.GmailApi;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults & Aspire client integrations.
builder.AddServiceDefaults();


// Add GmailService to DI
builder.Services.AddSingleton<GmailService>();

// Add ProblemDetails for exception handling
builder.Services.AddProblemDetails();

// Add OpenAPI for discoverability
builder.Services.AddOpenApi();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Minimal endpoint for Aspire health/discovery
app.MapGet("/health", () => Results.Ok("Healthy"));

// Example endpoint for pulling emails (stub)
app.MapGet("/emails", (GmailService gmail) =>
{
    gmail.PullEmails();
    return Results.Ok("Pulled emails (stub)");
});

app.MapDefaultEndpoints();

app.Run();