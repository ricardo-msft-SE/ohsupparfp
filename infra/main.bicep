targetScope = 'resourceGroup'

@description('Deployment location')
param location string = resourceGroup().location

@description('Container app name')
param containerAppName string = 'oh-rfp-approver-web'

@description('Container apps environment name')
param containerAppEnvironmentName string = 'oh-rfp-env'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'log-oh-rfp'

@description('User assigned managed identity name')
param managedIdentityName string = 'id-oh-rfp-web'

@description('Container image to deploy')
param containerImage string

@description('ACR login server, for example myregistry.azurecr.io')
param acrServer string

@description('ACR admin username')
param acrUsername string

@secure()
@description('ACR admin password')
param acrPassword string

@description('Foundry project endpoint URL')
param aiProjectEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp'

@description('Agent name to invoke')
param aiAgentName string = 'oh-rfpApprover1'

@description('Published Foundry activity protocol endpoint for the agent application')
param aiActivityProtocolEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp/applications/oh-rfpApprover1/protocols/activityprotocol?api-version=2025-11-15-preview'

@description('Published Foundry responses API endpoint for the agent application')
param aiResponsesApiEndpoint string = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp/applications/oh-rfpApprover1/protocols/openai/responses?api-version=2025-11-15-preview'

@description('Storage account name for HTML artifacts')
param storageAccountName string = 'stohrfpapprover'

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

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
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

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvironmentName
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

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
      registries: [
        {
          server: acrServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
      }
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'web'
          image: containerImage
          env: [
            {
              name: 'AZURE_AI_PROJECT_ENDPOINT'
              value: aiProjectEndpoint
            }
            {
              name: 'AZURE_AI_AGENT_NAME'
              value: aiAgentName
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: managedIdentity.properties.clientId
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
              name: 'AZURE_STORAGE_ACCOUNT_NAME'
              value: storageAccountName
            }
            {
              name: 'AZURE_STORAGE_CONTAINER_NAME'
              value: 'html-artifacts'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}

output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output storageAccountName string = storageAccount.name
output blobContainerName string = 'html-artifacts'
