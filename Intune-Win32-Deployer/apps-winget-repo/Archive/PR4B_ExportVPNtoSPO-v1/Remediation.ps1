# Read configuration from the JSON file
# Assign values from JSON to variables


<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>

# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$env:MYMODULE_CONFIG_PATH = $configPath

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
$Version = $config.Version
$PackageExecutionContext = $config.PackageExecutionContext
$RepetitionInterval = $config.RepetitionInterval
$ScriptMode = $config.ScriptMode




#fix permissions of the client app to add Intune permissions


# Read configuration from the JSON file
# Assign values from JSON to variables


<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>

# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$env:MYMODULE_CONFIG_PATH = $configPath



# # Load client secrets from the JSON file
# $secretsjsonPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"
# $secrets = Get-Content -Path $secretsjsonPath | ConvertFrom-Json

# # Variables from JSON file
# $tenantId = $secrets.tenantId
# $clientId = $secrets.clientId
# $CertThumbprint = $secrets.CertThumbprint

# $certPath = Join-Path -Path $PSScriptRoot -ChildPath 'graphcert.pfx'
# $CertPassword = $secrets.CertPassword

<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>


# Auxiliary function to detect OS and set the Modules folder path
function Get-ModulesFolderPath {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if ($PSVersionTable.Platform -eq 'Win32NT') {
            return "C:\code\modules"
        }
        elseif ($PSVersionTable.Platform -eq 'Unix') {
            return "/usr/src/modules"
        }
        else {
            throw "Unsupported operating system"
        }
    }
    else {
        $os = [System.Environment]::OSVersion.Platform
        if ($os -eq [System.PlatformID]::Win32NT) {
            return "C:\code\modules"
        }
        elseif ($os -eq [System.PlatformID]::Unix) {
            return "/usr/src/modules"
        }
        else {
            throw "Unsupported operating system"
        }
    }
}


# Store the outcome in $ModulesFolderPath
try {
    $ModulesFolderPath = Get-ModulesFolderPath
    Write-host "Modules folder path: $ModulesFolderPath"
}
catch {
    Write-Error $_.Exception.Message
}



function Get-ModulesScriptPathsAndVariables {   
    param (
        [string]$BaseDirectory,
        $ModulesFolderPath
    )

    try {
        # $ModulesFolderPath = Join-Path -Path $BaseDirectory -ChildPath "Modules"
        
        
        if (-not (Test-Path -Path $ModulesFolderPath)) {
            throw "Modules folder path does not exist: $ModulesFolderPath"
        }

        # Construct and return a PSCustomObject
        return [PSCustomObject]@{
            BaseDirectory     = $BaseDirectory
            ModulesFolderPath = $ModulesFolderPath
        }
    }
    catch {
        Write-Host "Error in finding Modules script files: $_" -ForegroundColor Red
        # Optionally, you could return a PSCustomObject indicating an error state
        # return [PSCustomObject]@{ Error = $_.Exception.Message }
    }
}

# Retrieve script paths and related variables
$DotSourcinginitializationInfo = Get-ModulesScriptPathsAndVariables -BaseDirectory $PSScriptRoot -ModulesFolderPath $ModulesFolderPath

# $DotSourcinginitializationInfo
$DotSourcinginitializationInfo | Format-List


function Import-ModuleWithRetry {
    <#
    .SYNOPSIS
    Imports a PowerShell module with retries on failure.

    .DESCRIPTION
    This function attempts to import a specified PowerShell module, retrying the import process up to a specified number of times upon failure. It also checks if the module path exists before attempting to import.

    .PARAMETER ModulePath
    The path to the PowerShell module file (.psm1) that should be imported.

    .PARAMETER MaxRetries
    The maximum number of retries to attempt if importing the module fails. Default is 3.

    .PARAMETER WaitTimeSeconds
    The number of seconds to wait between retry attempts. Default is 2 seconds.

    .EXAMPLE
    $modulePath = "C:\Modules\MyPowerShellModule.psm1"
    Import-ModuleWithRetry -ModulePath $modulePath

    Tries to import the module located at "C:\Modules\MyPowerShellModule.psm1", with up to 3 retries, waiting 2 seconds between each retry.

    .NOTES
    This function requires the `Write-EnhancedLog` function to be defined in the script for logging purposes.

    .LINK
    Write-EnhancedLog
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [int]$MaxRetries = 3,

        [int]$WaitTimeSeconds = 2
    )

    Begin {
        $retryCount = 0
        $isModuleLoaded = $false
        Write-Host "Starting to import module from path: $ModulePath"
        
        # Check if the module file exists before attempting to load it
        if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
            Write-Host "The module path '$ModulePath' does not exist."
            return
        }
    }

    Process {
        while (-not $isModuleLoaded -and $retryCount -lt $MaxRetries) {
            try {
                # Import-Module $ModulePath -ErrorAction Stop -Verbose
                Import-Module $ModulePath -ErrorAction Stop
                $isModuleLoaded = $true
                write-host "Module: $ModulePath imported successfully."
            }
            catch {
                $errorMsg = $_.Exception.Message
                Write-Host "Attempt $retryCount to load module failed: $errorMsg Waiting $WaitTimeSeconds seconds before retrying."
                Write-Host "Attempt $retryCount to load module failed with error: $errorMsg"
                Start-Sleep -Seconds $WaitTimeSeconds
            }
            finally {
                $retryCount++
            }

            if ($retryCount -eq $MaxRetries -and -not $isModuleLoaded) {
                Write-Host "Failed to import module after $MaxRetries retries."
                Write-Host "Failed to import module after $MaxRetries retries with last error: $errorMsg"
                break
            }
        }
    }

    End {
        if ($isModuleLoaded) {
            write-host "Module: $ModulePath loaded successfully."
        }
        else {
            Write-Host -Message "Failed to load module $ModulePath within the maximum retry limit."
        }
    }
}


function Import-LatestModulesLocalRepository {

    <#
.SYNOPSIS
    Imports the latest version of all modules found in the specified Modules directory.

.DESCRIPTION
    This function scans the Modules directory for module folders, identifies the latest version of each module,
    and attempts to import the module. If a module file is not found or if importing fails, appropriate error
    messages are logged.

.PARAMETER None
    This function does not take any parameters.

.NOTES
    This function assumes the presence of a custom function 'Import-ModuleWithRetry' for retrying module imports.

.EXAMPLE
    ImportLatestModules
    This example imports the latest version of all modules found in the Modules directory.
#>

    [CmdletBinding()]
    param (
        $ModulesFolderPath
    )

    Begin {
        # Get the path to the Modules directory
        # $modulesDir = Join-Path -Path $PSScriptRoot -ChildPath "Modules"
        # $modulesDir = "C:\code\Modules"

        # Get all module directories
        $moduleDirectories = Get-ChildItem -Path $ModulesFolderPath -Directory

        Write-Host "moduleDirectories is $moduleDirectories"

        # Log the number of discovered module directories
        write-host "Discovered module directories: $($moduleDirectories.Count)"  -ForegroundColor ([ConsoleColor]::Cyan)
    }

    Process {
        foreach ($moduleDir in $moduleDirectories) {
            # Get the latest version directory for the current module
            $latestVersionDir = Get-ChildItem -Path $moduleDir.FullName -Directory | Sort-Object Name -Descending | Select-Object -First 1

            if ($null -eq $latestVersionDir) {
                write-host "No version directories found for module: $($moduleDir.Name)" -ForegroundColor ([ConsoleColor]::Red)
                continue
            }

            # Construct the path to the module file
            $modulePath = Join-Path -Path $latestVersionDir.FullName -ChildPath "$($moduleDir.Name).psm1"

            # Check if the module file exists
            if (Test-Path -Path $modulePath) {
                # Import the module with retry logic
                try {
                    Import-ModuleWithRetry -ModulePath $modulePath
                    write-host "Successfully imported module: $($moduleDir.Name) from version: $($latestVersionDir.Name)"  -ForegroundColor ([ConsoleColor]::Green)
                }
                catch {
                    write-host "Failed to import module: $($moduleDir.Name) from version: $($latestVersionDir.Name). Error: $_"  -ForegroundColor ([ConsoleColor]::Red)
                }
            }
            else {
                write-host  "Module file not found: $modulePath" -ForegroundColor ([ConsoleColor]::Red)
            }
        }
    }

    End {
        write-host "Module import process completed using Import-LatestModulesLocalRepository from $moduleDirectories" -ForegroundColor ([ConsoleColor]::Cyan)
    }
}

Import-LatestModulesLocalRepository -ModulesFolderPath $ModulesFolderPath


# ################################################################################################################################
# ################################################ END MODULE LOADING ############################################################
# ################################################################################################################################




# Usage
try {
    Ensure-LoggingFunctionExists
    # Continue with the rest of the script here
    # exit
}
catch {
    Write-Host "Critical error: $_" -ForegroundColor Red
    exit
}

# ################################################################################################################################
# ################################################################################################################################
# ################################################################################################################################

# Setup logging
Write-EnhancedLog -Message "Script Started" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

# ################################################################################################################################
# ################################################################################################################################
# ################################################################################################################################

function InstallAndImportModulesPSGallery {

    <#
.SYNOPSIS
    Validates, installs, and imports required PowerShell modules specified in a JSON file.

.DESCRIPTION
    This function reads the 'modules.json' file from the script's directory, validates the existence of the required modules,
    installs any that are missing, and imports the specified modules into the current session.

.PARAMETER None
    This function does not take any parameters.

.NOTES
    This function relies on a properly formatted 'modules.json' file in the script's root directory.
    The JSON file should have 'requiredModules' and 'importedModules' arrays defined.

.EXAMPLE
    InstallAndImportModules
    This example reads the 'modules.json' file, installs any missing required modules, and imports the specified modules.
#>

    # Define the path to the modules.json file
    $moduleJsonPath = "$PSScriptRoot/modules.json"
    
    if (Test-Path -Path $moduleJsonPath) {
        try {
            # Read and convert JSON data from the modules.json file
            $moduleData = Get-Content -Path $moduleJsonPath | ConvertFrom-Json
            $requiredModules = $moduleData.requiredModules
            $importedModules = $moduleData.importedModules

            # Validate, Install, and Import Modules
            if ($requiredModules) {
                Install-Modules -Modules $requiredModules
            }
            if ($importedModules) {
                Import-Modules -Modules $importedModules
            }

            Write-EnhancedLog -Message "Modules installed and imported successfully." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        catch {
            Write-EnhancedLog -Message "Error processing modules.json: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        }
    }
    else {
        Write-EnhancedLog -Message "modules.json file not found." -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}

# Auxiliary Functions

# Execute InstallAndImportModulesPSGallery function
InstallAndImportModulesPSGallery





# ################################################################################################################################
# ################################################ END MODULE CHECKING ###########################################################
# ################################################################################################################################


# ################################################################################################################################
# ################################################ CALLING AS SYSTEM (Uncomment for debugging) ###################################
# ################################################################################################################################

# Assuming Invoke-AsSystem and Write-EnhancedLog are already defined
# Update the path to your actual location of PsExec64.exe

# Write-EnhancedLog -Message "calling Test-RunningAsSystem" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# if (-not (Test-RunningAsSystem)) {
#     $privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"

#     # Check if the private folder exists, and create it if it does not
#     if (-not (Test-Path -Path $privateFolderPath)) {
#         New-Item -Path $privateFolderPath -ItemType Directory | Out-Null
#     }
    
#     $PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"
    

#     Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

#     $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
#     Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem -TargetFolder $privateFolderPath

# }
# else {
#     Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# }



# ################################################################################################################################
# ################################################ END CALLING AS SYSTEM (Uncomment for debugging) ###############################
# ################################################################################################################################


    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################

# Define the variables to be used for the function
# $PSADTdownloadParams = @{
#     GithubRepository     = "psappdeploytoolkit/psappdeploytoolkit"
#     FilenamePatternMatch = "PSAppDeployToolkit*.zip"
#     ZipExtractionPath    = Join-Path "$PSScriptRoot\private" "PSAppDeployToolkit"
# }

# Call the function with the variables
# Download-PSAppDeployToolkit @PSADTdownloadParams



#################################################################################################################################
################################################# END DOWNLOADING PSADT #########################################################
#################################################################################################################################




###########################################################################################################################
###########################################################################################################################
###########################################################################################################################
###########################################################################################################################
###########################################################################################################################
###########################################################################################################################
#############################################STARTING THE MAIN FUNCTION LOGIC HERE#########################################
###########################################################################################################################
###########################################################################################################################
###########################################################################################################################



$global:Path_local = Set-LocalPathBasedOnContext



Write-EnhancedLog -Message "calling Initialize-ScriptVariables" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


# Invocation of the function and storing returned hashtable in a variable
# $initializationInfo = Initialize-ScriptVariables -PackageName "YourPackageName" -PackageUniqueGUID "YourGUID" -Version 1 -ScriptMode "YourMode"

# Call Initialize-ScriptVariables with splatting
$InitializeScriptVariablesParams = @{
    PackageName       = $PackageName
    PackageUniqueGUID = $PackageUniqueGUID
    Version           = $Version
    ScriptMode        = $ScriptMode
    PackageExecutionContext        = $PackageExecutionContext
}

$initializationInfo = Initialize-ScriptVariables @InitializeScriptVariablesParams

$initializationInfo

$global:PackageName = $initializationInfo['PackageName']
$global:PackageUniqueGUID = $initializationInfo['PackageUniqueGUID']
$global:Version = $initializationInfo['Version']
$global:ScriptMode = $initializationInfo['ScriptMode']
$global:Path_local = $initializationInfo['Path_local']
$global:Path_PR = $initializationInfo['Path_PR']
$global:schtaskName = $initializationInfo['schtaskName']
$global:schtaskDescription = $initializationInfo['schtaskDescription']
$global:PackageExecutionContext = $initializationInfo['PackageExecutionContext']


#################################################################################################################################
################################################# START Ensure-ScriptPathsExist #################################################
#################################################################################################################################




# Assuming $global:Path_local and $global:Path_PR are set from previous initialization
Ensure-ScriptPathsExist -Path_local $global:Path_local -Path_PR $global:Path_PR

if (-not (Test-Path -Path $global:Path_PR -PathType Container)) {
    Write-EnhancedLog -Message "Failed to create $global:Path_PR. Please check permissions and path validity." -Level "ERROR" -ForegroundColor ([System.ConsoleColor]::Red)
}
else {
    Write-EnhancedLog -Message "$global:Path_PR exists." -Level "INFO" -ForegroundColor ([System.ConsoleColor]::Green)
}


    
    
#################################################################################################################################
################################################# END Ensure-ScriptPathsExist ###################################################
#################################################################################################################################


#################################################################################################################################
################################################# START VARIABLES ###############################################################
#################################################################################################################################



#First, load secrets and create a credential object:
# $SecretsPath = (Join-Path -Path $PSScriptRoot -ChildPath "secrets.json")
$secretsjsonPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"
$secrets = Get-Secrets -SecretsPath $secretsjsonPath


# $ClientId = $secrets.clientId
# $ClientSecret = $secrets.ClientSecret
# $TenantName = "bcclsp.org"


# # Variables from JSON file
$tenantId = $secrets.tenantId
$clientId = $secrets.clientId
# $CertThumbprint = $secrets.CertThumbprint

$certPath = Join-Path -Path $PSScriptRoot -ChildPath 'graphcert.pfx'
$CertPassword = $secrets.CertPassword

# $TenantName = $secrets.TenantName
# $site_objectid = "6646347f-6339-4ddf-af21-2d63c3c685ca"
$siteObjectId = $secrets.SiteObjectId

# $document_drive_name = "Documents"
# $document_drive_name = "Documents"
$documentDriveName = $secrets.DocumentDriveName

#################################################################################################################################
################################################# END VARIABLES #################################################################
#################################################################################################################################


#################################################################################################################################
################################################# START GRAPH CONNECTING ########################################################
#################################################################################################################################


# # Define functions
# function Get-MicrosoftGraphAccessToken {
#     $tokenBody = @{
#         Grant_Type    = 'client_credentials'  
#         Scope         = 'https://graph.microsoft.com/.default'  
#         Client_Id     = $clientId  
#         Client_Secret = $clientSecret
#     }  

#     $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

#     return $tokenResponse.access_token
# }




# ################################################################################################################################
# ################################################################################################################################
$accessToken = Connect-GraphWithCert -tenantId $tenantId -clientId $clientId -certPath $certPath -certPassword $certPassword

Log-Params -Params @{accessToken = $accessToken }

Get-TenantDetails

# ################################################################################################################################
# ################################################################################################################################


# #################################################################################################################################
# ################################################# END Connecting to Graph #######################################################
# #################################################################################################################################



# #################################################################################################################################
# ################################################# Creating VPN Connection #######################################################
# #################################################################################################################################

# # Example usage
# $vpnConnectionName = "MyVPNConnection"
# $vpnServerAddress = "vpn.example.com"

# try {
#     # Create the VPN connection
#     New-VPNConnection -ConnectionName $vpnConnectionName -ServerAddress $vpnServerAddress -TunnelType 'Pptp'

#     # Validate VPN connection
#     if (Test-VPNConnection -ConnectionName $vpnConnectionName) {
#         Write-EnhancedLog -Message "VPN connection '$vpnConnectionName' is ready for use." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#     }
#     else {
#         Write-EnhancedLog -Message "VPN connection '$vpnConnectionName' validation failed." -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#     }
# }
# catch {
#     Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
# }



# #################################################################################################################################
# ################################################# END Creating VPN Connection (uncomment if needed) #############################
# #################################################################################################################################

#################################################################################################################################
################################################# START VPN Export #############################################################
#################################################################################################################################


# Example usage
$BasePath = $PSScriptRoot # or any base path you'd like to use

# Ensure the VPNExport folder exists
$ExportsFolderPath = Ensure-ExportsFolder -BasePath $BasePath
Write-EnhancedLog -Message "Exports folder path: $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

# Log parameters
Log-Params @{
    BasePath          = $BasePath
    ExportsFolderPath = $ExportsFolderPath
}

# Call the function to export VPN connections
Export-VPNConnectionsToXML -ExportFolder $ExportsFolderPath





#################################################################################################################################
################################################# END VPN Export ###############################################################
#################################################################################################################################



#################################################################################################################################
################################################# START UPLOADING EXPORTS TO SHAREPOINT #########################################
#################################################################################################################################











try {
    # Get an access token for the Microsoft Graph API
    # $accessToken = Get-MicrosoftGraphAccessToken
    
    # Set up headers for API requests
    $headers = @{
        "Authorization" = "Bearer $($accessToken)"
        "Content-Type"  = "application/json"
    }

    # Get the ID of the SharePoint document drive
    $documentDriveId = Get-SharePointDocumentDriveId -SiteObjectId $siteObjectId -DocumentDriveName $documentDriveName -Headers $headers

    Log-Params -Params @{document_drive_id = $documentDriveId }

    # Get the computer name and detailed info
    $computerName = $env:COMPUTERNAME
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String
    $allScanResults = @()

    $detectedFolderPath = "VPNLogs"

    # Generate a report file containing the paths of the files found
    Write-EnhancedLog -Message "Generating report..."
    $reportFileName = "ExportVPN_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
    $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

    # Add computer info and scan results to the report file
    $computerInfo | Set-Content -Path $reportFilePath
    $allScanResults | Add-Content -Path $reportFilePath

    # Create the "Infected" folder in SharePoint if it doesn't exist
    New-SharePointFolder -DocumentDriveId $documentDriveId -ParentFolderPath $detectedFolderPath -FolderName $computerName -Headers $headers

    $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
    Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $reportFilePath -FolderName $detectedtargetFolderPath -Headers $headers
    Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $CSVFilePath -FolderName $detectedtargetFolderPath -Headers $headers

}
catch {
    Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
}

# Stop-Transcript

# Create a folder in SharePoint named after the computer
$computerName = $env:COMPUTERNAME
$parentFolderPath = "VPN"  # Change this to the desired parent folder path in SharePoint
New-SharePointFolder -DocumentDriveId $documentDriveId -ParentFolderPath $parentFolderPath -FolderName $computerName -Headers $headers

# Upload the transcript log to the new SharePoint folder
$targetFolderPath = "$parentFolderPath/$computerName"
$LocalFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Exports"

# Get all files in the folder
$FilesToUpload = Get-ChildItem -Path $LocalFolderPath -File -Recurse

foreach ($File in $FilesToUpload) {
    Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $File.FullName -FolderName $targetFolderPath -Headers $headers
}


#################################################################################################################################
################################################# END UPLOADING EXPORTS TO SHAREPOINT ###########################################
#################################################################################################################################