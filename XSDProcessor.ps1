# Define base directories and paths
$baseDir = "C:\TylerDev\mainline\repos\custext\client_independent\PublishedIMS\Integration\InSite\API"
$outputDir = "C:\TylerDev\mainline\repos\custext\client_independent\source\Integration\InSite\API"
$namespace = "Tyler.Odyssey.API.Shared"
$baseTypesSource = "C:\TylerDev\mainline\repos\ody\Production\Binary\Odyssey\API\Schema\BaseTypes.xsd"

# Get available API folders from the base directory
$apiFolders = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

# Display available APIs and prompt user to select one
Write-Host "`n==== Available APIs ====" -ForegroundColor Cyan
$apiFolders | ForEach-Object { Write-Host "- $_" }
$apiFolder = Read-Host -Prompt "Enter the name of the API you want to update (e.g., LoadInSiteSearchResultSet)"

# Verify that the selected API folder exists
if (-not ($apiFolders -contains $apiFolder)) {
  Write-Host "`n[ERROR] The specified API folder '$apiFolder' does not exist." -ForegroundColor Red
  exit
}

# Prompt the user to select schema type to update (Inbound, Outbound, or Both)
$schemaChoice = Read-Host -Prompt "`nEnter the schema type to update (Inbound, Outbound, or Both)"

# Define schema directory and output directory based on the selected API
$schemaDir = Join-Path -Path $baseDir -ChildPath (Join-Path $apiFolder "Schema")
$outputApiDir = Join-Path -Path $outputDir -ChildPath $apiFolder

# Ensure the output directory exists
if (!(Test-Path -Path $outputApiDir)) {
  Write-Host "`nCreating output directory at '$outputApiDir'..." -ForegroundColor Yellow
  New-Item -ItemType Directory -Path $outputApiDir | Out-Null
}

# Copy BaseTypes.xsd to the schema directory if not already there
$baseTypesDestination = Join-Path -Path $schemaDir -ChildPath "BaseTypes.xsd"
if (!(Test-Path -Path $baseTypesDestination)) {
  Write-Host "`n[INFO] Copying BaseTypes.xsd to the schema directory..." -ForegroundColor Yellow
  Copy-Item -Path $baseTypesSource -Destination $baseTypesDestination -Force
} else {
  Write-Host "`n[INFO] BaseTypes.xsd already exists in the schema directory." -ForegroundColor Green
}

# Get all .xsd files in the schema directory
$xsdFiles = Get-ChildItem -Path $schemaDir -Filter "*.xsd" | Select-Object -ExpandProperty Name

# Check if there are any XSD files in the schema directory
if ($xsdFiles.Count -eq 0) {
  Write-Host "`n[ERROR] No XSD files found in the schema directory '$schemaDir'." -ForegroundColor Red
  exit
}

# Process each XSD file based on naming convention and schema choice
Write-Host "`n==== Processing XSD Files ====" -ForegroundColor Cyan
foreach ($xsdFile in $xsdFiles) {
  # Determine if it's an inbound or outbound schema based on file naming convention
  $isOutbound = $xsdFile -like "*Result.xsd"

  # Filter files based on user choice
  if (($schemaChoice -eq "Inbound" -and $isOutbound) -or
    ($schemaChoice -eq "Outbound" -and -not $isOutbound)) {
    Write-Host "[SKIPPED] Skipping '$xsdFile' as it does not match the chosen schema type." -ForegroundColor Gray
    continue
  }

  # Generate the full path and run the XSD command
  $fullPath = Join-Path -Path $schemaDir -ChildPath $xsdFile
  Write-Host "[INFO] Processing '$xsdFile'..." -ForegroundColor Green
  $command = "XSD.EXE `"$fullPath`" /classes /namespace:$namespace /o:`"$outputApiDir`""
  Write-Host "`tRunning: $command"
  Invoke-Expression $command
}

# Delete BaseTypes.xsd from the schema directory after processing
Remove-Item -Path $baseTypesDestination -Force
Write-Host "`n[INFO] Deleted BaseTypes.xsd from the schema directory." -ForegroundColor Green

Write-Host "`n==== Script Complete ====" -ForegroundColor Cyan
Write-Host "[INFO] Class generation from XSD files for API '$apiFolder' completed." -ForegroundColor Green