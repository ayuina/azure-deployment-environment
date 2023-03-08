param prefix string
param region string

var strAccName = replace('${prefix}-str', '-', '')
var logAnalyticsName = '${prefix}-laws'
var uamiName = '${prefix}-uami' 
var acrName = replace('${prefix}-acr', '-', '')

var diagRetention = {
  days : 0
  enabled: false
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: strAccName
  location: region
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}


resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: region
  properties:{
    sku:{
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acrName
  location: region
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: uamiName
  location: region
}

resource acrPull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource assign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, acrPull.id, uami.id)
  properties: {
    roleDefinitionId: acrPull.id
    principalType: 'ServicePrincipal'
    principalId: uami.properties.principalId
  }
}

resource acrdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: acr
  name: '${acrName}-diag'
  properties: {
    storageAccountId: storage.id
    workspaceId: logAnalytics.id
    logs :[
      {
        category: null
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: diagRetention
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: diagRetention
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: diagRetention
      }
    ]

  }
}
