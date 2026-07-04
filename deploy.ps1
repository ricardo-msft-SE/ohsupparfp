param(
  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup = "rg-ohsupparfp-web",

  [Parameter(Mandatory = $false)]
  [string]$Location = "eastus2",

  [Parameter(Mandatory = $false)]
  [string]$FunctionAppName = "func-oh-rfp-approver",

  [Parameter(Mandatory = $true)]
  [string]$MicrosoftAppPassword,

  [Parameter(Mandatory = $false)]
  [string]$LogAnalyticsWorkspaceName = "log-oh-rfp",

  [Parameter(Mandatory = $false)]
  [string]$ManagedIdentityName = "id-oh-rfp-web",

  [Parameter(Mandatory = $false)]
  [string]$AppServicePlanName = "plan-oh-rfp",

  [Parameter(Mandatory = $false)]
  [string]$StorageAccountName = "stohrfpapprover",

  [Parameter(Mandatory = $false)]
  [string]$FoundryResourceGroup = "rg-ohsupparfp",

  [Parameter(Mandatory = $false)]
  [string]$FoundryResourceName = "ohsupparfp-resource",

  [Parameter(Mandatory = $false)]
  [string]$SearchResourceGroup = "rg-ohsupparfp",

  [Parameter(Mandatory = $false)]
  [string]$SearchServiceName = "aisearch-ohsupparfp",

  [Parameter(Mandatory = $false)]
  [string]$SearchIndexName = "rfp-index"
)

$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot

Write-Host "Creating resource group if needed..."
az group create --name $ResourceGroup --location $Location | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to create or access resource group '$ResourceGroup'."
}

az config set extension.use_dynamic_install=yes_without_prompt | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to configure Azure CLI dynamic extension install."
}

Write-Host "Registering required Azure resource providers..."
$requiredProviders = @(
  "Microsoft.Web",
  "Microsoft.OperationalInsights",
  "Microsoft.ManagedIdentity",
  "Microsoft.CognitiveServices",
  "Microsoft.Storage",
  "Microsoft.BotService"
)

foreach ($provider in $requiredProviders) {
  az provider register --namespace $provider --wait --only-show-errors | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to register provider namespace '$provider'."
  }
}

Write-Host "Deploying infrastructure from Bicep..."
az deployment group create `
  --resource-group $ResourceGroup `
  --template-file ./infra/main.bicep `
  --parameters ./infra/main.bicepparam
if ($LASTEXITCODE -ne 0) {
  throw "Bicep deployment failed for resource group '$ResourceGroup'."
}

Write-Host "Publishing Azure Functions app code..."
Push-Location ./api
func azure functionapp publish $FunctionAppName --python --build local
if ($LASTEXITCODE -ne 0) {
  Pop-Location
  throw "Failed to publish Function App '$FunctionAppName'. Make sure Azure Functions Core Tools is installed."
}
Pop-Location

Write-Host "Getting managed identity principal ID from deployment output..."
$principalId = az deployment group show `
  --resource-group $ResourceGroup `
  --name (az deployment group list --resource-group $ResourceGroup --query "[0].name" -o tsv) `
  --query "properties.outputs.managedIdentityPrincipalId.value" -o tsv
if ($LASTEXITCODE -ne 0) {
  throw "Failed to read deployment outputs."
}

if (-not $principalId) {
  throw "Could not resolve managed identity principal ID from deployment outputs."
}

$foundryResourceId = az cognitiveservices account show `
  --resource-group $FoundryResourceGroup `
  --name $FoundryResourceName `
  --query id -o tsv
if ($LASTEXITCODE -ne 0 -or -not $foundryResourceId) {
  throw "Failed to resolve Foundry resource '$FoundryResourceName' in '$FoundryResourceGroup'."
}

Write-Host "Assigning Azure AI User role to app managed identity on Foundry resource..."
az role assignment create `
  --assignee-object-id $principalId `
  --assignee-principal-type ServicePrincipal `
  --role "Azure AI User" `
  --scope $foundryResourceId | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to assign 'Azure AI User' role to managed identity."
}

$searchResourceId = az search service show `
  --resource-group $SearchResourceGroup `
  --name $SearchServiceName `
  --query id -o tsv
if ($LASTEXITCODE -ne 0 -or -not $searchResourceId) {
  throw "Failed to resolve Azure AI Search service '$SearchServiceName' in '$SearchResourceGroup'."
}

Write-Host "Assigning Search Index Data Reader role to app managed identity on Azure AI Search..."
az role assignment create `
  --assignee-object-id $principalId `
  --assignee-principal-type ServicePrincipal `
  --role "Search Index Data Reader" `
  --scope $searchResourceId | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to assign 'Search Index Data Reader' role to managed identity."
}

Write-Host "Setting bot client secret on Function App..."
az functionapp config appsettings set `
  --resource-group $ResourceGroup `
  --name $FunctionAppName `
  --settings "MICROSOFT_APP_PASSWORD=$MicrosoftAppPassword" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to set MICROSOFT_APP_PASSWORD on Function App '$FunctionAppName'."
}

Write-Host "Getting bot messaging endpoint..."
$funcHostName = az functionapp show --resource-group $ResourceGroup --name $FunctionAppName --query "defaultHostName" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $funcHostName) {
  throw "Deployment completed but failed to fetch Function App hostname."
}
Write-Host "Done. Bot messaging endpoint: https://$funcHostName/api/messages"

Pop-Location
