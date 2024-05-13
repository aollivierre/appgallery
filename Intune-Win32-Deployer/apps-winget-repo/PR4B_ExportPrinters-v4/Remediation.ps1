#Unique Tracking ID: 44aff377-0a75-4a32-811d-102b5acd0fa5, Timestamp: 2024-03-10 14:50:44

# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$LoggingDeploymentName = $config.LoggingDeploymentName
    
function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "$LoggingDeploymentName" # Replace this with your actual deployment name
    $scriptPath = "C:\code\$deploymentName"
    # $hadError = $false
    
    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }
    
        $computerName = $env:COMPUTERNAME
        $Filename = "$LoggingDeploymentName"
        $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
        $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
            
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
            Write-Host "Created log file at $logPath" -ForegroundColor Green
        }
            
        $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
    
        $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
        $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
            
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Green
        }
    
        return @{
            ScriptPath  = $scriptPath
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }
    
    }
    catch {
        Write-Error "An error occurred while initializing script and logging: $_"
    }
}
$initializationInfo = Initialize-ScriptAndLogging
    
    
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']
    
    
    
    
function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
           
    )
    
    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }
    
    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}
    
    
    
function CreateEventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )
    
    
    # Validate parameters
    if (-not $LogName) {
        Write-Warning "LogName is required."
        return
    }
    if (-not $EventSource) {
        Write-Warning "Source is required."
        return
    }
    
    # Function to create event log and source
    function CreateEventLogSource($logName, $EventSource) {
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                New-EventLog -LogName $logName -Source $EventSource
            }
            else {
                [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $logName)
            }
            Write-Host "Event source '$EventSource' created in log '$logName'" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    }
    
    # Check if the event log exists
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        # CreateEventLogSource $LogName $EventSource
    }
    # Check if the event source exists
    elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Unregister the source if it's registered with a different log
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
        }
        # CreateEventLogSource $LogName $EventSource
    }
    else {
        Write-Host "Event source '$EventSource' already exists in log '$LogName'" -ForegroundColor Yellow
    }
}
    
$LogName = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
$EventSource = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
    
# Call the Create-EventSourceAndLog function
CreateEventSourceAndLog -LogName $LogName -EventSource $EventSource
    
# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'
    
    
    
    
function Write-EventLogMessage {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
    
        [string]$LogName = "$LoggingDeploymentName",
        [string]$EventSource,
    
        [int]$EventID = 1000  # Default event ID
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    $hadError = $false
    
    try {
        if (-not $EventSource) {
            throw "EventSource is required."
        }
    
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $EventSource -EntryType Information -EventId $EventID -Message $Message
        }
        else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $EventSource
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $EventID)
        }
    
        # Write-host "Event log entry created: $Message" 
    }
    catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }
    
    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}
    
    
    
    
function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [switch]$UseModule = $false,
        [string]$Caller = (Get-PSCallStack)[0].Command
    )
    
    # Add timestamp, computer name, and log level to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
    # Set foreground color based on log level
    switch ($Level) {
        'INFO' { $ForegroundColor = [ConsoleColor]::Green }
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
    }
    
    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    # Write-output $formattedMessage
    Write-host $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
    # Append to CSV file
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
    # Adjust this line in your script where you call the function
    # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
    
}
    
function Export-EventLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        wevtutil epl $LogName $ExportPath
    
        if (Test-Path $ExportPath) {
            Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        else {
            Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
    catch {
        Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}
    
# # Example usage
# $LogName = '$LoggingDeploymentNameLog'
# # $ExportPath = 'Path\to\your\exported\eventlog.evtx'
# $ExportPath = "C:\code\$LoggingDeploymentName\exports\Logs\$logname.evtx"
# Export-EventLog -LogName $LogName -ExportPath $ExportPath
    
    
    
    
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
    
    
    
Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################






#################################################################################################################################
################################################# START Export FOLDER #############################################################
#################################################################################################################################


function Ensure-ExportsFolder {
    param (
        [string]$BasePath
    )

    # Construct the full path to the SSID exports folder
    $ExportsFolderPath = Join-Path -Path $BasePath -ChildPath "Exports"

    # Check if the folder exists
    if (Test-Path -Path $ExportsFolderPath) {
        # Folder exists, so remove it first
        Remove-Item -Path $ExportsFolderPath -Recurse -Force
        Start-Sleep 5
        Write-EnhancedLog -Message "Removed existing PRINTER exports folder: $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
    }
    
    # Create the folder anew
    New-Item -ItemType Directory -Path $ExportsFolderPath | Out-Null
    Write-EnhancedLog -Message "Created PRINTER exports folder at: $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    # Return the full path of the exports folder
    return $ExportsFolderPath
}

# Example usage
$BasePath = $PSScriptRoot # or any base path you'd like to use
$ExportsFolderPath = Ensure-ExportsFolder -BasePath $BasePath
Write-EnhancedLog -Message "Exports folder path: $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)


#################################################################################################################################
################################################# START Export FOLDER ###########################################################
#################################################################################################################################


#################################################################################################################################
################################################# START PRINTERS Export #########################################################
#################################################################################################################################



<#
.SYNOPSIS
Exports details of each printer installed on the system to separate files.

.DESCRIPTION
This PowerShell function iterates over all printers installed on the system and exports the details of each printer to a separate file. The files are saved in an "exports" directory within the script's root directory. It uses a custom logging function, Write-EnhancedLog, for logging messages with levels and colors.

.PARAMETER ExportPath
Specifies the path where printer details files will be exported. If not provided, it defaults to an 'exports' directory within the script's root directory.

.EXAMPLE
Export-PrintersToFiles -ExportPath "C:\CustomPath\Printers"

Exports the details of each printer to separate files within the specified custom path.

#>

# function Export-PrintersToFiles {
#     [CmdletBinding()]
#     Param (
#         # [string]$ExportPath = "$PSScriptRoot\exports"
#     )

#     Write-EnhancedLog -Message "Starting printer export process" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

#     # Ensure the export directory exists
#     if (-not (Test-Path -Path $ExportsFolderPath)) {
#         Write-EnhancedLog -Message "Creating export directory at $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         New-Item -ItemType Directory -Path $ExportsFolderPath | Out-Null
#     }

#     # Get all printers
#     $printers = Get-Printer

#     if ($printers.Count -eq 0) {
#         Write-EnhancedLog -Message "No printers found on the system" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
#         return
#     }

#     # Export each printer to a separate file
#     foreach ($printer in $printers) {
#         $PRINTER_fileName = "$ExportsFolderPath\$($printer.Name).txt"
#         Write-EnhancedLog -Message "Exporting printer $($printer.Name) to file $PRINTER_fileName" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

#         try {
#             $printer | Out-File -FilePath $PRINTER_fileName
#         }
#         catch {
#             Write-EnhancedLog -Message "Failed to export printer $($printer.Name): $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#             continue
#         }
#     }

#     Write-EnhancedLog -Message "Printer export process completed successfully" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# }



# Export-PrintersToFiles




function Export-PrintersToFiles {
    [CmdletBinding()]
    Param (
        [string]$ExportsFolderPath = "$PSScriptRoot\exports"
    )

    Write-EnhancedLog -Message "Starting printer export process" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # Ensure the export directory exists
    if (-not (Test-Path -Path $ExportsFolderPath)) {
        Write-EnhancedLog -Message "Creating export directory at $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        New-Item -ItemType Directory -Path $ExportsFolderPath | Out-Null
    }

    # Get all printers
    $printers = Get-Printer

    if ($printers.Count -eq 0) {
        Write-EnhancedLog -Message "No printers found on the system" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        return
    }

    # Export each printer to a separate file in both TXT and CSV formats
    foreach ($printer in $printers) {
        $PRINTER_fileName_txt = "$ExportsFolderPath\$($printer.Name).txt"
        $PRINTER_fileName_csv = "$ExportsFolderPath\$($printer.Name).csv"
        Write-EnhancedLog -Message "Exporting printer $($printer.Name) to file $PRINTER_fileName_txt and $PRINTER_fileName_csv" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        try {
            # Export to TXT with full details
            $printer | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | Out-File -FilePath $PRINTER_fileName_txt
            
            # Export to CSV for easier readability
            $printer | Select-Object * | Export-Csv -Path $PRINTER_fileName_csv -NoTypeInformation -Encoding UTF8
        }
        catch {
            Write-EnhancedLog -Message "Failed to export printer $($printer.Name): $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            continue
        }
    }

    Write-EnhancedLog -Message "Printer export process completed successfully" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}







Export-PrintersToFiles




#################################################################################################################################
################################################# END PRINTERS Export #########################################################
#################################################################################################################################




#################################################################################################################################
################################################# START VARIABLES ###############################################################
#################################################################################################################################

<#
.SYNOPSIS
Loads secrets from a JSON file.

.DESCRIPTION
This function reads a JSON file containing secrets and returns an object with these secrets.

.EXAMPLE
$secrets = Get-Secrets

.NOTES
Assumes the JSON file is named "secrets.json" and is located in the same directory as the script.
#>
function Get-Secrets {
	[CmdletBinding()]
	Param ()
    
	$secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"
	$secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json
	return $secrets
}




#First, load secrets and create a credential object:
$secrets = Get-Secrets


$ClientId = $secrets.clientId
$ClientSecret = $secrets.ClientSecret
$TenantName = "bcclsp.org"
$site_objectid = "6646347f-6339-4ddf-af21-2d63c3c685ca"

$document_drive_name = "Documents"

#################################################################################################################################
################################################# END VARIABLES #################################################################
#################################################################################################################################


#################################################################################################################################
################################################# START GRAPH CONNECTING ########################################################
#################################################################################################################################


# Define functions
function Get-MicrosoftGraphAccessToken {
    $tokenBody = @{
        Grant_Type    = 'client_credentials'  
        Scope         = 'https://graph.microsoft.com/.default'  
        Client_Id     = $clientId  
        Client_Secret = $clientSecret
    }  

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

    return $tokenResponse.access_token
}


#################################################################################################################################
################################################# END Connecting to Graph #######################################################
#################################################################################################################################


function Get-SharePointDocumentDriveId {
    $url = "https://graph.microsoft.com/v1.0/groups/$site_objectid/sites/root"
    $subsite_ID = (Invoke-RestMethod -Headers $headers -Uri $URL -Method Get).ID

    $url = "https://graph.microsoft.com/v1.0/sites/$subsite_ID/drives"
    $drives = Invoke-RestMethod -Headers $headers -Uri $url -Method Get

    $document_drive_id = ($drives.value | Where-Object { $_.name -eq $document_drive_name }).id

    return $document_drive_id
}
function New-SharePointFolder {
    param($document_drive_id, $parent_folder_path, $folder_name)

    try {
        # Check if the folder already exists
        $check_url = "https://graph.microsoft.com/v1.0/drives/" + $document_drive_id + "/root:/" + $parent_folder_path + ":/children"
        $existing_folders = Invoke-RestMethod -Headers $headers -Uri $check_url -Method GET
        $existing_folder = $existing_folders.value | Where-Object { $_.name -eq $folder_name -and $_.folder }

        if ($existing_folder) {
            Write-EnhancedLog "Folder '$folder_name' already exists in '$parent_folder_path'. Skipping folder creation."
            return $existing_folder
        }
    }
    catch {
        Write-EnhancedLog "Folder '$folder_name' not found in '$parent_folder_path'. Proceeding with folder creation."
    }

    # If the folder does not exist, create it
    $url = "https://graph.microsoft.com/v1.0/drives/" + $document_drive_id + "/root:/" + $parent_folder_path + ":/children"

    $body = @{
        "@microsoft.graph.conflictBehavior" = "fail"
        "name"                              = $folder_name
        "folder"                            = @{}
    }

    Write-EnhancedLog "Creating folder '$folder_name' in '$parent_folder_path'..."
    $created_folder = Invoke-RestMethod -Headers $headers -Uri $url -Body ($body | ConvertTo-Json) -Method POST
    Write-EnhancedLog "Folder created successfully."
    return $created_folder
}


<#
.SYNOPSIS
Zips the specified folder.

.DESCRIPTION
This function takes a folder path as input and compresses it into a zip file. It logs the process using a custom logging function, Write-EnhancedLog. The zip file is created in the same directory as the folder.

.PARAMETER FolderPath
The path of the folder to be zipped.

.PARAMETER DestinationZipPath
The full path where the zip file should be saved. If not provided, the zip file is named after the folder and placed in the same directory as the folder.

.EXAMPLE
Zip-Folder -FolderPath "$PSScriptRoot\exports"

Compresses the "exports" folder into "exports.zip" in the "$PSScriptRoot" directory.
#>

function Zip-Folder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [string]$DestinationZipPath
    )

    if (-not $DestinationZipPath) {
        $DestinationZipPath = "$FolderPath.zip"
    }

    Write-EnhancedLog -Message "Starting to zip folder: $FolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    try {
        Compress-Archive -Path $FolderPath -DestinationPath $DestinationZipPath -Force
        
        # Check if the zip file was actually created
        if (Test-Path -Path $DestinationZipPath) {
            Write-EnhancedLog -Message "Successfully zipped folder to: $DestinationZipPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        } else {
            Write-EnhancedLog -Message "Zip file was not created due to an unknown error." -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            throw "Zip file creation failed."
        }
    }
    catch {
        Write-EnhancedLog -Message "Failed to zip folder: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        throw $_
    }
}

# Zip the exports folder
Zip-Folder -FolderPath $exportsFolderPath

# Define the path to the zipped file (assuming default naming)
$zippedExportsPath = "$exportsFolderPath.zip"

function Upload-FileToSharePoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$document_drive_id,

        [Parameter(Mandatory = $true)]
        [string]$File_Path,  # Assume this is the path to the zipped file created by Zip-Folder

        [Parameter(Mandatory = $true)]
        [string]$folder_name

        # [Parameter(Mandatory = $true)]
        # [string]$accessToken
    )

    try {
        # Adding detailed information about what is being uploaded and where
        Write-EnhancedLog -Message "Preparing to upload file to SharePoint. File Path: $File_Path, Destination: $folder_name on drive ID: $document_drive_id" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        # Ensure the zip file exists before attempting to upload
        if (-not (Test-Path -Path $File_Path)) {
            Write-EnhancedLog -Message "Zip file does not exist at path: $File_Path" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            throw "Zip file not found."
        }

        # Reading the zip file content as a byte array
        $fileContent = [System.IO.File]::ReadAllBytes($File_Path)
        $filename = [System.IO.Path]::GetFileName($File_Path)

        # Constructing the PUT URL for SharePoint
        $puturl = "https://graph.microsoft.com/v1.0/drives/$document_drive_id/root:/$folder_name/$($filename):/content"

        # Setting up the headers for upload
        # $upload_headers = @{
        #     "Authorization" = "Bearer $accessToken"
        #     "Content-Type"  = "application/zip"
        # }

        # Performing the file upload
        Write-EnhancedLog -Message "Uploading file: $filename to SharePoint folder: $folder_name on drive ID: $document_drive_id" -Level "VERBOSE" -ForegroundColor ([ConsoleColor]::Cyan)
        $uploadResponse = Invoke-RestMethod -Headers $headers -Uri $puturl -Method PUT -Body $fileContent -ContentType "application/octet-stream"
        
        # Success logging
        Write-EnhancedLog -Message "File: $filename uploaded successfully to SharePoint folder: $folder_name on drive ID: $document_drive_id." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    } catch {
        Write-EnhancedLog -Message "An error occurred during the upload process of $filename to SharePoint folder: $folder_name on drive ID: $document_drive_id $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        throw $_
    }
}



try {
    # Get an access token for the Microsoft Graph API
    $accessToken = Get-MicrosoftGraphAccessToken
    
    # Set up headers for API requests
    $headers = @{
        "Authorization" = "Bearer $($accessToken)"
        "Content-Type"  = "application/json"
    }

    # Get the ID of the SharePoint document drive
    $document_drive_id = Get-SharePointDocumentDriveId


    # ... (Previous code remains the same)

    # Get the computer name and detailed info
    $computerName = $env:COMPUTERNAME
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String
    $allScanResults = @()

    $detectedFolderPath = "PRINTERLogs"

    # Generate a report file containing the paths of the files found
    Write-EnhancedLog "Generating report..."
    $reportFileName = "ExportPRINTER_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
    $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

    # Add computer info and scan results to the report file
    $computerInfo | Set-Content -Path $reportFilePath
    $allScanResults | Add-Content -Path $reportFilePath


    # Create the "Infected" folder in SharePoint if it doesn't exist
    New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $detectedFolderPath -folder_name $computerName

    $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
    Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $detectedtargetFolderPath
    Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $detectedtargetFolderPath

}
catch {
    Write-EnhancedLog "An error occurred: $_"
}

Stop-Transcript



# Create a folder in SharePoint named after the computer
$computerName = $env:COMPUTERNAME
$parentFolderPath = "PRINTER"  # Change this to the desired parent folder path in SharePoint
New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $parentFolderPath -folder_name $computerName

# Upload the transcript log to the new SharePoint folder
$targetFolderPath = "$parentFolderPath/$computerName"
# Define the source path dynamically using $PSScriptRoot
$LocalFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Exports"

# Get all files in the folder
$FilesToUpload = Get-ChildItem -Path $LocalFolderPath -File -Recurse

foreach ($File in $FilesToUpload) {
    # For each file, upload it to SharePoint
    Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $File.FullName -folder_name $targetFolderPath
}

Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $zippedExportsPath -folder_name $targetFolderPath
