# Define base directories and paths
$baseDir = "C:\TylerDev\mainline\repos\custext\client_independent\PublishedIMS\Integration\InSite\API"
$outputDir = "C:\TylerDev\mainline\repos\custext\client_independent\source\Integration\InSite\API"
$namespace = "Tyler.Odyssey.API.Shared"
$baseTypesSource = "C:\TylerDev\mainline\repos\ody\Production\Binary\Odyssey\API\Schema\BaseTypes.xsd"

# Get available API folders from the base directory
$apiFolders = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

# Display available APIs with index numbers
Write-Host "`n==== Available APIs ====" -ForegroundColor Cyan
for ($i = 0; $i -lt $apiFolders.Count; $i++) {
    Write-Host "$($i + 1): $($apiFolders[$i])"
}

# Prompt user to select an API by number or enter manually
$apiFolder = $null
do {
    $selection = Read-Host -Prompt "`nEnter the number of the API you want to update or type the name manually"

    if ($selection -match "^\d+$") {
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $apiFolders.Count) {
            $apiFolder = $apiFolders[$index]
        } else {
            Write-Host "[ERROR] Invalid selection. Please enter a valid number from the list." -ForegroundColor Red
        }
    } elseif ($apiFolders -contains $selection) {
        $apiFolder = $selection
    } else {
        Write-Host "[ERROR] The specified API folder does not exist. Try again." -ForegroundColor Red
    }
} until ($apiFolder)

Write-Host "`n[INFO] You selected API: $apiFolder" -ForegroundColor Green

# Schema type selection with numbered menu
$schemaOptions = @("Inbound - Incoming data (received)", "Outbound - Outgoing data (sent)", "Both - Process all schemas")
Write-Host "`n==== Select Schema Type ====" -ForegroundColor Cyan
for ($i = 0; $i -lt $schemaOptions.Count; $i++) {
    Write-Host "$($i + 1): $($schemaOptions[$i])"
}

# Prompt user to select schema type
$schemaChoice = $null
do {
    $schemaSelection = Read-Host -Prompt "`nEnter the number corresponding to the schema type"

    if ($schemaSelection -match "^\d+$") {
        $schemaIndex = [int]$schemaSelection - 1
        if ($schemaIndex -ge 0 -and $schemaIndex -lt $schemaOptions.Count) {
            $schemaChoice = $schemaOptions[$schemaIndex]
        } else {
            Write-Host "[ERROR] Invalid selection. Please enter a valid number from the list." -ForegroundColor Red
        }
    } else {
        Write-Host "[ERROR] Invalid input. Please enter a number." -ForegroundColor Red
    }
} until ($schemaChoice)

Write-Host "`n[INFO] You selected Schema Type: $schemaChoice" -ForegroundColor Green

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
    $isOutbound = $xsdFile -like "*Result.xsd"

    if (($schemaChoice -eq "Inbound - Incoming data (received)" -and $isOutbound) -or
        ($schemaChoice -eq "Outbound - Outgoing data (sent)" -and -not $isOutbound)) {
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

# Find the generated files (API.cs or APIResult.cs)
$generatedFiles = Get-ChildItem -Path $outputApiDir -Filter "$apiFolder*.cs"

foreach ($file in $generatedFiles) {
  # # Search for the original file in the repository
  $originalFile = Get-ChildItem -Path $outputDir -Recurse -Filter ($file.Name -replace "\.cs$", "Entity.cs") | Select-Object -First 1
  $originalFilePath = (Get-ChildItem -Path $outputDir -Recurse -Filter ($file.Name -replace "\.cs$", "Entity.cs") | Select-Object -First 1).DirectoryName.Split('\')[-2..-1] -join "\"

  # Start logging for each file with breaks
  Write-Host "`n================ Processing File: $($file.Name) ================`n" -ForegroundColor Cyan
  Write-Host "= [INFO] Full Directory Path: $outputApiDir =" -ForegroundColor Yellow

  # Truncated directory path for ease of reading
  $truncatedPath = $file.DirectoryName.Split('\')[-2..-1] -join "\"
  Write-Host "= [DEBUG] Searching for original file in $truncatedPath and subdirectories: $($file.Name) =" -ForegroundColor Cyan

  if ($originalFile) {
    # Output the full path of the found original file
    Write-Host "= [INFO] Found original file in: $originalFilePath =" -ForegroundColor Magenta
  } else {
    Write-Host "= [WARNING] No original file found yet. Looking for matching file to replace. =" -ForegroundColor Red
  }

  # Determine new file name
  $newFileName = $file.Name
  if ($newFileName -match "\.cs$") {
    $newFileName = $newFileName -replace "\.cs$", "Entity.cs"
  }

  $newFilePath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

  $truncatedOutputPath = $outputApiDir.Split('\')[-2..-1] -join "\"

  # Rename the file if needed
  if ($newFileName -ne $file.Name) {
    Write-Host "= [INFO] Renaming the newly created file $($file.Name) to $newFileName located at $truncatedOutputPath =" -ForegroundColor Cyan
    Rename-Item -Path $file.FullName -NewName $newFileName -Force
    $file = Get-Item -Path $newFilePath  # Update file reference
  }

  if ($originalFile) {
    # Move the newly generated file to the original directory, replacing the old one
    Write-Host "= [INFO] Replacing original file: $($originalFile.FullName.Split('\')[-2..-1] -join "\") with new version... =" -ForegroundColor Yellow
    Move-Item -Path $file.FullName -Destination $originalFile.FullName -Force
    Write-Host "= [SUCCESS] Replaced: $($originalFile.FullName.Split('\')[-2..-1] -join "\") =" -ForegroundColor Green
  } else {
    Write-Host "= [WARNING] No matching original file found in $truncatedOutputPath or its subdirectories for: $($newFileName). Keeping it in $($file.DirectoryName) =" -ForegroundColor Red
  }

  Write-Host "`n================ End of Log for: $($file.Name) ================" -ForegroundColor Cyan
}

# Final confirmation message
Write-Host "`n==== Process Complete ====" -ForegroundColor Cyan
Write-Host "[INFO] The files have been successfully created. You can find them here... $originalFilePath" -ForegroundColor Green

Read-Host -Prompt "`nPress Enter to exit"