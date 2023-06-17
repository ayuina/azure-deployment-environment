param region string = 'japaneast'

var vnetName = 'depenv-${region}-vnet'
var vnetRange  = '10.0.0.0/16'
var pesubnetName = 'pesubnet'
var pesubnetRange = '10.0.0.0/24'
var subnet1Name = 'subnet1'
var subnet1Range = '10.0.1.0/24'
var subnet2Name = 'subnet2'
var subnet2Range = '10.0.2.0/24'
var subnet3Name = 'subnet3'
var subnet3Range = '10.0.3.0/24'


var aoaiZoneName = 'privatelink.openai.azure.com'
var appsvcZoneName = 'privatelink.azurewebsites.net'
var sqlsvcZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

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
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Range
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Range
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: subnet3Range
        }
      }
    ]
  }
}

resource aoaiPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: aoaiZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'aoaiZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}


resource appsvcPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: appsvcZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'appsvcZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource sqlsvcPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlsvcZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'sqlsvcZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}



