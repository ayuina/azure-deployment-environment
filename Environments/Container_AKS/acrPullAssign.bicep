param kubeleteId string
param acrName string

resource acrPull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource assignmentAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, resourceGroup().name, kubeleteId)
  scope: acr
  properties: {
    principalId: kubeleteId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPull.id
  }
}
