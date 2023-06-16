param prefix string 
param region string 
param appInsightName string
param logAnalyticsName string

var apimName = '${prefix}-apim'

resource apimanagement 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apimName
  location: region
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherName: prefix
    publisherEmail: '${prefix}@${prefix}.local'

    virtualNetworkType: 'None'
  }
}

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
}

resource ai 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightName
}


resource aiLogger 'Microsoft.ApiManagement/service/loggers@2022-04-01-preview' = {
  name: '${appInsightName}-logger'
  parent: apimanagement
  properties: {
    loggerType: 'applicationInsights'
    resourceId: ai.id
    credentials: {
      instrumentationKey: ai.properties.InstrumentationKey
    }
  }
}

resource ailogging 'Microsoft.ApiManagement/service/diagnostics@2022-04-01-preview' = {
  name: 'applicationinsights'
  parent: apimanagement
  properties: {
    loggerId: aiLogger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    verbosity: 'verbose'
  }
}

resource apimDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${apimanagement.name}-diag'
  scope: apimanagement
  properties: {
    workspaceId: laws.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
         category: 'AllMetrics'
         enabled: true
      }
    ]
  }

}
