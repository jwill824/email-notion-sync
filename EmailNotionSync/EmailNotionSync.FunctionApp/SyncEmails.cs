using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace EmailNotionSync.FunctionApp;

public class SyncEmails
{
    private readonly ILogger _logger;

    public SyncEmails(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<SyncEmails>();
    }

    [Function("TimerTriggerSyncEmails")]
    public void Run([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer)
    {
        _logger.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
        // TODO: Call Gmail API, categorize, and store in Notion
    }
}
