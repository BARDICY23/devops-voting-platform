FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app

COPY --from=build /app .

# aspnet image already runs as non-root user
USER app

CMD ["dotnet", "Worker.dll"]

