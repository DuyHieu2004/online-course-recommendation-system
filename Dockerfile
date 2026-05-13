# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/out .

# Expose port
EXPOSE 5128
ENV ASPNETCORE_URLS=http://+:5128
ENV ASPNETCORE_ENVIRONMENT=Docker

ENTRYPOINT ["dotnet", "online-course-recommendation-system.dll"]
