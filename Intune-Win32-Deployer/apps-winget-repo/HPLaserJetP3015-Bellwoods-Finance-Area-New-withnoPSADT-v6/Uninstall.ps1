#Unique Tracking ID: eb934004-9280-4ed1-8c21-a7c345802f61, Timestamp: 2024-03-11 01:58:18
# #Unique Tracking ID: 50ed2b1e-b96b-437b-b3ac-d035dc575793, Timestamp: 2024-02-15 13:23:30
# $d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# # Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe -DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden


# Start-Process -FilePath "$d_1002\Deploy-Application.exe" -ArgumentList "-DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden

# # Start-Process -FilePath ".\sara\SaRAcmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden
# # Start-Process -FilePath "C:\Users\AOllivierre_CloudAdm\Downloads\SaRACmd_17_01_0495_021\SaRACmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden



# function Remove-PrinterAndCleanup {
#     param(
#         [Parameter(Mandatory)]
#         [string]$PrinterName,
#         # [string]$DriverName,
#         [string]$PortName
#     )

#     # Remove Printer
#     if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
#         Remove-Printer -Name $PrinterName -Confirm:$false
#         # Write-Host "Printer '$PrinterName' removed."
#         Start-Sleep -Seconds 120
#     }

#     # Remove Printer Port
#     $portExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
#     if ($portExists) {
#         Remove-PrinterPort -Name $PortName -Confirm:$false
#         # Write-Host "Printer port '$PortName' removed."
#         Start-Sleep -Seconds 120
#     }
# }

# # Set parameters here
# $PrinterName = "HP LaserJet P3015 - Finance - New"
# # $DriverName = "SHARP MX-3071 PCL6" # Adjust as necessary
# $PortName = "IP_192.168.53.20" # Adjust as necessary
# # $InfFileName = "su2emenu.inf" # Adjust as necessary

# # Call the function with specified parameters
# # Remove-PrinterAndCleanup -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName -InfFileName $InfFileName
# # Remove-PrinterAndCleanup -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName
# Remove-PrinterAndCleanup -PrinterName $PrinterName -PortName $PortName





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



# # Determine the directory where the script is located
# # $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Define the path to the printer removal configuration JSON file
# $removePrinterConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# # Read configuration from the JSON file
# $removePrinterConfig = Get-Content -Path $removePrinterConfigPath -Raw | ConvertFrom-Json

# # Assign values from JSON to variables
# $PrinterName = $removePrinterConfig.PrinterName
# $PortName = $removePrinterConfig.PortName
# # Uncomment and adjust these if your JSON includes them and your function needs them
# # $DriverName = $removePrinterConfig.DriverName
# # $InfFileName = $removePrinterConfig.InfFileName

# # Call the function with parameters read from JSON
# # Adjust the function call according to which parameters are actually needed/used
# Remove-PrinterAndCleanup -PrinterName $PrinterName -PortName $PortName
# # Include these in the function call if applicable
# # -DriverName $DriverName -InfFileName $InfFileName





































<#
.SYNOPSIS
Removes a specified printer.

.DESCRIPTION
This function removes the printer with the given name if it exists.

.PARAMETER PrinterName
The name of the printer to be removed.

.EXAMPLE
Remove-PrinterByName -PrinterName "HP LaserJet P3015 - Finance - New"
#>
function Remove-PrinterByName {
    param (
        [Parameter(Mandatory=$true)]
        [string]$PrinterName
    )

    try {
        if (Get-Printer -Name $PrinterName -ErrorAction Stop) {
            Remove-Printer -Name $PrinterName -Confirm:$false
            Write-EnhancedLog -Message "Printer '$PrinterName' removed." -Level "INFO" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-EnhancedLog -Message "Failed to remove printer '$PrinterName': $_" -Level "ERROR" -ForegroundColor Red
    }
}


<#
.SYNOPSIS
Removes a specified printer port.

.DESCRIPTION
This function removes the printer port with the given name if it exists.

.PARAMETER PortName
The name of the printer port to be removed.

.EXAMPLE
Remove-PrinterPortByName -PortName "IP_192.168.53.20"
#>
function Remove-PrinterPortByName {
    param (
        [Parameter(Mandatory=$true)]
        [string]$PortName
    )

    try {
        $portExists = Get-PrinterPort -Name $PortName -ErrorAction Stop
        if ($portExists) {
            Remove-PrinterPort -Name $PortName -Confirm:$false
            Write-EnhancedLog -Message "Printer port '$PortName' removed." -Level "INFO" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-EnhancedLog -Message "Failed to remove printer port '$PortName': $_" -Level "ERROR" -ForegroundColor Red
    }
}



<#
.SYNOPSIS
Loads printer configuration from a JSON file.

.DESCRIPTION
This function reads the printer configuration from a specified JSON file and returns it as a custom object.

.PARAMETER ConfigPath
The path to the JSON configuration file.

.EXAMPLE
$printerConfig = Get-PrinterConfig -ConfigPath "printer.json"
#>
function Get-PrinterConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )

    try {
        if (Test-Path -Path $ConfigPath) {
            $configContent = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $configContent
        } else {
            Write-EnhancedLog -Message "Configuration file not found at path: $ConfigPath" -Level "ERROR" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-EnhancedLog -Message "Failed to read configuration file: $_" -Level "ERROR" -ForegroundColor Red
        return $null
    }
}



# Set the path to your configuration file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# Load the printer configuration
$printerConfig = Get-PrinterConfig -ConfigPath $configPath

if ($null -ne $printerConfig) {
    # Remove the printer and printer port based on the loaded configuration
    Remove-PrinterByName -PrinterName $printerConfig.PrinterName
    Remove-PrinterPortByName -PortName $printerConfig.PortName
}

