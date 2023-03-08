# Platform as a Services Demo using IaC

```bash
# environment variables
prefix=yourPrefix

region=japaneast
webdbrg=${prefix}-webdb-rg
```

## Deploy Azure App Service and SQL Database

```bash
# deploy azure resources
cd ${CODESPACE_VSCODE_FOLDER}/Environments/WebSql

az group create -n $webdbrg -l $region
az deployment group create -g $webdbrg -f ./main.bicep --parameter prefix=$prefix region=$region
```

## Build and Publish Web Application

```bash
# test web app
cd ${CODESPACE_VSCODE_FOLDER}/Applications/webapp1

dotnet run
```

```bash
# publish and zip package

dotnet publish -o publish
cd publish
zip -r ./publish.zip *
```

```bash
# deploy to web app

webapp=${prefix}-web
az webapp config appsettings set -g $webdbrg -n $webapp --settings WEBSITE_RUN_FROM_PACKAGE=1
az webapp deployment source config-zip -g $webdbrg -n $webapp --src ./publish.zip
```

## Deploy Azure Function App

```
TBD
```

## Build and publish function app

```
TBD
```
