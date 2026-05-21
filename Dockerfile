# Sử dụng SDK .NET 9 để build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Copy csproj và restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy toàn bộ code và build
COPY . ./
RUN dotnet publish -c Release -o out

# Sử dụng ASP.NET runtime để chạy
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/out .

# Mở port cho API
EXPOSE 8080
ENTRYPOINT ["dotnet", "online-course-recommendation-system.dll"]