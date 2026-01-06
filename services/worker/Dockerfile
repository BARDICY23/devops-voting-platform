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

# aspnet image uses UID 64198 → PSA compliant
USER 64198

CMD ["dotnet", "Worker.dll"]

