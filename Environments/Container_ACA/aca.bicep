param prefix string
param region string
param infraRgName string
param containerImage string
param targetPort int

var logAnalyticsName = '${prefix}-laws'
var appInsightsName = '${prefix}-ai'
var uamiName = '${prefix}-uami'
var acrName = replace('${prefix}-acr', '-', '')

var acaenvName = '${prefix}-env'
var acaName = '${prefix}-aca'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(infraRgName)
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup(infraRgName)
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: acrName
  scope: resourceGroup(infraRgName)
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: uamiName
  scope: resourceGroup(infraRgName)
}

resource acaenv 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: acaenvName
  location: region
  sku: {
    name: 'Consumption'
  }
  properties: {
    daprAIConnectionString: appinsights.properties.ConnectionString
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: acaName
  location: region
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: acaenv.id
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: acr.properties.loginServer
          identity: uami.id
        }
      ]
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'http'
      }

    }
    template: {
      containers: [
        {
          name: '${acaName}-container'
          image: containerImage
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
          ]
          resources:{
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}
