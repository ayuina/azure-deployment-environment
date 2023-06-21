param region string = 'japaneast'

var devboxRg = 'dev-rg'
var devboxVnetName = 'devbox-jpe-vnet'

var vnetName = 'depenv-${region}-vnet'
var vnetRange  = '10.0.0.0/16'
var pesubnetName = 'pesubnet'
var pesubnetRange = '10.0.0.0/24'

var privatelinkZones = [
  'privatelink.openai.azure.com'
  'privatelink.azurewebsites.net'
  'privatelink${environment().suffixes.sqlServerHostname}'
]

resource devboxVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup(devboxRg)
  name: devboxVnetName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetRange
      ]
    }

    subnets: [
      {
        name: pesubnetName
        properties: {
          addressPrefix: pesubnetRange
        }
      }
    ]
  }
}


@batchSize(1)
resource Subnets 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = [for idx in range(128, 32): {
  parent: vnet
  name: 'subnet${idx}'
  properties: {
    addressPrefix: '10.0.${idx}.0/24'
    delegations: [
      {
        name: 'Microsoft.Web/serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
}]

resource privateZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (pdz, idx) in privatelinkZones : {
  name: pdz
  location: 'global'
}]

resource infraZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (pdz, idx) in privatelinkZones : {
  parent: privateZones[idx]
  name: 'infra-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

resource devboxVnetZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (pdz, idx) in privatelinkZones : {
  parent: privateZones[idx]
  name: 'devbox-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: devboxVnet.id
    }
  }
}]
