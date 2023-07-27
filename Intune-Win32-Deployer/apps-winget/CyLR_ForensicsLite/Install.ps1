# Get the current script's directory
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Specify the modules to be imported
$ModuleNames = @("Az.Accounts", "Az.Storage")

foreach ($ModuleName in $ModuleNames) {
    # Get the module folder path based on the script's directory
    $ModuleFolderPath = Join-Path -Path $scriptDir -ChildPath "Modules"

    # Find the module manifest file (*.psd1) in the respective subdirectory
    $ModuleFilePath = Get-ChildItem -Path $ModuleFolderPath -Filter "$ModuleName.psd1" -Recurse -File | Select-Object -ExpandProperty FullName -First 1

    # Check if the module file exists
    if ($ModuleFilePath) {
        Import-Module -Name $ModuleFilePath
    } else {
    }
}


function Invoke-CyLR {
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = "C:\intune\win32\cylr",
        [string]$LogFilePath = $logFile
    )

    try {
        # Get the computer name and timestamp
        $computerName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputFileName = "{0}_{1}_cylr_archive.zip" -f $computerName, $timestamp

        # Ensure the output directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
        }

        # Reference CyLR.exe dynamically based on the script's directory
        $cyLRPath = Join-Path -Path $scriptDir -ChildPath "CyLR.exe"

        # Run the CyLR command with the specified options and redirect the output to a log file
        $cmdOutputLogFileName = "{0}_{1}_CyLR_cmd_output.log" -f $computerName, $timestamp
        $cmdOutputLogPath = Join-Path -Path $OutputDirectory -ChildPath $cmdOutputLogFileName

        & $cyLRPath -od $OutputDirectory -of $OutputFileName *> $cmdOutputLogPath
    }
    catch {
        # Write-EnhancedLog -Message "Error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }

    return Join-Path -Path $OutputDirectory -ChildPath $OutputFileName
}

$azureAppId = "3c9b3719-36a9-47d3-881e-8321d6823592"
$azureTenantId = "8bb6061d-2d46-4095-9f9e-41cfcbc1e9f1"
$azurePassword = ConvertTo-SecureString "Ied8Q~SaDAA-.7csdNV0P35qB78NelrJFJ7Erds2" -AsPlainText -Force
$azureCredential = New-Object System.Management.Automation.PSCredential($azureAppId, $azurePassword)

Connect-AzAccount -ServicePrincipal -Credential $azureCredential -Tenant $azureTenantId


$resourceGroupName = "cylr2"
$storageAccountName = "cylrsa002"
$containerName = "cylcontainer002"
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$computerName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$blobName = "{0}_{1}_cylr_archive.zip" -f $computerName, $timestamp

# Invoke the function and store the output file path in a variable
$localFilePath = $null
$localFilePath = Invoke-CyLR

# Upload the file to Azure Storage
Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext
