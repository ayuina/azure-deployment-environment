FROM mcr.microsoft.com/dotnet/aspnet:7.0 as base
WORKDIR /app
EXPOSE 5000

ENV ASPNETCORE_URLS=http://+:5000

###
FROM mcr.microsoft.com/dotnet/sdk:7.0 as builder
WORKDIR /src
COPY webapp1.csproj .
RUN dotnet restore webapp1.csproj
COPY . .
RUN dotnet publish webapp1.csproj -o /app/publish 

###
FROM base as final
WORKDIR /app
COPY --from=builder /app/publish .
ENTRYPOINT [ "dotnet", "webapp1.dll" ]