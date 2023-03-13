param prefix string
param region string
param infraRgName string

// reference name
var logAnalyticsName = '${prefix}-laws'
var acrName = replace('${prefix}-acr', '-', '')

// resource names
var appInsightsName = '${aksName}-ai'

var aksName = '${prefix}-aks'
var k8sver = '1.26.0'
var systemNodePool = {
  name: 'nodepool1'
  mode: 'System'
  type: 'VirtualMachineScaleSets'
  osType: 'Linux'
  osSKU: 'Ubuntu'
  osDiskSizeGB: 64
  osDiskType: 'ManagedDisk' // 'Ephemeral'
  vmSize: 'Standard_D4s_v4'
  count: 3
  kubeletDiskType: 'OS'
  vnetSubnetID: vnet::nodepoolSubnet.id
  maxPods: 32
  availabilityZones: ['1', '2', '3']
  enableAutoScaling: true
  minCount: 3
  maxCount: 10
}

var vnetName = '${aksName}-vnet'
var vnetRange = '10.178.0.0/16'
var defaultSubnetName = 'default'
var defaultSubnetRange = '10.178.192.0/24'
var nodepoolSubnetName = 'myAksSubnet'
var nodepoolSubnetRange = '10.178.0.0/18'
var aksServiceCidr = '10.0.0.0/24'
var aksDnsServiceIp = '10.0.0.4'
var aksDockerBridgeCidr = '172.17.0.1/16'

var aksUamiName = '${aksName}-cluster-uami'
var aksKubeletUamiName = '${aksName}-kubelet-uami'
var akvName = '${aksName}-kv'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(infraRgName)
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: acrName
  scope: resourceGroup(infraRgName)
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: region
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource clusterIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: aksUamiName
  location: region
}

resource kubeleteIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: aksKubeletUamiName
  location: region
}

resource managedIdOperator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'f1a07417-d97a-45cb-824c-7a7467783830'
}

resource assignmentManagedIdOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, resourceGroup().name, kubeleteIdentity.id, clusterIdentity.id)
  scope: kubeleteIdentity
  properties: {
    principalId: clusterIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: managedIdOperator.id
  }
}

module acrAssign './acrPullAssign.bicep' = {
  scope: resourceGroup(infraRgName)
  name: 'acrAssign'
  params: {
    kubeleteId: kubeleteIdentity.properties.principalId
    acrName: acr.name
  }
}

resource defaultNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-${defaultSubnetName}-nsg'
  location: region
}

resource nodepoolNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-${nodepoolSubnetName}-nsg'
  location: region
}

resource allowInternetInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2022-05-01' = {
  parent: nodepoolNsg
  name: 'AllowHttpFromInternet'
  properties: {
    access: 'Allow'
    direction: 'Inbound'
    priority: 1000
    protocol: '*'
    sourceAddressPrefix: 'Internet'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRanges: [ '80', '443' ]
  }
}

//vnet
resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetRange ]
    }
  }

  resource defaultSubnet 'subnets' = {
    name: defaultSubnetName
    properties: {
      addressPrefix: defaultSubnetRange
      networkSecurityGroup: { id: defaultNsg.id }
    }
  }

  resource nodepoolSubnet 'subnets' = {
    name: nodepoolSubnetName
    properties: {
      addressPrefix: nodepoolSubnetRange
      networkSecurityGroup: { id: nodepoolNsg.id }
    }
  }
}

resource networkContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4d97b98b-1d4f-4787-a291-c67834d212e7'
}

resource assignmentNetworkContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, resourceGroup().name, vnet.name, vnet::nodepoolSubnet.name, clusterIdentity.id)
  scope: vnet::nodepoolSubnet
  properties: {
    principalId: clusterIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: networkContributor.id
  }
}

resource akv 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: akvName
  location: region
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableSoftDelete: false
    publicNetworkAccess: 'Enabled'
    enabledForDeployment: true
    accessPolicies: [
      {
        tenantId: kubeleteIdentity.properties.tenantId
        objectId: kubeleteIdentity.properties.principalId
        permissions: {
          keys:['get']
          secrets:['get']
          certificates:['get']
        }
      }
    ]
  }

  resource aiconstr 'secrets' = {
    name: 'appInsightConnectionString'
    properties:{
      value: appinsights.properties.ConnectionString
    }
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-11-01' = {
  name: aksName
  location: region
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities:{
      '${clusterIdentity.id}' : {}
    }
  }
  
  properties: {
    kubernetesVersion: k8sver
    dnsPrefix: uniqueString(subscription().subscriptionId, resourceGroup().id, aksName)
    agentPoolProfiles: [
      systemNodePool
    ]
    servicePrincipalProfile:{
      clientId: 'msi'
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: aksServiceCidr
      dnsServiceIP: aksDnsServiceIp
      dockerBridgeCidr: aksDockerBridgeCidr
    }
    identityProfile: {
      kubeletidentity:{
        resourceId: kubeleteIdentity.id
      }
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
          useAADAuth: 'false'
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'false'
          rotationPollInterval: '2m'
        }
      }

    }
    
  }
}

