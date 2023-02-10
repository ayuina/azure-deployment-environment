param prefix string = 'ayuina'
param region string = 'westus3'

var lawsName = '${prefix}-laws'
var appInsName = '${prefix}-ai'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawsName
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

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsName
  location: region
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module apim './apim.bicep' = {
  name: 'apim'
  params:{
    prefix: prefix
    region: region
    appInsightName: appinsights.name
    logAnalyticsName: logAnalytics.name
  }
}

module webapi 'webdb.bicep' = {
  name: 'webdb'
  params:{
    prefix: prefix
    region: region
    appInsightName: appinsights.name
    logAnalyticsName: logAnalytics.name
  }
}
