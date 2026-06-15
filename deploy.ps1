param(
  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup = "rg-ohsupparfp-web",

  [Parameter(Mandatory = $false)]
  [string]$Location = "eastus2",

  [Parameter(Mandatory = $false)]
  [string]$FunctionAppName = "func-oh-rfp-approver",

  [Parameter(Mandatory = $false)]
  [string]$StaticWebAppName = "swa-oh-rfp-approver",

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
  "Microsoft.Storage"
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
  --parameters location=$Location functionAppName=$FunctionAppName staticWebAppName=$StaticWebAppName aiSearchServiceName=$SearchServiceName aiSearchIndexName=$SearchIndexName
if ($LASTEXITCODE -ne 0) {
  throw "Bicep deployment failed for resource group '$ResourceGroup'."
}

Write-Host "Publishing Azure Functions app code..."
Push-Location ./api
func azure functionapp publish $FunctionAppName --python
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

Write-Host "Linking Static Web App backend to Function App..."
$functionAppId = az functionapp show --resource-group $ResourceGroup --name $FunctionAppName --query id -o tsv
if ($LASTEXITCODE -ne 0 -or -not $functionAppId) {
  throw "Failed to resolve Function App resource ID."
}

az staticwebapp backends link `
  --name $StaticWebAppName `
  --resource-group $ResourceGroup `
  --backend-resource-id $functionAppId `
  --backend-region $Location | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to link Static Web App backend to Function App."
}

Write-Host "Getting Static Web App deployment token..."
$swaToken = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroup --query "properties.apiKey" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $swaToken) {
  throw "Failed to retrieve Static Web App deployment token."
}

Write-Host "Deploying frontend to Static Web App..."
Push-Location ./frontend
npx @azure/static-web-apps-cli deploy . --deployment-token $swaToken --env production
if ($LASTEXITCODE -ne 0) {
  Pop-Location
  throw "Failed to deploy frontend to Static Web App. Ensure Node.js and swa CLI are available (npx will install if needed)."
}
Pop-Location

Write-Host "Getting public app URL..."
$swaHostName = az staticwebapp show --resource-group $ResourceGroup --name $StaticWebAppName --query "defaultHostname" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $swaHostName) {
  throw "Deployment completed but failed to fetch Static Web App URL."
}
Write-Host "Done. App URL: https://$swaHostName"

Pop-Location
