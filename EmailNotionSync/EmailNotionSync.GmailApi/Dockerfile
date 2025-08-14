# GmailApi Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["EmailNotionSync.GmailApi.csproj", "./"]
RUN dotnet restore "./EmailNotionSync.GmailApi.csproj"
COPY . .
RUN dotnet publish "./EmailNotionSync.GmailApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EmailNotionSync.GmailApi.dll"]
