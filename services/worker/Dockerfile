ARG BUILD_VERSION=unknown
ARG GIT_COMMIT_SHA=unknown
ARG REPO_URL=https://github.com/BARDICY23/devops-voting-app

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copy project and restore
COPY *.csproj ./
RUN dotnet restore

# Copy remaining files and publish
COPY . ./
RUN dotnet publish -c Release -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app .

# Use non-root user provided by runtime if desired (optional)
# For .NET images you can create a user if you want extra safety;
# leaving as default runtime user is fine for local/dev test.
USER appuser

LABEL org.opencontainers.image.title="Voting App Worker Service (.NET)" \
      org.opencontainers.image.version=$BUILD_VERSION \
      org.opencontainers.image.revision=$GIT_COMMIT_SHA \
      org.opencontainers.image.source=$REPO_URL

CMD ["dotnet", "Worker.dll"]
