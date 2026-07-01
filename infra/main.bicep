targetScope = 'resourceGroup'

@description('Deployment location')
param location string = resourceGroup().location

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'log-oh-rfp'

@description('User assigned managed identity name')
param managedIdentityName string = 'id-oh-rfp-web'

@description('App Service Plan name (Consumption)')
param appServicePlanName string = 'plan-oh-rfp'

@description('Function App name')
param functionAppName string = 'func-oh-rfp-approver'

@description('Static Web App name')
param staticWebAppName string = 'swa-oh-rfp-approver'

@description('Foundry project endpoint URL')
param aiProjectEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp'

@description('Agent name to invoke')
param aiAgentName string = 'oh-rfpApprover1'

@description('Published Foundry activity protocol endpoint for the agent application')
param aiActivityProtocolEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp/applications/oh-rfpApprover1/protocols/activityprotocol?api-version=2025-11-15-preview'

@description('Published Foundry responses API endpoint for the agent application')
param aiResponsesApiEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp/applications/oh-rfpApprover1/protocols/openai/responses?api-version=2025-11-15-preview'

@description('Azure AI Search service name used to ground recommendations')
param aiSearchServiceName string = 'aisearch-ohsupparfp'

@description('Azure AI Search index name used to retrieve reference context')
param aiSearchIndexName string = 'rfp-index'

@description('Storage account name for HTML artifacts and Functions runtime')
param storageAccountName string = 'stohrfpapprover'

// ---------------------------------------------------------------------------
// Observability
// ---------------------------------------------------------------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

// ---------------------------------------------------------------------------
// Storage (artifacts + Functions runtime)
// ---------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccountName}/default/html-artifacts'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageQueueDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageTableDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Function App (Linux Consumption)
// ---------------------------------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'AzureWebJobsStorage__blobServiceUri'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__tableServiceUri'
          value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'AZURE_AI_PROJECT_ENDPOINT'
          value: aiProjectEndpoint
        }
        {
          name: 'AZURE_AI_AGENT_NAME'
          value: aiAgentName
        }
        {
          name: 'AZURE_AI_ACTIVITY_PROTOCOL_ENDPOINT'
          value: aiActivityProtocolEndpoint
        }
        {
          name: 'AZURE_AI_RESPONSES_API_ENDPOINT'
          value: aiResponsesApiEndpoint
        }
        {
          name: 'AZURE_AI_SEARCH_ENDPOINT'
          value: 'https://${aiSearchServiceName}.search.windows.net'
        }
        {
          name: 'AZURE_AI_SEARCH_INDEX_NAME'
          value: aiSearchIndexName
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: 'html-artifacts'
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// Static Web App (free tier, linked to Function App as backend)
// ---------------------------------------------------------------------------

resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource swaLinkedBackend 'Microsoft.Web/staticSites/linkedBackends@2022-09-01' = {
  parent: staticWebApp
  name: 'backend'
  properties: {
    backendResourceId: functionApp.id
    region: location
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output storageAccountName string = storageAccount.name
output blobContainerName string = 'html-artifacts'
