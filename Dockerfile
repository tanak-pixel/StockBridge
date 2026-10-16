# Multi-stage Dockerfile for StockBridge

# Stage 1: Build Frontend
FROM node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY src/StockBridge.Web/package*.json ./
RUN npm install
COPY src/StockBridge.Web/ ./
RUN npm run build

# Stage 2: Build Backend
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS backend-build
WORKDIR /app
COPY StockBridge.sln ./
COPY src/StockBridge.Core/*.csproj src/StockBridge.Core/
COPY src/StockBridge.Infrastructure/*.csproj src/StockBridge.Infrastructure/
COPY src/StockBridge.Api/*.csproj src/StockBridge.Api/
COPY tests/StockBridge.Tests/*.csproj tests/StockBridge.Tests/
RUN dotnet restore

COPY src/ src/
COPY tests/ tests/
# Copy frontend build output into wwwroot
COPY --from=frontend-build /app/src/StockBridge.Api/wwwroot /app/src/StockBridge.Api/wwwroot
RUN dotnet publish src/StockBridge.Api/StockBridge.Api.csproj -c Release -o /app/publish

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app
COPY --from=backend-build /app/publish ./
ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000
ENTRYPOINT ["dotnet", "StockBridge.Api.dll"]
