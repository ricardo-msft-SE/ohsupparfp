targetScope = 'resourceGroup'

@description('Deployment location')
param location string = resourceGroup().location

@description('Azure AI Search service name')
param searchServiceName string

@description('Azure AI Search SKU')
@allowed([
  'basic'
  'standard'
  'standard2'
  'standard3'
])
param searchSku string = 'basic'

@description('Storage account name for PDF source documents')
param storageAccountName string

@description('Blob container name for PDF source documents')
param pdfContainerName string = 'pdf-documents'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/${pdfContainerName}'
  properties: {
    publicAccess: 'None'
  }
}

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchServiceName
  location: location
  sku: {
    name: searchSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
  }
}

output searchServiceName string = searchService.name
output searchServiceResourceId string = searchService.id
output searchServicePrincipalId string = searchService.identity.principalId
output searchEndpoint string = 'https://${searchService.name}.search.windows.net'
output storageAccountName string = storageAccount.name
output storageAccountResourceId string = storageAccount.id
output pdfContainerName string = pdfContainerName
