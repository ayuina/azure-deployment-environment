param prefix string
param region string
param infraRgName string
param containerImage string
param targetPort int

var logAnalyticsName = '${prefix}-laws'
var appInsightsName = '${prefix}-ai'
var uamiName = '${prefix}-uami'
var acrName = replace('${prefix}-acr', '-', '')

var aciName = '${prefix}-aci'

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

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = {
  name: aciName
  location: region
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities:{
      '${uami.id}': {}
    }
  }
  properties: {
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    containers: [
      {
        name: '${aciName}-container'
        properties: {
          image: containerImage
          ports: [
            {
              port: targetPort
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: acr.properties.loginServer
        identity: uami.id
      }
    ]
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: targetPort
          protocol: 'TCP'
        }
      ]
    }
  }
}
