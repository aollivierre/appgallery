# Check if running as Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    # Get the ID and security principal of the current user account
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        # We are running "as Administrator" - so change the title and background color to indicate this
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
        $Host.UI.RawUI.BackgroundColor = "DarkBlue"
        clear-host
    }
    else {
        # We are not running "as Administrator" - so relaunch as administrator
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition;
        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";
        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);
        # Exit from the current, unelevated, process
        exit
    }
}

# Your script code goes here
Write-Output "Running as Administrator"



function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "UploadSmallFiletoSPOv2" # Replace this with your actual deployment name
    $scriptPath = "C:\_SPO\Upload\$deploymentName"
    # $hadError = $false

    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }

        $computerName = $env:COMPUTERNAME
        $Filename = "UploadtoSPO"
        $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
        $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
        
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
            Write-Host "Created log file at $logPath" -ForegroundColor Yellow
        }
        
        $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null

        $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
        $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
        
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Yellow
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




# $DBG

# $DBG


$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']

# $DBG


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


function CreateEventLogSource {
    param (
       
        [string]$LogName = 'UploadtoSPOLog'
    )

 


    $source = "UploadtoSPO"
 

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use New-EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            New-EventLog -LogName $logName -Source $source
            Write-Host "Event source '$source' created in log '$logName'" -ForegroundColor Green
            
        }
        else {
            Write-Host "Event source '$source' already exists" -ForegroundColor Yellow
         
        }
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
        
            Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
           
            Write-EnhancedLog -Message "Event source '$source' already exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }


}
CreateEventLogSource


function Write-EventLogMessage {
    param (
        [string]$Message,
        [string]$LogName = 'UploadtoSPOLog'
    )

    $ErrorActionPreference = 'SilentlyContinue'
    $source = "UploadtoSPO"
    $eventID = 1000
    $hadError = $false

    try {
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
        } else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $source
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
        }

        # Write-host "Event log entry created: $Message" 
    } catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }

    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}

function Write-BasicLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [string]$Caller = (Get-PSCallStack)[0].Command
    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Log the message using the PowerShell Logging Module
    # Write-Log -Level $Level -Message $Message

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}


$Message = "Finished Importing Modules"
Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)


#################################################################################################################################
################################################# START LOGGING ###################################################################
#################################################################################################################################




function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [switch]$UseModule = $false,

        [string]$Caller = (Get-PSCallStack)[0].Command

    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"
    

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}

#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################


$file_extension = ".detectUploadingSmallFiletoSPOv1"


function CreateDetectionFile {
    $ErrorActionPreference = 'SilentlyContinue'
    $filePath = "C:\_SPO\Upload\UploadtoSPO\detect$file_extension"
    $hadError = $false

    try {
        if (-not (Test-Path -Path (Split-Path $filePath))) {
            New-Item -ItemType Directory -Path (Split-Path $filePath) -Force
            Write-EnhancedLog -Message "Created detection directory: $(Split-Path $filePath)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }

        New-Item -ItemType File -Path $filePath -Force
        Write-EnhancedLog -Message "Created detection file: $filePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
    catch {
        Write-EnhancedLog -Message "Error creating detection file or directory: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        $hadError = $true
    }

    if (-not $hadError) {
        Write-EnhancedLog -Message "Detection file creation completed successfully. file C:\_SPO\Upload\UploadtoSPO\detect$file_extension " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
}

CreateDetectionFile



#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################


$clientId = 'your client ID goes here'
$clientSecret = 'your client secret goes here'
$tenantName = 'domainname.onmicrosoft.com'
$site_objectid = 'your M365 group ID from the M365 admin center URL goes URL'
$webhook_url = 'your webhook URL goes here'



# $DBG




$document_drive_name = "Documents"

# Set the file extension to scan for
# $file_extension = ".detectUploadingSmallFiletoSPOv1"

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

function Upload-FileToSharePoint {
    param($document_drive_id, $file_path, $folder_name)

    $content = Get-Content -Path $file_path
    $filename = (Get-Item -Path $file_path).Name

    $puturl = "https://graph.microsoft.com/v1.0/drives/$document_drive_id/root:/$folder_name/$($filename):/content"

    $upload_headers = @{
        "Authorization" = "Bearer $($accessToken)"
        "Content-Type"  = "text/plain"
    }

    $uploadResponse = Invoke-RestMethod -Headers $upload_headers -Uri $puturl -Body $content -Method PUT
}

function Send-TeamsMessage {
    param($webhook_url, $message_text)

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

    $Teamsresponse = Invoke-RestMethod @params
}

function Scan-FolderForExtension {
    param($folderPath, $fileExtension)

    Write-EnhancedLog "Scanning folder '$folderPath' for files with extension '$fileExtension'..."

    $results = @()

    if (Test-Path $folderPath) {
        $files = Get-ChildItem -Path $folderPath -Filter "*$fileExtension" -Recurse -File -ErrorAction SilentlyContinue
        Write-EnhancedLog "Get-ChildItem returned $($files.Count) files."
            
            
        $files | ForEach-Object {
            Write-EnhancedLog "Processing file: $($_.FullName)"
            $results += $_.FullName
        }
    }
    else {
        Write-EnhancedLog "Folder path '$folderPath' does not exist."
    }

    Write-EnhancedLog "Found $($results.Count) files with extension '$fileExtension' in folder '$folderPath'."

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

    # Get the ID of the SharePoint document drive
    $document_drive_id = Get-SharePointDocumentDriveId


    # ... (Previous code remains the same)

    # Get the computer name and detailed info
    $computerName = $env:COMPUTERNAME
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String

    # $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
    $allScanResults = @()

    # foreach ($drive in $drives) {
        $folderPath = "C:\_SPO\Upload\UploadtoSPO\"
        # $folderPath = $folderPath -replace "^C:", "$drive"

        Write-EnhancedLog "Scanning folder '$folderpath' for files with extension '$file_extension'..."
        $scanResults = Scan-FolderForExtension -folderPath $folderPath -fileExtension $file_extension
        $allScanResults += $scanResults
    # }



    $detectedFolderPath = "DetectedUploadingSmallFiletoSPOv1"
    $cleanFolderPath = "Clean"

    if ($allScanResults.Count -gt 0) {
        $messageText = "UploadingSmallFiletoSPOv1 detected on computer $computerName!"

    }
    else {
        $messageText = "Computer $computerName is clean"

    }

    # Generate a report file containing the paths of the files found
    Write-EnhancedLog "Generating report..."
    $reportFileName = "UploadingSmallFiletoSPOv1ScanReport_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
    $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

    # Add computer info and scan results to the report file
    $computerInfo | Set-Content -Path $reportFilePath
    $allScanResults | Add-Content -Path $reportFilePath

    # Send the report file to the specified Teams channel
    $messageText += Get-Content -Path $reportFilePath -Raw
    Write-EnhancedLog "Sending report to Teams channel..."
    Send-TeamsMessage -webhook_url $webhook_url -message_text $messageText
    Write-EnhancedLog "Report sent successfully."

    # Upload the specified file to SharePoint
    # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name



    if ($allScanResults.Count -gt 0) {

        # Create the "Infected" folder in SharePoint if it doesn't exist
        # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $detectedFolderPath
        New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $detectedFolderPath -folder_name $computerName

        # Upload the specified file to the "Infected" folder in SharePoint
        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $detectedFolderPath

        $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
        Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $detectedtargetFolderPath
        Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $detectedtargetFolderPath


    }
    else {
        Write-EnhancedLog "No files found with extension '$file_extension'."

        # Create the "Clean" folder in SharePoint if it doesn't exist
        # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $cleanFolderPath

        New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $cleanFolderPath -folder_name $computerName

        # Upload a "clean" report to the "Clean" folder in SharePoint
        $reportFileName = "CleanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
        Set-Content -Path $reportFilePath -Value "No files found with extension '$file_extension'."
        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $cleanFolderPath

        # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $targetFolderPath

        $cleandtargetFolderPath = "$cleanFolderPath/$computerName"
        Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $cleandtargetFolderPath
        Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $cleandtargetFolderPath

    }


}
catch {
    Write-EnhancedLog "An error occurred: $_"
}


# Get-secretvault | Unregister-SecretVault

# Remove variables and clear secrets
Remove-Variable -Name clientId
Remove-Variable -Name clientSecret
Remove-Variable -Name tenantName
Remove-Variable -Name site_objectid
Remove-Variable -Name webhook_url

# $Secrets.Clear()
# Remove-Variable -Name Secrets


# Stop transcript logging
Stop-Transcript

# Create a folder in SharePoint named after the computer
$computerName = $env:COMPUTERNAME
$parentFolderPath = "Logs"  # Change this to the desired parent folder path in SharePoint
New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $parentFolderPath -folder_name $computerName

# Upload the transcript log to the new SharePoint folder
$targetFolderPath = "$parentFolderPath/$computerName"
$logFilePath = $logFile
Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $logFilePath -folder_name $targetFolderPath



# $BIGFilePath = "C:\Users\NovaAdmin-Abdullah\Downloads\ExchangeServer2019-x64-CU13.ISO"
# Upload the transcript log to the new SharePoint folder
# $targetFolderPath = "$parentFolderPath/$computerName"
# $logFilePath = $logFile
# Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $BIGFilePath -folder_name $targetFolderPath







