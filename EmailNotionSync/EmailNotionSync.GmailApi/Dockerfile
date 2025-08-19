# GmailApi Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files first (restore only this project)
COPY EmailNotionSync/EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj ./EmailNotionSync.GmailApi/
COPY EmailNotionSync/EmailNotionSync.ServiceDefaults/EmailNotionSync.ServiceDefaults.csproj ./EmailNotionSync.ServiceDefaults/

RUN dotnet restore "./EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj"

# Copy full source for the projects we need
COPY EmailNotionSync/EmailNotionSync.GmailApi/. ./EmailNotionSync.GmailApi/
COPY EmailNotionSync/EmailNotionSync.ServiceDefaults/. ./EmailNotionSync.ServiceDefaults/

RUN dotnet publish "EmailNotionSync/EmailNotionSync.GmailApi/EmailNotionSync.GmailApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EmailNotionSync.GmailApi.dll"]