param prefix string = 'ayuina0621d'
param aoaiRegion string = 'uksouth'
param integSubnetName string = 'subnet1'

var infraRegion = 'japaneast'
var infraRg = 'depenv-japaneast-rg'
var infraVnet = 'depenv-japaneast-vnet'
var pesubnetName = 'pesubnet'

var aoaiName = '${prefix}-${aoaiRegion}-aoai'
var aoaiZoneName = 'privatelink.openai.azure.com'
var aoaiPeName = '${aoaiName}-pe'

var appSvcName = '${prefix}-web'
var appSvcPeName = '${appSvcName}-pe'
var appSvcPlanName = '${appSvcName}-asp'
var appsvcZoneName = 'privatelink.azurewebsites.net'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = { 
  name: infraVnet
  scope: resourceGroup(infraRg)

  resource pesubnet 'subnets' existing = {
    name: pesubnetName
  }

  resource  integSubnet 'subnets' existing = {
    name: integSubnetName
  }
}


resource aoaiPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: aoaiZoneName
  scope: resourceGroup(infraRg)
}

resource appsvcPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: appsvcZoneName
  scope: resourceGroup(infraRg)
}


resource aoai 'Microsoft.CognitiveServices/accounts@2023-06-01-preview' = {
  name: aoaiName
  location: aoaiRegion
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: aoaiName
    publicNetworkAccess: 'Disabled'
  }
}

resource aoaipe 'Microsoft.Network/privateEndpoints@2023-02-01' = {
  name: aoaiPeName
  location: infraRegion
  properties: {
    subnet: {
      id: vnet::pesubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${aoaiPeName}-plsc'
        properties: {
          privateLinkServiceId: aoai.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }

  resource pdzGroup 'privateDnsZoneGroups' = {
    name: 'pdzGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'pdzConfig'
          properties: {
            privateDnsZoneId: aoaiPrivateZone.id
          }
        }
      ]
    }
  }
}

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appSvcPlanName
  location: infraRegion
  sku: {
    name: 'S1'
    capacity: 1
  }
}

resource web 'Microsoft.Web/sites@2022-03-01' = {
  name: appSvcName
  location: infraRegion
  properties:{
    serverFarmId: asp.id
    clientAffinityEnabled: false
    virtualNetworkSubnetId: vnet::integSubnet.id
    siteConfig: {
      netFrameworkVersion: 'v7.0'
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
      vnetRouteAllEnabled: true
      publicNetworkAccess: 'Disabled'
    }
  }
}

resource metadata 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'metadata'
  parent: web
  properties: {
    CURRENT_STACK: 'dotnet'
  }
}


resource appsvcpe 'Microsoft.Network/privateEndpoints@2023-02-01' = {
  name: appSvcPeName
  location: infraRegion
  properties: {
    subnet: {
      id: vnet::pesubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${appSvcPeName}-plsc'
        properties: {
          privateLinkServiceId: web.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }

  resource pdzGroup 'privateDnsZoneGroups' = {
    name: 'pdzGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'pdzConfig'
          properties: {
            privateDnsZoneId: appsvcPrivateZone.id
          }
        }
      ]
    }
  }
}
