# # Relaunch the script with elevated privileges
# $scriptPath = $MyInvocation.MyCommand.Path
# function RunAsAdmin {
#     # Check if the current process is running as administrator
#     $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
#     $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

#     if (-not $isAdmin) {
#         Write-Host "Running script as administrator..." -ForegroundColor Yellow

     
#         Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
#         exit
#     } else {
#         Write-Host "Script is running as administrator." -ForegroundColor Green
#     }
# }

# RunAsAdmin




function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "CollectingForensicswithCyLR" # Replace this with your actual deployment name
    $scriptPath = "C:\Intune\Win32\$deploymentName"
    # $hadError = $false

    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }

        $computerName = $env:COMPUTERNAME
        $Filename = "CollectingForensicswithCyLR"
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

    } catch {
        Write-Error "An error occurred while initializing script and logging: $_"
    }
}
$initializationInfo = Initialize-ScriptAndLogging




# #DBG

# #DBG


$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']

# #DBG


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


function Create-EventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )

    # Check if the event log exists, and if not, create it
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        try {
            New-EventLog -LogName $LogName -Source $EventSource
        } catch [System.InvalidOperationException] {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    } elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Get the existing log name for the event source
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName

        # If the existing log name is different from the desired log name, unregister the source and register it with the correct log name
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
            try {
                New-EventLog -LogName $LogName -Source $EventSource
            } catch [System.InvalidOperationException] {
                New-EventLog -LogName $LogName -Source $EventSource
            }
        }
    }
}

function Write-CustomEventLog {
    param (
        [string]$LogName,
        [string]$EventSource,
        [int]$EventID = 1000,
        [string]$EventMessage,
        [string]$Level = 'INFO'
    )

    # Map the Level to the corresponding EntryType
    switch ($Level) {
        'DEBUG'   { $EntryType = 'Information' }
        'INFO'    { $EntryType = 'Information' }
        'WARNING' { $EntryType = 'Warning' }
        'ERROR'   { $EntryType = 'Error' }
        default   { $EntryType = 'Information' }
    }

    # Write the event to the custom event log
    try {
        Write-EventLog -LogName $LogName -Source $EventSource -EventID $EventID -Message $EventMessage -EntryType $EntryType
    } catch [System.InvalidOperationException] {
        Write-Warning "Error writing to the event log. Make sure you run PowerShell as an Administrator."
    }
}

$LogName = (Get-Date -Format "HHmmss") + "_CollectingForensicswithCyLR"
$EventSource = (Get-Date -Format "HHmmss") + "_CollectingForensicswithCyLR"

# Call the Create-EventSourceAndLog function
Create-EventSourceAndLog -LogName $LogName -EventSource $EventSource

# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'


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
        'INFO'    { $ForegroundColor = [ConsoleColor]::Green }
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR'   { $ForegroundColor = [ConsoleColor]::Red }
    }

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor

    # Append to CSV file
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level


    Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage $formattedMessage -EventID 1001 -Level $Level
}

function Export-EventLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogName,
        [Parameter(Mandatory=$true)]
        [string]$ExportPath
    )

    try {
        wevtutil epl $LogName $ExportPath

        if (Test-Path $ExportPath) {
            Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        } else {
            Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    } catch {
        Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}








#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################




function Install-RequiredModules {

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $requiredModules = @("Az")

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {

            Write-EnhancedLog -Message "Installing module: $module" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
            Install-Module -Name $module -AllowClobber -Force -Scope Allusers
            Write-EnhancedLog -Message "Module: $module has been installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
            Write-EnhancedLog -Message "Module $module is already installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
    }

    $ImportedModules = @("Az")
    
    foreach ($Importedmodule in $ImportedModules) {
        if ((Get-Module -ListAvailable -Name $Importedmodule)) {
            Write-EnhancedLog -Message "Importing module: $Importedmodule" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
            Import-Module -Name $Importedmodule
            Write-EnhancedLog -Message "Module: $Importedmodule has been Imported" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
    }


}
# Call the function to install the required modules and dependencies
Install-RequiredModules







###############################################################################################################################
###############################################################################################################################
################################################ BEGINING AZURE AD APP details ################################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################

# Here's the list of permissions mapped to their corresponding IDs:

# Scope (Delegated) Permissions:

# 89fe6a52-be36-487e-b7d8-d061c450a026: Group.Read.All
# e1fe6dd8-ba31-4d61-89e7-88639da4683d: User.Read.All
# 205e70e5-aba6-4c52-a976-6d2d46c48043: Files.Read.All
# 65e50fdc-43b7-4915-933e-e8138f11f40a: Directory.Read.All
# 5a54b8b3-347c-476d-8f8e-42d5c7424d29: Calendars.Read
# Role (Application) Permissions:

# 62a82d76-70ea-41e2-9197-370581804d09: Directory.ReadAll
# 883ea226-0bf2-4a8f-9f9d-92c9162a727d: Group.ReadAll
# 332a536c-c7ef-4017-ab91-336970924f0d: User.ReadAll
# 9492366f-7969-46a4-8d15-ed1a20078fff: Files.ReadAll
# a82116e5-55eb-4c41-a434-62fe8a61c773: Calendars.Read
# 0c0bf378-bf22-4481-8f81-9e89a9b4960a: Directory.ReadWrite.All


$clientId = 'xxxxxxxxxxxxxxx-8321d6823592'
$clientSecret = 'xxxxxxxxxxxxxxxxx'
$tenantName = 'contoso.onmicrosoft.com'
# $groupObjectID = '7f764990-e69d-41fc-b62c-d833b16bb8ab'
$webhook_url = 'https://contoso.webhook.office.com/webhookb2/xxxxxxxxxxxxx'



###############################################################################################################################
###############################################################################################################################
################################################ END OF AZURE AD APP details ##################################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################




###############################################################################################################################
###############################################################################################################################
################################## BEGINING OF YOUR MAIN POWERSHELL SCRIPT WRAPPED AS WIN32####################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################

# Get the current script's directory
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
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
            # Write-EnhancedLog -Message "Creating output directory: $OutputDirectory" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
            New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
        }

        # Reference CyLR.exe dynamically based on the script's directory
        $cyLRPath = Join-Path -Path $scriptDir -ChildPath "CyLR.exe"

        # Run the CyLR command with the specified options and redirect the output to a log file
        $cmdOutputLogFileName = "{0}_{1}_CyLR_cmd_output.log" -f $computerName, $timestamp
        $cmdOutputLogPath = Join-Path -Path $OutputDirectory -ChildPath $cmdOutputLogFileName
        # Write-EnhancedLog -Message "Running CyLR command with output directory: $OutputDirectory, output file: $OutputFileName, and log file: $LogFilePath" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
        & $cyLRPath -od $OutputDirectory -of $OutputFileName *> $cmdOutputLogPath
    }
    catch {
        Write-EnhancedLog -Message "Error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }

    return Join-Path -Path $OutputDirectory -ChildPath $OutputFileName
}


# # Invoke the function and store the output file path in a variable
# $localFilePath = Invoke-CyLR

# # Upload the file to Azure Storage
# Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext


###############################################################################################################################
###############################################################################################################################
################################## END OF YOUR MAIN POWERSHELL SCRIPT WRAPPED AS WIN32#########################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################




# #DBG




$document_drive_name = "Documents"

# Set the file extension to scan for
# $file_extension = ".detectWin32CollectingForensicswithCyLRRemove"

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


    $groupObjectID = $null
    function Get-M365GroupObjectId {
        param (
            [Parameter(Mandatory=$true)]
            [string]$groupEmail
        )
    
        $url = "https://graph.microsoft.com/v1.0/groups"
        $groups = @()
    
        do {
            $response = Invoke-RestMethod -Headers $headers -Uri $url -Method Get
            $groups += $response.value
            $url = $response.'@odata.nextLink'
        } while ($url)


        # #DBG
    
        $group = $groups | Where-Object { $_.mail -eq $groupEmail }
    
        if ($group) {
            return $group.id
        } else {
            Write-EnhancedLog -Message "M365 Group not found with email address: $groupEmail check the Azure AD App permissions and make sure to add Group.ReadWrite.All under app permissions" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Yellow)
            return $null
        }
    }
    
    # $groupObjectID = Get-M365GroupObjectId -groupEmail "syslog@lhc.ca"


function Get-SharePointDocumentDriveId {
    $url = "https://graph.microsoft.com/v1.0/groups/$groupObjectID/sites/root"
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
        Write-EnhancedLog -Message "Checking for existing folder with URL: $check_url" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
        
        $existing_folders = Invoke-RestMethod -Headers $headers -Uri $check_url -Method GET
        Write-EnhancedLog -Message "Received response from server: $($existing_folders.value)" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
        
        $existing_folder = $existing_folders.value | Where-Object { $_.name -eq $folder_name -and $_.folder }
        Write-EnhancedLog -Message "Filtered existing folders: $($existing_folder)" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)

        if ($existing_folder) {
            Write-EnhancedLog -Message "Folder '$folder_name' already exists in '$parent_folder_path'. Skipping folder creation." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            return $existing_folder
        }
    }
    catch {

        Write-EnhancedLog -Message "Error encountered during folder $folder_name in $parent_folder_path check: $($_.Exception.Message). Likely because the folder $folder_name does not exist yet in $parent_folder_path Proceeding with folder creation." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Red)
        Write-EnhancedLog -Message "Folder '$folder_name' not found in '$parent_folder_path'. Proceeding with folder creation." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
    }

    # If the folder does not exist, create it
    $url = "https://graph.microsoft.com/v1.0/drives/" + $document_drive_id + "/root:/" + $parent_folder_path + ":/children"

    $body = @{
        "@microsoft.graph.conflictBehavior" = "fail"
        "name"                              = $folder_name
        "folder"                            = @{}
    }

    try {
        Write-EnhancedLog -Message "Creating folder '$folder_name' in '$parent_folder_path'..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        $created_folder = Invoke-RestMethod -Headers $headers -Uri $url -Body ($body | ConvertTo-Json) -Method POST
        Write-EnhancedLog -Message "Folder created successfully. Folder ID: $($created_folder.id)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        return $created_folder
    }
    catch {
        Write-EnhancedLog -Message "Error creating folder '$folder_name' in '$parent_folder_path' : $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        throw $_
    }
}



function Upload-FileToSharePoint {
    param($document_drive_id, $file_path, $folder_name)

    try {
        $SPOUploadfilename = Split-Path -Path $file_path -Leaf
        $puturl = "https://graph.microsoft.com/v1.0/drives/$document_drive_id/root:/$folder_name/$($SPOUploadfilename):/content"

        $upload_headers = @{
            "Authorization" = "Bearer $($accessToken)"
        }

        Write-EnhancedLog -Message "Uploading file '$SPOUploadfilename' to '$putUrl'..." -Level 'INFO' -ForegroundColor Green

        Invoke-RestMethod -Uri $putUrl -Headers $upload_headers -Method Put -InFile $file_path -ContentType 'multipart/form-data'

        Write-EnhancedLog -Message "File '$SPOUploadfilename' was uploaded to '$putUrl'" -Level 'INFO' -ForegroundColor Green
    } catch {
        Write-EnhancedLog -Message "Error encountered while uploading file '$SPOUploadfilename' to '$putUrl': $_" -Level 'ERROR' -ForegroundColor Red
    }
}










function Send-TeamsMessage {
    param($webhook_url, $message_text)

    try {
        $message = @{
            "@type"    = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "text"     = $message_text
        }

        $params = @{
            'ContentType' = 'application/json'
            'Method'      = 'POST'
            'Body'        = ($message | ConvertTo-Json)
            'Uri'         = $webhook_url
        }

        Write-EnhancedLog -Message "Sending message to Microsoft Teams: '..." -Level 'INFO' -ForegroundColor Green

        $Teamsresponse = Invoke-RestMethod @params

        Write-EnhancedLog -Message "Message sent to Microsoft Teams successfully." -Level 'INFO' -ForegroundColor Green
    } catch {
        Write-EnhancedLog -Message "Error encountered while sending message to Microsoft Teams: $_" -Level 'ERROR' -ForegroundColor Red
    }
}


function Scan-FolderForExtension {
    param($folderPath, $fileExtension)

    Write-EnhancedLog -Message "Scanning folder '$folderPath' for files with extension '$fileExtension'..." -Level 'INFO'

    $results = @()

    try {
        if (Test-Path $folderPath) {
            $files = Get-ChildItem -Path $folderPath -Filter "*$fileExtension" -Recurse -File -ErrorAction SilentlyContinue
            Write-EnhancedLog -Message "Get-ChildItem returned $($files.Count) files." -Level 'DEBUG'

            $files | ForEach-Object {
                Write-EnhancedLog -Message "Processing file: $($_.FullName)" -Level 'DEBUG' -ForegroundColor DarkYellow
                $results += $_.FullName
            }
        }
        else {
            Write-EnhancedLog -Message "Folder path '$folderPath' does not exist." -Level 'WARNING' -ForegroundColor Yellow
        }
    } catch {
        Write-EnhancedLog -Message "Error encountered while scanning folder '$folderPath' for files with extension '$fileExtension': $_" -Level 'ERROR' -ForegroundColor Red
    }

    Write-EnhancedLog -Message "Found $($results.Count) files with extension '$fileExtension' in folder '$folderPath'." -Level 'INFO'

    return $results
}




try {
    # Get an access token for the Microsoft Graph API
    $accessToken = Get-MicrosoftGraphAccessToken
    
    # Set up headers for API requests
    $headers = @{
        "Authorization" = "Bearer $($accessToken)"
        "Content-Type"  = "application/json"
    }


    # $groupObjectID = Get-M365GroupObjectId -groupDisplayName "Syslog"

    $groupObjectID = Get-M365GroupObjectId -groupEmail "SysLog@cna-aiic.ca"


    # $DBG

    # Get the ID of the SharePoint document drive
    $document_drive_id = Get-SharePointDocumentDriveId


    # ... (Previous code remains the same)

    # Get the computer name and detailed info
    $computerName = $env:COMPUTERNAME
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String

    # $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
    $allScanResults = @()

    # foreach ($drive in $drives) {
        $folderPath = "C:\intune\Win32\CollectingForensicswithCyLR\"
        # $folderPath = $folderPath -replace "^C:", "$drive"

        # Write-EnhancedLog "Scanning folder '$folderpath' for files with extension '$file_extension'..."
        # $scanResults = Scan-FolderForExtension -folderPath $folderPath -fileExtension $file_extension
        # $allScanResults += $scanResults
    # }



    $detectedFolderPath = "DetectedCollectingForensicswithCyLR"
    $cleanFolderPath = "Clean"

    if ($allScanResults.Count -gt 0) {
        $messageText = "CollectingForensicswithCyLR detected on computer $computerName!"

    }
    else {
        $messageText = "Computer $computerName CyLR logs are now uploaded - review logs uploaded on SharePoint online 'Syslog' for more details"

    }

    # Generate a report file containing the paths of the files found
    Write-EnhancedLog "Generating report..."
    $reportFileName = "CollectingForensicswithCyLRScanReport_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
    $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

    # Add computer info and scan results to the report file
    $computerInfo | Set-Content -Path $reportFilePath
    $allScanResults | Add-Content -Path $reportFilePath

  

    # Upload the specified file to SharePoint
    # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name



    if ($allScanResults.Count -gt 0) {

        # Create the "Infected" folder in SharePoint if it doesn't exist
        # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $detectedFolderPath
        $null = New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $detectedFolderPath -folder_name $computerName

        # Upload the specified file to the "Infected" folder in SharePoint
        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $detectedFolderPath

        $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
        $null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $detectedtargetFolderPath
        $null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $detectedtargetFolderPath


    }
    else {
        Write-EnhancedLog "No files found with extension '$file_extension'."

        # Create the "Clean" folder in SharePoint if it doesn't exist
        # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $cleanFolderPath

        $null = New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $cleanFolderPath -folder_name $computerName

        # Upload a "clean" report to the "Clean" folder in SharePoint
        $reportFileName = "CleanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
        Set-Content -Path $reportFilePath -Value "No files found with extension '$file_extension'."
        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $cleanFolderPath

        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $targetFolderPath

        $cleandtargetFolderPath = "$cleanFolderPath/$computerName"
        $null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $cleandtargetFolderPath
        $null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $cleandtargetFolderPath

    }


}
catch {
    Write-EnhancedLog "An error occurred: $_"
}


# Get-secretvault | Unregister-SecretVault



  # Send the report file to the specified Teams channel
#   $messageText += Get-Content -Path $reportFilePath -Raw


# Remove variables and clear secrets


# $Secrets.Clear()
# Remove-Variable -Name Secrets


# Stop transcript logging
Stop-Transcript


# Example usage
$EvenlogExportPath = Join-Path -Path $logPath -ChildPath "$LogName-Transcript.evtx"
Export-EventLog -LogName $LogName -ExportPath $EvenlogExportPath

# Create a folder in SharePoint named after the computer
$computerName = $env:COMPUTERNAME
$parentFolderPath = "Logs"  # Change this to the desired parent folder path in SharePoint
$null = New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $parentFolderPath -folder_name $computerName

# Upload the transcript log to the new SharePoint folder
$targetFolderPath = "$parentFolderPath/$computerName"
$logFilePath = $logFile
$null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $logFilePath -folder_name $targetFolderPath


# Upload the Event log to the new SharePoint folder
$targetFolderPath = "$parentFolderPath/$computerName"
$EventlogFilePath = $EvenlogExportPath
$null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $EventlogFilePath -folder_name $targetFolderPath



# Upload the Event log to the new SharePoint folder
# $CyLRExportPath = "C:\Intune\Win32\cylr\cylr_archive.zip"
# $targetFolderPath = "$parentFolderPath/$computerName"
# $CyLRFilePath = $CyLRExportPath
# $null = Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CyLRFilePath -folder_name $targetFolderPath



$azureAppId = "xxxxxxxxxxxxxxxxx-8321d6823592"
$azureTenantId = "8bb6061d-2d46-4095-9f9e-41cfcbc1e9f1"
$azurePassword = ConvertTo-SecureString "xxxxxxxxxxxxxxxxxxxxxxxxx" -AsPlainText -Force
$azureCredential = New-Object System.Management.Automation.PSCredential($azureAppId, $azurePassword)

Connect-AzAccount -ServicePrincipal -Credential $azureCredential -Tenant $azureTenantId



# Install-Module -Name Az -AllowClobber -Scope AllUsers
# Connect-AzAccount
# $resourceGroupName = "YourResourceGroupName"
$resourceGroupName = "cylr2"
# $location = "YourAzureLocation"
$location = "West US 3"
# $storageAccountName = "YourStorageAccountName"
$storageAccountName = "cylrsa002"

# New-AzResourceGroup -Name $resourceGroupName -Location $location
# New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2
# $containerName = "YourContainerName"
$containerName = "cylcontainer002"
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# New-AzStorageContainer -Name $containerName -Context $storageContext
# $localFilePath = "C:\path\to\your\cylr_archive.zip"
# $localFilePath = "C:\Intune\Win32\cylr\cylr_archive.zip"
# $computerName = (Get-WmiObject -Class Win32_ComputerSystem).Name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$blobName = "{0}_{1}_cylr_archive.zip" -f $computerName, $timestamp


# Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext -Type Block


# Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext


# Invoke the function and store the output file path in a variable
$localFilePath = $null
$localFilePath = Invoke-CyLR

# $DBG

# Upload the file to Azure Storage
Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext


$messageText += Get-Content -Path $logFile -Raw
Write-EnhancedLog "Sending report to Teams channel..."
Send-TeamsMessage -webhook_url $webhook_url -message_text $messageText
Write-EnhancedLog "Report sent successfully."



# Remove variables and clear secrets
Remove-Variable -Name clientId
Remove-Variable -Name clientSecret
Remove-Variable -Name tenantName
Remove-Variable -Name groupObjectID
Remove-Variable -Name webhook_url
Remove-Variable -Name headers


Remove-Variable -Name azureAppId
Remove-Variable -Name azureTenantId
Remove-Variable -Name azurePassword
Remove-Variable -Name azureCredential



