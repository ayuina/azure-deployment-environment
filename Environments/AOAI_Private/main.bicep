param prefix string
param aoairegion string
param infraRegion string
param infraRg string
param infraVnet string

var aoaiName = '${prefix}-${aoairegion}-aoai'
var aoaiZoneName = 'privatelink.openai.azure.com'
var aoaiPeName = '${aoaiName}-pe'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = { 
  name: infraVnet
  scope: resourceGroup(infraRg)

  resource pesubnet 'subnets' existing = {
    name: 'pesubnet'
  }
  resource subnnet 'subnets' existing = {
    name: 'subnet1'
  }
}

resource aoaiPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: aoaiZoneName
  scope: resourceGroup(infraRg)
}


resource aoai 'Microsoft.CognitiveServices/accounts@2023-06-01-preview' = {
  name: aoaiName
  location: aoairegion
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

