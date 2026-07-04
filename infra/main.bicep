targetScope = 'resourceGroup'

@description('Deployment location')
param location string = resourceGroup().location

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'log-oh-rfp'

@description('User assigned managed identity name')
param managedIdentityName string = 'id-oh-rfp-web'

#disable-next-line no-unused-params
param appServicePlanName string = 'plan-oh-rfp'

#disable-next-line no-unused-params
param functionAppName string = 'func-oh-rfp-approver'

@description('Azure Container Registry name (globally unique, 5-50 lowercase alphanumeric)')
param containerRegistryName string

@description('Container Apps Environment name')
param containerAppsEnvironmentName string

@description('Container App name')
param containerAppName string

@description('Azure Bot Service resource name')
param botServiceName string = 'bot-oh-rfp-approver'

@description('Entra App Registration client ID for the bot (MICROSOFT_APP_ID). Create via az ad app create.')
param botMicrosoftAppId string

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

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${functionAppName}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
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
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
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
// Container Registry + Container Apps (replaces Azure Functions – no Azure Files needed)
// ---------------------------------------------------------------------------

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false  // pull via managed identity only – no shared keys
  }
}

// AcrPull: managed identity needs this to pull images at Container App startup
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, managedIdentity.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'rfp-approver-bot'
          // Placeholder – GitHub Actions updates this to the real ACR image on every deploy
          image: 'mcr.microsoft.com/k8se/quickstart:latest'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            { name: 'AzureWebJobsStorage__accountName', value: storageAccount.name }
            { name: 'AzureWebJobsStorage__credential', value: 'managedidentity' }
            { name: 'AzureWebJobsStorage__clientId', value: managedIdentity.properties.clientId }
            { name: 'AzureWebJobsStorage__blobServiceUri', value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}' }
            { name: 'AzureWebJobsStorage__queueServiceUri', value: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}' }
            { name: 'AzureWebJobsStorage__tableServiceUri', value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}' }
            { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
            { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'python' }
            { name: 'AZURE_CLIENT_ID', value: managedIdentity.properties.clientId }
            { name: 'AZURE_AI_PROJECT_ENDPOINT', value: aiProjectEndpoint }
            { name: 'AZURE_AI_AGENT_NAME', value: aiAgentName }
            { name: 'AZURE_AI_ACTIVITY_PROTOCOL_ENDPOINT', value: aiActivityProtocolEndpoint }
            { name: 'AZURE_AI_RESPONSES_API_ENDPOINT', value: aiResponsesApiEndpoint }
            { name: 'AZURE_AI_SEARCH_ENDPOINT', value: 'https://${aiSearchServiceName}.search.windows.net' }
            { name: 'AZURE_AI_SEARCH_INDEX_NAME', value: aiSearchIndexName }
            { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
            { name: 'ApplicationInsightsAgent_EXTENSION_VERSION', value: '~3' }
            { name: 'MICROSOFT_APP_ID', value: botMicrosoftAppId }
            { name: 'MICROSOFT_APP_PASSWORD', value: '' }  // set by GitHub Actions post-deploy step
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Azure Bot Service + Teams Channel
// Ref: https://learn.microsoft.com/en-us/azure/bot-service/bot-service-overview
// ---------------------------------------------------------------------------

resource botService 'Microsoft.BotService/botServices@2022-09-15' = {
  name: botServiceName
  location: 'global' // Bot Services are always deployed globally.
  kind: 'azurebot'
  sku: {
    name: 'S1'
  }
  properties: {
    displayName: 'RFP Approver Bot'
    msaAppId: botMicrosoftAppId
    msaAppType: 'SingleTenant'
    msaAppTenantId: subscription().tenantId
    // Messaging endpoint: Container App ingress URL
    endpoint: 'https://${containerApp.properties.configuration.ingress.fqdn}/api/messages'
  }
}

resource botTeamsChannel 'Microsoft.BotService/botServices/channels@2022-09-15' = {
  parent: botService
  name: 'MsTeamsChannel'
  location: 'global'
  properties: {
    channelName: 'MsTeamsChannel'
    properties: {
      isEnabled: true
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output containerRegistryName string = containerRegistry.name
output containerAppName string = containerApp.name
output functionAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output botMessagingEndpoint string = 'https://${containerApp.properties.configuration.ingress.fqdn}/api/messages'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output storageAccountName string = storageAccount.name
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
