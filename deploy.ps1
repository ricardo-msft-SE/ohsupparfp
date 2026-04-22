param(
  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup = "rg-ohsupparfp-web",

  [Parameter(Mandatory = $false)]
  [string]$Location = "eastus2",

  [Parameter(Mandatory = $false)]
  [string]$ContainerAppName = "oh-rfp-approver-web",

  [Parameter(Mandatory = $false)]
  [string]$EnvName = "oh-rfp-env",

  [Parameter(Mandatory = $false)]
  [string]$AcrName = "",

  [Parameter(Mandatory = $false)]
  [string]$Image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest",

  [Parameter(Mandatory = $false)]
  [string]$FoundryResourceGroup = "rg-ohsupparfp",

  [Parameter(Mandatory = $false)]
  [string]$FoundryResourceName = "ohsupparfp-resource"
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
  "Microsoft.ContainerRegistry",
  "Microsoft.App",
  "Microsoft.OperationalInsights",
  "Microsoft.ManagedIdentity",
  "Microsoft.CognitiveServices"
)

foreach ($provider in $requiredProviders) {
  az provider register --namespace $provider --wait --only-show-errors | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to register provider namespace '$provider'."
  }
}

if (-not $AcrName) {
  $suffix = Get-Random -Minimum 1000 -Maximum 9999
  $AcrName = "acrohsupparfp$suffix"
}

Write-Host "Creating Azure Container Registry if needed..."
$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup --query name -o tsv 2>$null
if (-not $acrExists) {
  az acr create --name $AcrName --resource-group $ResourceGroup --location $Location --sku Basic --admin-enabled true | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create Azure Container Registry '$AcrName'."
  }
}

$tag = Get-Date -Format "yyyyMMddHHmmss"
$repository = "oh-rfp-approver"
$acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer -o tsv
if ($LASTEXITCODE -ne 0 -or -not $acrLoginServer) {
  throw "Failed to resolve ACR login server for '$AcrName'."
}
$image = "${acrLoginServer}/${repository}:$tag"

Write-Host "Building and pushing image to ACR..."
az acr build --registry $AcrName --image "${repository}:$tag" .
if ($LASTEXITCODE -ne 0) {
  throw "Failed to build and push image to ACR '$AcrName'."
}

$acrUsername = az acr credential show --name $AcrName --query username -o tsv
if ($LASTEXITCODE -ne 0 -or -not $acrUsername) {
  throw "Failed to get ACR username for '$AcrName'."
}
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $acrPassword) {
  throw "Failed to get ACR password for '$AcrName'."
}

Write-Host "Deploying infrastructure from Bicep..."
az deployment group create `
  --resource-group $ResourceGroup `
  --template-file ./infra/main.bicep `
  --parameters location=$Location containerAppName=$ContainerAppName containerAppEnvironmentName=$EnvName containerImage=$image acrServer=$acrLoginServer acrUsername=$acrUsername acrPassword=$acrPassword
if ($LASTEXITCODE -ne 0) {
  throw "Bicep deployment failed for resource group '$ResourceGroup'."
}

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

Write-Host "Getting public app URL..."
$appUrl = az containerapp show --resource-group $ResourceGroup --name $ContainerAppName --query "properties.configuration.ingress.fqdn" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $appUrl) {
  throw "Deployment completed but failed to fetch Container App public URL."
}
Write-Host "Done. App URL: https://$appUrl"

Pop-Location
