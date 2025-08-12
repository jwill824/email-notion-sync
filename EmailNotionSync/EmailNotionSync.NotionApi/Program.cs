using EmailNotionSync.ServiceDefaults;
using EmailNotionSync.NotionApi;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults & Aspire client integrations.
builder.AddServiceDefaults();


// Add NotionService to DI
builder.Services.AddSingleton<NotionService>();

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

// Example endpoint for storing an email (stub)
app.MapPost("/emails", (NotionService notion, object email) =>
{
    notion.StoreEmail(email);
    return Results.Ok("Stored email (stub)");
});

app.MapDefaultEndpoints();

app.Run();
