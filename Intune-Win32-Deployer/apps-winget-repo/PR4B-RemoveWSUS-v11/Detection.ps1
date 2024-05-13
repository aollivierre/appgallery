#Unique Tracking ID: 6f5fbd30-1e24-4f68-a8aa-7de47f43c650, Timestamp: 2024-03-08 19:19:08
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
$initializationInfoLogging = Initialize-ScriptAndLogging
    
$initializationInfoLogging
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfoLogging['ScriptPath']
$Filename = $initializationInfoLogging['Filename']
$logPath = $initializationInfoLogging['LogPath']
$logFile = $initializationInfoLogging['LogFile']
$CSVFilePath = $initializationInfoLogging['CSVFilePath']
    
    
    
    
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



#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################
#################################################################################################################




function Initialize-RegistryCheckVariables {
    [CmdletBinding()]
    param ()

    # Logging the start of variable initialization
    Write-EnhancedLog -Message "Initializing script variables for registry checks..." -Level "INFO" -ForegroundColor ([System.ConsoleColor]::Green)

    # Initialize script-specific variables
    $registryPathWindowsUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $registryPathWindowsUpdateAU = "$registryPathWindowsUpdate\AU"

    $registryKeys = @('WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnabled')
    $registryValues = @{
        'UseWUServer'                = 0
        'NoAutoUpdate'               = 0
        'DisableWindowsUpdateAccess' = 0
    }

    # Package these variables into a hashtable for ease of access
    $initializedVariables = @{
        RegistryPathWindowsUpdate   = $registryPathWindowsUpdate
        RegistryPathWindowsUpdateAU = $registryPathWindowsUpdateAU
        RegistryKeys                = $registryKeys
        RegistryValues              = $registryValues
    }

    return $initializedVariables
}


# Calling Initialize-RegistryCheckVariables to set up our environment
$initializationInfoWU = Initialize-RegistryCheckVariables

# Extracting registry-specific variables from the initialization output
$RegistryPathWindowsUpdate = $initializationInfoWU['RegistryPathWindowsUpdate']
$RegistryPathWindowsUpdateAU = $initializationInfoWU['RegistryPathWindowsUpdateAU']
$RegistryKeys = $initializationInfoWU['RegistryKeys']
$RegistryValues = $initializationInfoWU['RegistryValues']

# Proceed with the script using these variables



<#
.SYNOPSIS
Checks for the presence of specified registry keys.

.DESCRIPTION
This function checks if the specified registry keys exist and returns $true if they are missing or set correctly.

.PARAMETER RegistryPath
The registry path to check the keys in.

.EXAMPLE
$missingOrCorrectKeys = Check-RegistryKeys -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
#>
function Check-RegistryKeys {
    param (
        [string]$RegistryPath,
        [string[]]$Keys # Add this parameter to accept keys
    )
    $Keys | ForEach-Object {
        $value = (Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue).$_
        $null -eq $value
    }
}




<#
.SYNOPSIS
Checks for the presence and correctness of specified registry values.

.DESCRIPTION
This function checks if the specified registry values exist and are set to the expected values. It returns $true for correct or missing values.

.PARAMETER RegistryPath1
The first registry path to check values in.

.PARAMETER RegistryPath2
The second registry path to check values in, for values specific to a sub-path.

.EXAMPLE
$correctValues = Check-RegistryValues -RegistryPath1 $rp1 -RegistryPath2 $rp2
#>
function Check-RegistryValues {
    param (
        [string]$RegistryPath1,
        [string]$RegistryPath2,
        [hashtable]$Values # Add this parameter to accept values
    )
    $Values.GetEnumerator() | ForEach-Object {
        $path = if ($_.Key -eq 'DisableWindowsUpdateAccess') { $RegistryPath1 } else { $RegistryPath2 }
        $value = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).$_.Key
        $value -eq $_.Value -or $null -eq $value
    }
}




<#
.SYNOPSIS
Performs checks on specific registry keys and values related to Windows Update settings to ensure they are set correctly.

.DESCRIPTION
This function assesses the presence and correctness of specified registry keys and values within the Windows Update and Windows Update AU (Automatic Updates) registry paths. It utilizes two auxiliary functions, Check-RegistryKeys and Check-RegistryValues, to perform the checks. If all keys and values are as expected, it logs a success message; otherwise, it logs a warning indicating that remediation is needed. In case of errors during the process, it logs an error message. The function concludes by exiting with a code that represents the outcome of the checks: 0 for success, 1 for incorrect settings, and 2 for errors.

.PARAMETER WindowsUpdateRegistryPath
The registry path for Windows Update settings. This should be the full path to the registry key where Windows Update settings are stored.

.PARAMETER WindowsUpdateAURegistryPath
The registry path for Windows Update AU (Automatic Updates) settings. This is a subpath or related path to WindowsUpdateRegistryPath where AU-specific settings are stored.

.EXAMPLE
Perform-RegistryChecks -WindowsUpdateRegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -WindowsUpdateAURegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

This example performs registry checks on the specified paths related to Windows Update and Automatic Updates settings. It uses the default keys and values defined within the Check-RegistryKeys and Check-RegistryValues functions to verify the settings' correctness.

.NOTES
Ensure that the Check-RegistryKeys and Check-RegistryValues functions are defined in your script or module and are accessible to Perform-RegistryChecks. These functions are essential for the operation of Perform-RegistryChecks.

#>



function Perform-RegistryChecks {
    param (
        [string]$WindowsUpdateRegistryPath,
        [string]$WindowsUpdateAURegistryPath
    )

    try {
        # Now, pass these variables as parameters to the functions
        $missingOrCorrectKeysResult = Check-RegistryKeys -RegistryPath $RegistryPathWindowsUpdate -Keys $RegistryKeys
        $correctValuesResult = Check-RegistryValues -RegistryPath1 $RegistryPathWindowsUpdate -RegistryPath2 $RegistryPathWindowsUpdateAU -Values $RegistryValues

        $missingOrCorrectKeys = $missingOrCorrectKeysResult -contains $false
        $correctValues = $correctValuesResult -contains $false

        if (-not $missingOrCorrectKeys -and -not $correctValues) {
            Write-EnhancedLog -Message "All registry keys and values are set correctly. No remediation needed." -Level "INFO" -ForegroundColor ([System.ConsoleColor]::Green)
            exit 0
        }
        else {
            Write-EnhancedLog -Message "Registry keys and/or values are incorrect. Remediation needed." -Level "WARNING" -ForegroundColor ([System.ConsoleColor]::Yellow)
            exit 1
        }
    }
    catch {
        Write-EnhancedLog -Message "An error occurred during registry checks: $_" -Level "ERROR" -ForegroundColor ([System.ConsoleColor]::Red)
        exit 2
    }
}

Perform-RegistryChecks -WindowsUpdateRegistryPath $RegistryPathWindowsUpdate -WindowsUpdateAURegistryPath $RegistryPathWindowsUpdateAU
