<#
.Synopsis
Created on:   31/12/2021
Created by:   Ben Whitmore
Filename:     Install-Printer.ps1

Simple script to install a network printer from an INF file. The INF and required CAB files hould be in the same directory as the script if creating a Win32app

#### Win32 app Commands ####

Install:
powershell.exe -executionpolicy bypass -file .\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP "10.1.1.1" -PrinterName "Canon Printer Upstairs" -DriverName "Canon Generic Plus UFR II" -INFFile "CNLB0MA64.inf"

Uninstall:
powershell.exe -executionpolicy bypass -file .\Remove-Printer.ps1 -PrinterName "Canon Printer Upstairs"

Detection:
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\Canon Printer Upstairs
Name = "Canon Printer Upstairs"

.Example
.\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP "10.1.1.1" -PrinterName "Canon Printer Upstairs" -DriverName "Canon Generic Plus UFR II" -INFFile "CNLB0MA64.inf"
#>








function RunAsAdmin {
    # Check if the current process is running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Running script as administrator..." -ForegroundColor Yellow

        # Relaunch the script with elevated privileges
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    } else {
        Write-Host "Script is running as administrator." -ForegroundColor Green
    }
}

RunAsAdmin




function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "InstallingPrintDrviers" # Replace this with your actual deployment name
    $scriptPath = "C:\Intune\Win32\$deploymentName"
    # $hadError = $false

    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }

        $computerName = $env:COMPUTERNAME
        $Filename = "InstallingPrintDrviers"
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

$LogName = (Get-Date -Format "HHmmss") + "_InstallingPrintDrviers"
$EventSource = (Get-Date -Format "HHmmss") + "_InstallingPrintDrviers"

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








###############################################################################################################################
###############################################################################################################################
################################## BEGINING OF YOUR MAIN POWERSHELL SCRIPT WRAPPED AS WIN32####################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################

function Install-PrinterWithParameters {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String]$PortName,
        [Parameter(Mandatory = $True)]
        [String]$PrinterIP,
        [Parameter(Mandatory = $True)]
        [String]$PrinterName,
        [Parameter(Mandatory = $True)]
        [String]$DriverName,
        [Parameter(Mandatory = $True)]
        [String]$INFFile
    )

    # (paste the entire script here, replacing hard-coded parameters with the passed parameters)

#Reset Error catching variable
$Throwbad = $Null

#Run script in 64bit PowerShell to enumerate correct path for pnputil
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH -PortName $PortName -PrinterIP $PrinterIP -DriverName $DriverName -PrinterName $PrinterName -INFFile $INFFile
    }
    Catch {
        Write-Error "Failed to start $PSCOMMANDPATH"
        Write-Warning "$($_.Exception.Message)"
        $Throwbad = $True
    }
}

Write-EnhancedLog -Message "##################################"
Write-EnhancedLog -Message "Installation started"
Write-EnhancedLog -Message "##################################"
Write-EnhancedLog -Message "Install Printer using the following Messages..."
Write-EnhancedLog -Message "Port Name: $PortName"
Write-EnhancedLog -Message "Printer IP: $PrinterIP"
Write-EnhancedLog -Message "Printer Name: $PrinterName"
Write-EnhancedLog -Message "Driver Name: $DriverName"
Write-EnhancedLog -Message "INF File: $INFFile"

$INFARGS = @(
    "/add-driver"
    "$INFFile"
)

If (-not $ThrowBad) {

    Try {

        #Stage driver to driver store
        Write-EnhancedLog -Message "Staging Driver to Windows Driver Store using INF ""$($INFFile)"""
        Write-EnhancedLog -Message "Running command: Start-Process pnputil.exe -ArgumentList $($INFARGS) -wait -passthru"
        Start-Process pnputil.exe -ArgumentList $INFARGS -wait -passthru

    }
    Catch {
        Write-Warning "Error staging driver to Driver Store"
        Write-Warning "$($_.Exception.Message)"
        Write-EnhancedLog -Message "Error staging driver to Driver Store"
        Write-EnhancedLog -Message "$($_.Exception)"
        $ThrowBad = $True
    }
}

If (-not $ThrowBad) {
    Try {
    
        #Install driver
        $DriverExist = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
        if (-not $DriverExist) {
            Write-EnhancedLog -Message "Adding Printer Driver ""$($DriverName)"""
            Add-PrinterDriver -Name $DriverName -Confirm:$false
        }
        else {
            Write-EnhancedLog -Message "Print Driver ""$($DriverName)"" already exists. Skipping driver installation."
        }
    }
    Catch {
        Write-Warning "Error installing Printer Driver"
        Write-Warning "$($_.Exception.Message)"
        Write-EnhancedLog -Message "Error installing Printer Driver"
        Write-EnhancedLog -Message "$($_.Exception)"
        $ThrowBad = $True
    }
}

If (-not $ThrowBad) {
    Try {

        #Create Printer Port
        $PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
        if (-not $PortExist) {
            Write-EnhancedLog -Message "Adding Port ""$($PortName)"""
            Add-PrinterPort -name $PortName -PrinterHostAddress $PrinterIP -Confirm:$false
        }
        else {
            Write-EnhancedLog -Message "Port ""$($PortName)"" already exists. Skipping Printer Port installation."
        }
    }
    Catch {
        Write-Warning "Error creating Printer Port"
        Write-Warning "$($_.Exception.Message)"
        Write-EnhancedLog -Message "Error creating Printer Port"
        Write-EnhancedLog -Message "$($_.Exception)"
        $ThrowBad = $True
    }
}

If (-not $ThrowBad) {
    Try {

        #Add Printer
        $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
        if (-not $PrinterExist) {
            Write-EnhancedLog -Message "Adding Printer ""$($PrinterName)"""
            Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
        }
        else {
            Write-EnhancedLog -Message "Printer ""$($PrinterName)"" already exists. Removing old printer..."
            Remove-Printer -Name $PrinterName -Confirm:$false
            Write-EnhancedLog -Message "Adding Printer ""$($PrinterName)"""
            Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
        }

        $PrinterExist2 = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
        if ($PrinterExist2) {
            Write-EnhancedLog -Message "Printer ""$($PrinterName)"" added successfully"
        }
        else {
            Write-Warning "Error creating Printer"
            Write-EnhancedLog -Message "Printer ""$($PrinterName)"" error creating printer"
            $ThrowBad = $True
        }
    }
    Catch {
        Write-Warning "Error creating Printer"
        Write-Warning "$($_.Exception.Message)"
        Write-EnhancedLog -Message "Error creating Printer"
        Write-EnhancedLog -Message "$($_.Exception)"
        $ThrowBad = $True
    }
}

If ($ThrowBad) {
    Write-Error "An error was thrown during installation. Installation failed. Refer to the log file in %temp% for details"
    Write-EnhancedLog -Message "Installation Failed"
}




}

# Define your parameters
# $InfFilePath = "C:\temp\z97499L16\disk1\oemsetup.inf"
$InfFilePath = Join-Path -Path $PSScriptRoot -ChildPath "Driver\disk1\oemsetup.inf"
$PortName = "IP_10.0.0.47"
$PrinterIP = "10.0.0.47"
$DriverName = "RICOH MP C3504ex PCL 6"
$PrinterName = "LHC - RICOH MP C3504ex PCL 6"

# Call the function with the defined parameters
Install-PrinterWithParameters -PortName $PortName -PrinterIP $PrinterIP -PrinterName $PrinterName -DriverName $DriverName -INFFile $InfFilePath

###############################################################################################################################
###############################################################################################################################
################################## END OF YOUR MAIN POWERSHELL SCRIPT WRAPPED AS WIN32#########################################
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################




$clientId = 'xxxxxxxxxxx-e8dd7099e8e0'
$clientSecret = ''
$tenantName = 'contoso.onmicrosoft.com'
# $site_objectid = '7f764990-e69d-41fc-b62c-d833b16bb8ab'
# $site_objectid = '898b76df-8e5a-4f17-ba50-53c32d2dad50'
$webhook_url = 'https://contoso.webhook.office.com/webhookb2/xxxxxxxxxxxx'



# #DBG




$document_drive_name = "Documents"

# Set the file extension to scan for
# $file_extension = ".detectWin32InstallingPrintDrviersRemove"

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


    $site_objectid = $null
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
            Write-EnhancedLog -Message "M365 Group not found with email address: $groupEmail" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
            return $null
        }
    }
    
    # $site_objectid = Get-M365GroupObjectId -groupEmail "syslog@lhc.ca"


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
        Write-EnhancedLog -Message "Error creating folder: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
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


    # $site_objectid = Get-M365GroupObjectId -groupDisplayName "Syslog"

    $site_objectid = Get-M365GroupObjectId -groupEmail "syslog@lhc.ca"
    

    #DBG

    # Get the ID of the SharePoint document drive
    $document_drive_id = Get-SharePointDocumentDriveId


    # ... (Previous code remains the same)

    # Get the computer name and detailed info
    $computerName = $env:COMPUTERNAME
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String

    # $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
    $allScanResults = @()

    # foreach ($drive in $drives) {
        $folderPath = "C:\intune\Win32\InstallingPrintDrviers\"
        # $folderPath = $folderPath -replace "^C:", "$drive"

        # Write-EnhancedLog "Scanning folder '$folderpath' for files with extension '$file_extension'..."
        # $scanResults = Scan-FolderForExtension -folderPath $folderPath -fileExtension $file_extension
        # $allScanResults += $scanResults
    # }



    $detectedFolderPath = "DetectedInstallingPrintDrviers"
    $cleanFolderPath = "Clean"

    if ($allScanResults.Count -gt 0) {
        $messageText = "InstallingPrintDrviers detected on computer $computerName!"

    }
    else {
        $messageText = "Computer $computerName signatures is now restored - review logs uploaded on SharePoint online 'Syslog' for more details"

    }

    # Generate a report file containing the paths of the files found
    Write-EnhancedLog "Generating report..."
    $reportFileName = "InstallingPrintDrviersScanReport_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
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
  $messageText += Get-Content -Path $reportFilePath -Raw
  $messageText += Get-Content -Path $logFile -Raw
  Write-EnhancedLog "Sending report to Teams channel..."
  Send-TeamsMessage -webhook_url $webhook_url -message_text $messageText
  Write-EnhancedLog "Report sent successfully."

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


