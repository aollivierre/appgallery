#Unique Tracking ID: 505c652b-4986-49e8-b0c6-96243b8ff939, Timestamp: 2024-02-24 21:07:37


# Define the source path of your config.json file
# Update this path to where the original config.json is located
# $sourceConfigPath = "C:\Path\To\Original\config.json"

# Output the $PSScriptRoot to understand the current script location
write-host "Script Root: $PSScriptRoot"

# Find the most recently created GUID-named folder under C:\Windows\IMECache\
$latestGUIDFolder = Get-ChildItem -Path 'C:\Windows\IMECache\' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# If a folder is found, proceed to locate config.json within it
if ($latestGUIDFolder) {
    $sourceConfigPath = Join-Path -Path $latestGUIDFolder.FullName -ChildPath "config.json"

    # Check if config.json exists in the found folder
    if (Test-Path -Path $sourceConfigPath) {
        # Define the destination path for config.json using $PSScriptRoot
        $destinationConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

        # Copy the config.json from the source to the destination path
        Copy-Item -Path $sourceConfigPath -Destination $destinationConfigPath -Force

        # Attempt to read the copied config.json file
        $config = Get-Content -Path $destinationConfigPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue

        # Output the path and content for verification
        # write-host "Config Path: $destinationConfigPath"
        # write-host "Config Content: $($config | Out-String)"
    } else {
        # write-host "config.json not found in the latest GUID folder: $($latestGUIDFolder.FullName)"
    }
} else {
    # write-host "No GUID-named folder found under C:\Windows\IMECache\"
}




# # Define the destination path for config.json using $PSScriptRoot
# $destinationConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

# # Copy the config.json from the source to the destination path
# Copy-Item -Path $sourceConfigPath -Destination $destinationConfigPath -Force

# Attempt to read the copied config.json file
# $config = Get-Content -Path $destinationConfigPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue

# Output the path and content for verification
# write-host "Config Path: $destinationConfigPath"
# write-host "Config Content: $($config | Out-String)"


# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# write-host "Config Path: $configPath"
# write-host "Config Content: $($config | Out-String)"


# write-host "config path: $configPath"
# write-host "config: $config"


# $logPath = Join-Path -Path $env:ProgramData -ChildPath "YourAppName\log.txt"

# # Logging function
# function Write-Log {
#     param ([string]$message)
#     Add-Content -Path $logPath -Value $message
# }

# Your existing script with added logging
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
# Write-Log "Attempting to read config from: $configPath"

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($config) {
    # Write-Log "Successfully read config: $config"
} else {
    # Write-Log "Failed to read config from: $configPath"
}

# Ensure the log file and folder have appropriate permissions for SYSTEM account access















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
    
    
    
# Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################




# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
$Version = $config.Version

$schtaskName = "$PackageName - $PackageUniqueGUID"

# Write-EnhancedLog -Message "Config: $config" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# Write-EnhancedLog -Message "LoggingDeploymentName: $LoggingDeploymentName" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# Write-EnhancedLog -Message "Package Name: $PackageName" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# Write-EnhancedLog -Message "Package Unique GUID: $PackageUniqueGUID" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# Write-EnhancedLog -Message "Package version: $Version" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# Write-EnhancedLog -Message "Scheduled task name $schtaskName" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

# Check if Task exist with correct version


# Write-EnhancedLog -Message "calling Get-ScheduledTask" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
$Task_existing = Get-ScheduledTask -TaskName $schtaskName -ErrorAction SilentlyContinue
if ($Task_existing.Description -like "Version $Version*") {

    # Write-EnhancedLog -Message "calling Get-ScheduledTask - done and found it" -Level "INFO" -ForegroundColor ([ConsoleColor]::GREEN)
    Write-Host "Found it!"

    # Write-Host "Stopping transcript..." -ForegroundColor Cyan
    # Stop-Transcript


    exit 0
}
else {

    # Write-EnhancedLog -Message "calling Get-ScheduledTask - did not find it" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    # Stop-Transcript
    exit 1
}
