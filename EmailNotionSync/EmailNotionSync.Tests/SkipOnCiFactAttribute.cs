using System;
using Xunit;

namespace EmailNotionSync.Tests;

public class SkipOnCiFactAttribute : FactAttribute
{
    public SkipOnCiFactAttribute()
    {
        if (Environment.GetEnvironmentVariable("GITHUB_ACTIONS") == "true")
        {
            Skip = "Skipped on CI environment";
        }
    }
}
