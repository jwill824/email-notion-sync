# NotionApi Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files first (restore only this project)
COPY EmailNotionSync/EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj ./EmailNotionSync.NotionApi/
COPY EmailNotionSync/EmailNotionSync.ServiceDefaults/EmailNotionSync.ServiceDefaults.csproj ./EmailNotionSync.ServiceDefaults/

RUN dotnet restore "./EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj"

# Copy full source for the projects we need
COPY EmailNotionSync/EmailNotionSync.NotionApi/. ./EmailNotionSync.NotionApi/
COPY EmailNotionSync/EmailNotionSync.ServiceDefaults/. ./EmailNotionSync.ServiceDefaults/

RUN dotnet publish "./EmailNotionSync.NotionApi/EmailNotionSync.NotionApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EmailNotionSync.NotionApi.dll"]
