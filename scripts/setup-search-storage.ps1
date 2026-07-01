param(
  [Parameter(Mandatory = $false)]
  [string]$StateFile = '.azure/search-setup-state.json',

  [Parameter(Mandatory = $false)]
  [switch]$ResetState
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$StatePath = Join-Path $ProjectRoot $StateFile
$TemplatePath = Join-Path $ProjectRoot 'infra/search-storage.bicep'
$SearchApiVersion = '2024-07-01'

function New-DefaultState {
  return [ordered]@{
    TenantId = ''
    SubscriptionId = ''
    Location = 'eastus2'
    ResourceGroup = 'rg-ohsupparfp-search'
    SearchServiceName = 'aisearch-ohsupparfp'
    SearchSku = 'basic'
    StorageAccountName = ''
    PdfContainerName = 'pdf-documents'
    IndexName = 'pdf-index'
    DataSourceName = 'pdf-datasource'
    IndexerName = 'pdf-indexer'
    FoundryResourceGroup = ''
    FoundryResourceName = ''
    AppPrincipalId = ''
    SearchServiceResourceId = ''
    SearchServicePrincipalId = ''
    StorageAccountResourceId = ''
    SearchEndpoint = ''
    CompletedSteps = @()
  }
}

function Load-State {
  if (Test-Path $StatePath) {
    return (Get-Content -Path $StatePath -Raw | ConvertFrom-Json -AsHashtable)
  }
  return (New-DefaultState)
}

function Save-State([hashtable]$state) {
  $dir = Split-Path -Path $StatePath -Parent
  if (-not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
  }
  ($state | ConvertTo-Json -Depth 10) | Set-Content -Path $StatePath -Encoding UTF8
}

function Mark-StepComplete([hashtable]$state, [int]$stepNumber) {
  $items = @($state.CompletedSteps)
  if ($items -notcontains $stepNumber) {
    $state.CompletedSteps = @($items + $stepNumber | Sort-Object -Unique)
  }
}

function Get-StepStatus([hashtable]$state, [int]$stepNumber) {
  if (@($state.CompletedSteps) -contains $stepNumber) {
    return 'Done'
  }
  return 'Pending'
}

function Invoke-AzJson([string]$commandLine) {
  $result = Invoke-Expression $commandLine
  if ($LASTEXITCODE -ne 0) {
    throw "Azure CLI command failed: $commandLine"
  }
  if (-not $result) {
    return $null
  }
  return ($result | ConvertFrom-Json)
}

function Invoke-AzText([string]$commandLine) {
  $result = Invoke-Expression $commandLine
  if ($LASTEXITCODE -ne 0) {
    throw "Azure CLI command failed: $commandLine"
  }
  return "$result".Trim()
}

function Ensure-LoggedIn {
  $ctx = Invoke-Expression 'az account show -o json 2>$null'
  if ($LASTEXITCODE -eq 0 -and $ctx) {
    return
  }

  Write-Host 'No active Azure CLI session found. Starting device-code login...'
  az login --use-device-code | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw 'Azure login failed.'
  }
}

function Get-FoundryCandidates {
  $accounts = Invoke-AzJson 'az cognitiveservices account list -o json'
  if (-not $accounts) {
    return @()
  }

  $candidates = @()
  foreach ($account in $accounts) {
    $endpoint = ''
    if ($account.properties -and $account.properties.endpoint) {
      $endpoint = "$($account.properties.endpoint)"
    }

    $kind = if ($account.kind) { "$($account.kind)" } else { '' }
    $looksLikeFoundry = $false
    if ($endpoint -match '\.services\.ai\.azure\.com/?$') {
      $looksLikeFoundry = $true
    }
    if ($kind -eq 'AIServices') {
      $looksLikeFoundry = $true
    }

    if ($looksLikeFoundry) {
      $candidates += [ordered]@{
        name = "$($account.name)"
        resourceGroup = "$($account.resourceGroup)"
        kind = $kind
        location = "$($account.location)"
        endpoint = $endpoint
      }
    }
  }

  return $candidates
}

function Ensure-Provider([string]$providerNamespace) {
  $state = Invoke-AzText "az provider show --namespace $providerNamespace --query registrationState -o tsv"
  if ($state -eq 'Registered') {
    return
  }

  Write-Host "Registering provider: $providerNamespace"
  az provider register --namespace $providerNamespace --wait --only-show-errors | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to register provider namespace '$providerNamespace'."
  }
}

function Ensure-RoleAssignment([string]$roleName, [string]$scope, [string]$assigneeObjectId) {
  $existing = Invoke-AzText "az role assignment list --assignee-object-id $assigneeObjectId --role \"$roleName\" --scope $scope --query \"[0].id\" -o tsv"
  if ($existing) {
    Write-Host "Role already assigned: $roleName"
    return
  }

  Write-Host "Assigning role '$roleName'..."
  az role assignment create --assignee-object-id $assigneeObjectId --assignee-principal-type ServicePrincipal --role "$roleName" --scope $scope | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to assign role '$roleName' on scope '$scope'."
  }
}

function Invoke-SearchRest([string]$method, [string]$path, [hashtable]$payload, [hashtable]$state) {
  if (-not $state.SearchEndpoint) {
    throw 'Search endpoint is not available. Run deployment step first.'
  }

  $url = "$($state.SearchEndpoint)/$path"
  if ($url -notmatch '\?api-version=') {
    $separator = if ($url.Contains('?')) { '&' } else { '?' }
    $url = "$url$separator`api-version=$SearchApiVersion"
  }

  $args = @(
    'rest',
    '--method', $method,
    '--uri', $url,
    '--resource', 'https://search.azure.com/'
  )
  if ($payload) {
    $jsonBody = $payload | ConvertTo-Json -Depth 20 -Compress
    $args += @('--body', $jsonBody)
  }

  $result = & az @args
  if ($LASTEXITCODE -ne 0) {
    throw "Search REST call failed: $method $url"
  }

  if (-not $result) {
    return $null
  }

  return ($result | ConvertFrom-Json)
}

function Show-Menu([hashtable]$state) {
  Write-Host ''
  Write-Host '=========================================='
  Write-Host 'Azure AI Search + Blob Guided Setup'
  Write-Host '=========================================='
  Write-Host "1. Prerequisite checks                                 [$((Get-StepStatus $state 1))]"
  Write-Host "2. Select tenant/subscription and names               [$((Get-StepStatus $state 2))]"
  Write-Host "3. Collect Foundry and app identity info              [$((Get-StepStatus $state 3))]"
  Write-Host "4. Deploy Search + Blob infrastructure (Bicep)        [$((Get-StepStatus $state 4))]"
  Write-Host "5. Apply RBAC assignments                             [$((Get-StepStatus $state 5))]"
  Write-Host "6. RBAC propagation wait and re-check                 [$((Get-StepStatus $state 6))]"
  Write-Host "7. Create data source and index                       [$((Get-StepStatus $state 7))]"
  Write-Host "8. Create and run indexer                             [$((Get-StepStatus $state 8))]"
  Write-Host "9. Upload sample PDF                                  [$((Get-StepStatus $state 9))]"
  Write-Host "10. Query smoke test                                  [$((Get-StepStatus $state 10))]"
  Write-Host "11. Show app env values                               [$((Get-StepStatus $state 11))]"
  Write-Host '0. Exit'
  Write-Host ''
}

function Show-NextStepHint([int]$completedStep) {
  $hint = switch ($completedStep) {
    1 { 'Recommended next step: 2 (select subscription and resource names).' }
    2 { 'Recommended next step: 3 (discover/select Foundry resource and provide app identity).' }
    3 { 'Recommended next step: 4 (deploy Search + Blob infrastructure).' }
    4 { 'Recommended next step: 5 (apply RBAC assignments).' }
    5 { 'Recommended next step: 6 (wait for and re-check RBAC propagation).' }
    6 { 'Recommended next step: 7 (create data source and index).' }
    7 { 'Recommended next step: 8 (create and run indexer).' }
    8 { 'Recommended next step: 9 (upload a sample PDF), then 10 (query smoke test).' }
    9 { 'Recommended next step: 8 (run indexer again to ingest the new PDF), then 10 (query smoke test).' }
    10 { 'Recommended next step: 11 (print final app environment values).' }
    11 { 'Setup flow complete. You can exit or rerun specific steps as needed.' }
    default { '' }
  }

  if ($hint) {
    Write-Host ''
    Write-Host $hint -ForegroundColor Cyan
  }
}

function Step1-Prerequisites([hashtable]$state) {
  Ensure-LoggedIn

  $extensions = @('account', 'resource-graph')
  foreach ($ext in $extensions) {
    az extension add --name $ext --upgrade --yes | Out-Null
  }

  $providers = @(
    'Microsoft.Storage',
    'Microsoft.Search',
    'Microsoft.Authorization',
    'Microsoft.ManagedIdentity',
    'Microsoft.CognitiveServices'
  )

  foreach ($provider in $providers) {
    Ensure-Provider -providerNamespace $provider
  }

  Write-Host 'Prerequisites check completed.'
  Mark-StepComplete $state 1
}

function Step2-SelectContextAndNames([hashtable]$state) {
  Ensure-LoggedIn
  $subs = Invoke-AzJson 'az account list --all -o json'
  if (-not $subs -or $subs.Count -eq 0) {
    throw 'No Azure subscriptions were found for the signed-in account.'
  }

  Write-Host ''
  Write-Host 'Available subscriptions:'
  for ($i = 0; $i -lt $subs.Count; $i++) {
    $item = $subs[$i]
    Write-Host "$($i + 1). $($item.name) ($($item.id)) tenant=$($item.tenantId)"
  }

  $selection = Read-Host 'Select subscription number'
  $parsedSelection = 0
  if (-not [int]::TryParse($selection, [ref]$parsedSelection)) {
    throw 'Invalid subscription selection.'
  }

  $selectedIndex = $parsedSelection - 1
  if ($selectedIndex -lt 0 -or $selectedIndex -ge $subs.Count) {
    throw 'Selected subscription number is out of range.'
  }

  $selected = $subs[$selectedIndex]
  az account set --subscription $selected.id | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to set active subscription.'
  }

  $state.SubscriptionId = $selected.id
  $state.TenantId = $selected.tenantId

  $defaultStorageName = if ($state.StorageAccountName) { $state.StorageAccountName } else {
    ('st' + (($state.SearchServiceName -replace '[^a-zA-Z0-9]', '').ToLower()) + (Get-Random -Minimum 100 -Maximum 999))
  }
  if ($defaultStorageName.Length -gt 24) {
    $defaultStorageName = $defaultStorageName.Substring(0, 24)
  }

  $inputLocation = Read-Host "Location [$($state.Location)]"
  if ($inputLocation) { $state.Location = $inputLocation }

  $inputRg = Read-Host "Resource group [$($state.ResourceGroup)]"
  if ($inputRg) { $state.ResourceGroup = $inputRg }

  $inputSearch = Read-Host "Search service name [$($state.SearchServiceName)]"
  if ($inputSearch) { $state.SearchServiceName = $inputSearch }

  $inputStorage = Read-Host "Storage account name [$defaultStorageName]"
  if ($inputStorage) {
    $state.StorageAccountName = $inputStorage.ToLower()
  } elseif (-not $state.StorageAccountName) {
    $state.StorageAccountName = $defaultStorageName.ToLower()
  }

  $inputContainer = Read-Host "PDF container name [$($state.PdfContainerName)]"
  if ($inputContainer) { $state.PdfContainerName = $inputContainer }

  $inputIndex = Read-Host "Search index name [$($state.IndexName)]"
  if ($inputIndex) { $state.IndexName = $inputIndex }

  $inputDatasource = Read-Host "Data source name [$($state.DataSourceName)]"
  if ($inputDatasource) { $state.DataSourceName = $inputDatasource }

  $inputIndexer = Read-Host "Indexer name [$($state.IndexerName)]"
  if ($inputIndexer) { $state.IndexerName = $inputIndexer }

  Mark-StepComplete $state 2
}

function Step3-CollectIdentityInputs([hashtable]$state) {
  $discoverChoice = Read-Host 'Auto-discover Foundry resources in this subscription? [Y/n]'
  $shouldDiscover = (-not $discoverChoice) -or ($discoverChoice -match '^(y|yes)$')

  if ($shouldDiscover) {
    $candidates = @(Get-FoundryCandidates)
    if ($candidates.Count -gt 0) {
      Write-Host ''
      Write-Host 'Foundry/AI Services candidates:'
      for ($i = 0; $i -lt $candidates.Count; $i++) {
        $item = $candidates[$i]
        Write-Host "$($i + 1). $($item.name)  rg=$($item.resourceGroup)  kind=$($item.kind)  location=$($item.location)"
        if ($item.endpoint) {
          Write-Host "   endpoint=$($item.endpoint)"
        }
      }

      $pick = Read-Host 'Select candidate number to use, or press Enter to skip'
      if ($pick) {
        $parsedPick = 0
        if (-not [int]::TryParse($pick, [ref]$parsedPick)) {
          throw 'Invalid Foundry candidate selection.'
        }

        $pickIndex = $parsedPick - 1
        if ($pickIndex -lt 0 -or $pickIndex -ge $candidates.Count) {
          throw 'Foundry candidate selection is out of range.'
        }

        $selected = $candidates[$pickIndex]
        $state.FoundryResourceGroup = $selected.resourceGroup
        $state.FoundryResourceName = $selected.name
      }
    } else {
      Write-Host 'No Foundry-like cognitive resources were discovered in this subscription.'
    }
  }

  $frg = Read-Host "Foundry resource group (optional) [$($state.FoundryResourceGroup)]"
  if ($frg) { $state.FoundryResourceGroup = $frg }

  $fname = Read-Host "Foundry resource name (optional) [$($state.FoundryResourceName)]"
  if ($fname) { $state.FoundryResourceName = $fname }

  $principal = Read-Host "Application managed identity principal/object ID (optional) [$($state.AppPrincipalId)]"
  if ($principal) { $state.AppPrincipalId = $principal }

  Mark-StepComplete $state 3
}

function Step4-DeployInfra([hashtable]$state) {
  if (-not (Test-Path $TemplatePath)) {
    throw "Template not found: $TemplatePath"
  }

  if (-not $state.ResourceGroup -or -not $state.Location -or -not $state.SearchServiceName -or -not $state.StorageAccountName) {
    throw 'Missing required configuration. Run step 2 first.'
  }

  az group create --name $state.ResourceGroup --location $state.Location | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create or access resource group.'
  }

  $deploymentName = "searchsetup-$(Get-Date -Format 'yyyyMMddHHmmss')"
  $deployArgs = @(
    'deployment', 'group', 'create',
    '--name', $deploymentName,
    '--resource-group', $state.ResourceGroup,
    '--template-file', $TemplatePath,
    '--parameters',
    "location=$($state.Location)",
    "searchServiceName=$($state.SearchServiceName)",
    "searchSku=$($state.SearchSku)",
    "storageAccountName=$($state.StorageAccountName)",
    "pdfContainerName=$($state.PdfContainerName)",
    '--query', 'properties.outputs',
    '-o', 'json'
  )

  $outputsRaw = & az @deployArgs
  if ($LASTEXITCODE -ne 0) {
    throw 'Bicep deployment failed for Search + Blob resources.'
  }
  $outputs = $outputsRaw | ConvertFrom-Json
  $state.SearchServiceResourceId = $outputs.searchServiceResourceId.value
  $state.SearchServicePrincipalId = $outputs.searchServicePrincipalId.value
  $state.SearchEndpoint = $outputs.searchEndpoint.value
  $state.StorageAccountResourceId = $outputs.storageAccountResourceId.value

  Write-Host "Deployed search endpoint: $($state.SearchEndpoint)"
  Mark-StepComplete $state 4
}

function Step5-ApplyRbac([hashtable]$state) {
  if (-not $state.SearchServiceResourceId -or -not $state.StorageAccountResourceId -or -not $state.SearchServicePrincipalId) {
    throw 'Infrastructure outputs are missing. Run step 4 first.'
  }

  # Allows AI Search service managed identity to read blobs during indexing.
  Ensure-RoleAssignment -roleName 'Storage Blob Data Reader' -scope $state.StorageAccountResourceId -assigneeObjectId $state.SearchServicePrincipalId

  if ($state.AppPrincipalId) {
    Ensure-RoleAssignment -roleName 'Search Index Data Reader' -scope $state.SearchServiceResourceId -assigneeObjectId $state.AppPrincipalId
    Ensure-RoleAssignment -roleName 'Storage Blob Data Reader' -scope $state.StorageAccountResourceId -assigneeObjectId $state.AppPrincipalId

    if ($state.FoundryResourceGroup -and $state.FoundryResourceName) {
      $foundryId = Invoke-AzText "az cognitiveservices account show --resource-group $($state.FoundryResourceGroup) --name $($state.FoundryResourceName) --query id -o tsv"
      if ($foundryId) {
        Ensure-RoleAssignment -roleName 'Azure AI User' -scope $foundryId -assigneeObjectId $state.AppPrincipalId
      }
    }
  } else {
    Write-Host 'App principal ID was not provided. App-level RBAC assignments were skipped.'
  }

  Write-Host 'RBAC assignments requested successfully.'
  Mark-StepComplete $state 5
}

function Step6-PropagationCheck([hashtable]$state) {
  if (-not $state.SearchServiceResourceId -or -not $state.StorageAccountResourceId) {
    throw 'Run step 4 first.'
  }

  $minutesText = Read-Host 'Minutes to wait before re-checking role assignments [2]'
  $minutes = 2
  if ($minutesText) {
    $minutes = [int]$minutesText
  }

  Write-Host "Waiting $minutes minute(s) for RBAC propagation..."
  Start-Sleep -Seconds ($minutes * 60)

  if ($state.AppPrincipalId) {
    $searchRole = Invoke-AzText "az role assignment list --assignee-object-id $($state.AppPrincipalId) --scope $($state.SearchServiceResourceId) --role \"Search Index Data Reader\" --query \"[0].id\" -o tsv"
    $storageRole = Invoke-AzText "az role assignment list --assignee-object-id $($state.AppPrincipalId) --scope $($state.StorageAccountResourceId) --role \"Storage Blob Data Reader\" --query \"[0].id\" -o tsv"
    if ($searchRole -and $storageRole) {
      Write-Host 'App principal role assignments are present.'
    } else {
      Write-Host 'One or more app principal role assignments are not visible yet. You can run this step again.'
    }
  }

  $searchIdentityStorageRole = Invoke-AzText "az role assignment list --assignee-object-id $($state.SearchServicePrincipalId) --scope $($state.StorageAccountResourceId) --role \"Storage Blob Data Reader\" --query \"[0].id\" -o tsv"
  if ($searchIdentityStorageRole) {
    Write-Host 'Search service managed identity role assignment is present.'
  } else {
    Write-Host 'Search service role assignment is not visible yet. You can run this step again.'
  }

  Mark-StepComplete $state 6
}

function Step7-CreateDatasourceAndIndex([hashtable]$state) {
  if (-not $state.SubscriptionId -or -not $state.ResourceGroup -or -not $state.StorageAccountName -or -not $state.SearchEndpoint) {
    throw 'Missing state for search object creation. Run steps 2 and 4 first.'
  }

  $storageResourceId = "/subscriptions/$($state.SubscriptionId)/resourceGroups/$($state.ResourceGroup)/providers/Microsoft.Storage/storageAccounts/$($state.StorageAccountName)"

  $dataSourcePayload = @{
    name = $state.DataSourceName
    type = 'azureblob'
    credentials = @{
      connectionString = "ResourceId=$storageResourceId;"
    }
    container = @{
      name = $state.PdfContainerName
    }
  }

  Invoke-SearchRest -method 'PUT' -path "datasources/$($state.DataSourceName)" -payload $dataSourcePayload -state $state | Out-Null

  $indexPayload = @{
    name = $state.IndexName
    fields = @(
      @{ name = 'id'; type = 'Edm.String'; key = $true; searchable = $false; filterable = $true; sortable = $false; facetable = $false },
      @{ name = 'metadata_storage_name'; type = 'Edm.String'; searchable = $true; filterable = $true; sortable = $true; facetable = $false },
      @{ name = 'metadata_storage_path'; type = 'Edm.String'; searchable = $false; filterable = $true; sortable = $false; facetable = $false },
      @{ name = 'content'; type = 'Edm.String'; searchable = $true; filterable = $false; sortable = $false; facetable = $false }
    )
    semantic = @{
      configurations = @(
        @{
          name = 'default-semantic-config'
          prioritizedFields = @{
            titleField = @{
              fieldName = 'metadata_storage_name'
            }
            prioritizedContentFields = @(
              @{ fieldName = 'content' }
            )
          }
        }
      )
    }
  }

  Invoke-SearchRest -method 'PUT' -path "indexes/$($state.IndexName)" -payload $indexPayload -state $state | Out-Null

  Write-Host 'Data source and index created/updated.'
  Mark-StepComplete $state 7
}

function Step8-CreateAndRunIndexer([hashtable]$state) {
  $indexerPayload = @{
    name = $state.IndexerName
    dataSourceName = $state.DataSourceName
    targetIndexName = $state.IndexName
    parameters = @{
      configuration = @{
        parsingMode = 'default'
        dataToExtract = 'contentAndMetadata'
      }
    }
    fieldMappings = @(
      @{
        sourceFieldName = 'metadata_storage_path'
        targetFieldName = 'id'
        mappingFunction = @{
          name = 'base64Encode'
        }
      }
    )
  }

  Invoke-SearchRest -method 'PUT' -path "indexers/$($state.IndexerName)" -payload $indexerPayload -state $state | Out-Null
  Invoke-SearchRest -method 'POST' -path "indexers/$($state.IndexerName)/search.run" -payload $null -state $state | Out-Null

  Write-Host 'Indexer run started. Polling status...'
  $maxAttempts = 20
  for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    Start-Sleep -Seconds 15
    $status = Invoke-SearchRest -method 'GET' -path "indexers/$($state.IndexerName)/status" -payload $null -state $state
    $last = $status.lastResult
    $stateText = if ($last) { $last.status } else { 'unknown' }
    Write-Host "Attempt $attempt/$maxAttempts - indexer status: $stateText"

    if ($stateText -eq 'success') {
      Write-Host 'Indexer completed successfully.'
      Mark-StepComplete $state 8
      return
    }

    if ($stateText -eq 'transientFailure' -or $stateText -eq 'error') {
      Write-Host 'Indexer reported a failure. Review Search service indexer execution logs.'
      Mark-StepComplete $state 8
      return
    }
  }

  Write-Host 'Indexer status polling timed out. You can run this step again later.'
  Mark-StepComplete $state 8
}

function Step9-UploadSamplePdf([hashtable]$state) {
  $filePath = Read-Host 'Absolute path to sample PDF file'
  if (-not (Test-Path $filePath)) {
    throw "File not found: $filePath"
  }

  $blobName = Split-Path -Path $filePath -Leaf
  az storage blob upload --account-name $state.StorageAccountName --container-name $state.PdfContainerName --name $blobName --file $filePath --auth-mode login --overwrite true | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to upload sample PDF.'
  }

  Write-Host "Uploaded PDF as blob '$blobName'."
  Mark-StepComplete $state 9
}

function Step10-SmokeQuery([hashtable]$state) {
  $queryText = Read-Host 'Search query text [*]'
  if (-not $queryText) {
    $queryText = '*'
  }

  $payload = @{
    search = $queryText
    top = 3
    count = $true
  }

  $response = Invoke-SearchRest -method 'POST' -path "indexes/$($state.IndexName)/docs/search" -payload $payload -state $state
  $count = $response.'@odata.count'
  Write-Host "Result count: $count"

  $docs = @($response.value)
  for ($i = 0; $i -lt [Math]::Min(3, $docs.Count); $i++) {
    $doc = $docs[$i]
    $name = if ($doc.metadata_storage_name) { $doc.metadata_storage_name } else { 'unknown' }
    $snippet = if ($doc.content) { "$($doc.content)".Substring(0, [Math]::Min(140, "$($doc.content)".Length)) } else { '<no content>' }
    Write-Host "[$($i + 1)] $name :: $snippet"
  }

  Mark-StepComplete $state 10
}

function Step11-ShowEnv([hashtable]$state) {
  Write-Host ''
  Write-Host 'Use these values in your app runtime settings:'
  Write-Host "AZURE_AI_SEARCH_ENDPOINT=$($state.SearchEndpoint)"
  Write-Host "AZURE_AI_SEARCH_INDEX_NAME=$($state.IndexName)"
  Write-Host "AZURE_STORAGE_ACCOUNT_NAME=$($state.StorageAccountName)"
  Write-Host "AZURE_STORAGE_CONTAINER_NAME=$($state.PdfContainerName)"
  Write-Host ''
  Write-Host "State file: $StatePath"

  Mark-StepComplete $state 11
}

if ($ResetState -and (Test-Path $StatePath)) {
  Remove-Item -Path $StatePath -Force
}

$state = Load-State

while ($true) {
  Show-Menu -state $state
  $choice = Read-Host 'Choose a step number'

  try {
    switch ($choice) {
      '1' { Step1-Prerequisites -state $state; Show-NextStepHint -completedStep 1 }
      '2' { Step2-SelectContextAndNames -state $state; Show-NextStepHint -completedStep 2 }
      '3' { Step3-CollectIdentityInputs -state $state; Show-NextStepHint -completedStep 3 }
      '4' { Step4-DeployInfra -state $state; Show-NextStepHint -completedStep 4 }
      '5' { Step5-ApplyRbac -state $state; Show-NextStepHint -completedStep 5 }
      '6' { Step6-PropagationCheck -state $state; Show-NextStepHint -completedStep 6 }
      '7' { Step7-CreateDatasourceAndIndex -state $state; Show-NextStepHint -completedStep 7 }
      '8' { Step8-CreateAndRunIndexer -state $state; Show-NextStepHint -completedStep 8 }
      '9' { Step9-UploadSamplePdf -state $state; Show-NextStepHint -completedStep 9 }
      '10' { Step10-SmokeQuery -state $state; Show-NextStepHint -completedStep 10 }
      '11' { Step11-ShowEnv -state $state; Show-NextStepHint -completedStep 11 }
      '0' {
        Save-State -state $state
        Write-Host 'Exiting.'
        break
      }
      default {
        Write-Host 'Invalid selection.'
      }
    }

    Save-State -state $state
  } catch {
    Write-Host "Step failed: $($_.Exception.Message)" -ForegroundColor Red
    Save-State -state $state
  }
}
