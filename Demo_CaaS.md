# Container as a Services Demo using IaC

```bash
# environment variables
prefix=yourPrefix
image=webapp1:v1
targetPort=5000

region=japaneast
infrarg=${prefix}-infra-rg
acarg=${prefix}-aca-rg
acirg=${prefix}-aci-rg
```

## Deploy base resources for Container as a Services

```bash
# deploy azure resources
cd ${CODESPACE_VSCODE_FOLDER}/Environments/Container_Infra

az group create -n $infrarg -l $region
az deployment group create -g $infrarg -f ./infra.bicep --parameter prefix=$prefix region=$region
```

## Build and Push Web Application container image

```bash
# test web app
cd ${CODESPACE_VSCODE_FOLDER}/Applications/webapp1

dotnet run
```

```bash
# build container image and test run
docker build -t $image .
docker run -it -p 8888:${targetPort} ${image}
```

```bash
# push image to Azure Container Registry
az acr login -n ${prefix}acr
docker tag ${image} ${prefix}acr.azurecr.io/${image}
docker push ${prefix}acr.azurecr.io/${image}
```

## Deploy Azure Container App and Environment

```bash
# deploy azure resources
cd ${CODESPACE_VSCODE_FOLDER}/Environments/Container_ACA

az group create -g $acarg -l $region
az deployment group create -g $acarg -f ./aca.bicep \
    --parameter prefix=$prefix region=$region infraRgName=$infrarg \
    --parameter containerImage=${prefix}acr.azurecr.io/${image} targetPort=$targetPort
```

## Deploy Azure Container Instance

```bash
# deploy azure resources
cd ${CODESPACE_VSCODE_FOLDER}/Environments/Container_ACI

az group create -g $acirg -l $region
az deployment group create -g $acirg -f ./aci.bicep \
    --parameter prefix=$prefix region=$region infraRgName=$infrarg \
    --parameter containerImage=${prefix}acr.azurecr.io/${image} targetPort=$targetPort
```


