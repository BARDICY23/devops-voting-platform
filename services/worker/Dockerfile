FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app

COPY --from=build /app .

# aspnet image user is UID 64198 → use numeric UID explicitly
USER 64198

CMD ["dotnet", "Worker.dll"]

