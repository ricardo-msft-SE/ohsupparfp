using './main.bicep'

param location = 'eastus2'
param containerAppName = 'oh-rfp-approver-web'
param containerAppEnvironmentName = 'oh-rfp-env'
param logAnalyticsWorkspaceName = 'log-oh-rfp'
param managedIdentityName = 'id-oh-rfp-web'

// Set this during deployment to your pushed image, for example:
// myregistry.azurecr.io/oh-rfp-approver:latest
param containerImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

param aiProjectEndpoint = 'https://ohsupparfp-resource.services.ai.azure.com/api/projects/ohsupparfp'
param aiAgentName = 'oh-rfpApprover1'
