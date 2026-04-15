# ---------- build stage ----------
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

COPY *.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app

# ---------- runtime stage ----------
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app

COPY --from=build /app .

# Install procps to provide pgrep for liveness/readiness probes
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

# aspnet image uses UID 64198 → PSA compliant
USER 64198

CMD ["dotnet", "Worker.dll"]

