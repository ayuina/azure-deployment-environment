param prefix string = 'devbox0221'
param region string = 'japaneast'
param devcenterName string = 'ainaba-dev-center'
param devcenterRg string = 'dev-rg'

var vnetName = '${prefix}-${region}-vnet'
var devboxSubnetName = 'devbox-subnet'
var vnetDevBoxConnectionName = '${vnetName}-connection'
var projectName = 'ayuina-demo'

var appsvcZoneName = 'privatelink.azurewebsites.net'
var blobZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var queueZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var tableZoneName = 'privatelink.table.${environment().suffixes.storage}'
var fileZoneName = 'privatelink.file.${environment().suffixes.storage}'


resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: region

  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.128.0/24'
      ]
    }
  }

  resource devboxSubnet 'subnets' = {
    name: devboxSubnetName
    properties: {
      addressPrefix: '192.168.128.0/26'
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

resource blobPrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: blobZoneName 
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'blobZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource queuePrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: queueZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'queueZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource tablePrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: tableZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'tableZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource filePrivateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: fileZoneName
  location: 'global'

  resource zoneLink 'virtualNetworkLinks' = {
    name: 'fileZone-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}


resource vnetcon 'Microsoft.DevCenter/networkConnections@2022-11-11-preview' = {
  name: vnetDevBoxConnectionName
  location: region
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: vnet::devboxSubnet.id
    networkingResourceGroupName: '${resourceGroup().name}-devbox-nic-rg'
  }
}

resource devcenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
  scope: resourceGroup(devcenterRg)
}

// resource devproj 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
//   name: projectName
//   location: region
//   properties: {
//     devCenterId: devcenter.id
//   }

// }
