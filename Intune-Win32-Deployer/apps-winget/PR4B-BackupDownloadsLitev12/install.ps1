#Unique Tracking ID: 239f65ce-a4fe-4b0d-82ce-8295ad160753, Timestamp: 2024-02-26 14:44:46
<#
.SYNOPSIS
    Automates the detection and remediation of issues related to Bitlocker Escrow Recovery Key to Entra ID/Intune.

.DESCRIPTION
    This script, named "PR4B_BitLockerRecoveryEscrow" is designed to automate the process of detecting and remediating common issues associated with Bitlocker configurations on Windows systems. It leverages scheduled tasks to periodically check for and address these issues, ensuring that the system's Bitlocker settings remain optimal. The script includes functions for testing execution context, creating hidden VBScript wrappers for PowerShell, checking for existing tasks, executing detection and remediation scripts, and registering scheduled tasks with specific parameters.

.PARAMETER PackageName
    The name of the package, used for logging and task naming.

.PARAMETER Version
    The version of the script, used in task descriptions and for version control.

.FUNCTIONS
    Test-RunningAsSystem
        Checks if the script is running with System privileges.
        
    Create-VBShiddenPS
        Creates a VBScript to execute PowerShell scripts hidden.
        
    Check-ExistingTask
        Checks for the existence of a scheduled task based on name and version.
        
    Execute-DetectionAndRemediation
        Executes detection and remediation scripts based on the outcome of the detection.
        
    MyRegisterScheduledTask
        Registers a scheduled task with the system to automate the execution of this script.

.EXAMPLE
    .\PR4B_RemoveBitlocker.ps1
    Executes the script with default parameters, initiating the detection and remediation process.

.NOTES
    Author: Abdullah Ollivierre (Credits for Florian Salzmann)
    Contact: Organization IT
    Created on: Feb 07, 2024
    Last Updated: Feb 07, 2024

    This script is intended for use by IT professionals familiar with PowerShell and BitLocker. It should be tested in a non-production environment before being deployed in a live setting.

.VERSION HISTORY
    1.0 - Initial version.
    2.0 - Added VBScript creation for hidden execution.
    3.0 - Implemented scheduled task checking and updating based on script version.
    4.0 - Enhanced detection and remediation script execution process.
    5.0 - Introduced dynamic scheduling for task execution.
    6.0 - Optimized logging and transcript management.
    7.0 - Improved error handling and reporting mechanisms.
    8.0 - Current version, with various bug fixes and performance improvements.


    Unique Tracking ID: 215c2d78-1295-439e-8ff5-74e423f8717f
    
#>



# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
$Version = $config.Version
$PackageExecutionContext = $config.PackageExecutionContext
$RepetitionInterval = $config.RepetitionInterval
$ScriptMode = $config.ScriptMode


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




# $DBG


Write-Host "Initializing script variables..." -ForegroundColor Cyan

function Test-RunningAsSystem {
    Write-Host "Checking if running as System..." -ForegroundColor Magenta
    return [bool]($(whoami -user) -match "S-1-5-18")
}

function Create-VBShiddenPS {
    Write-Host "Creating VBScript to hide PowerShell window..." -ForegroundColor Magenta
    $scriptBlock = @"
    Dim shell,fso,file

    Set shell=CreateObject("WScript.Shell")
    Set fso=CreateObject("Scripting.FileSystemObject")

    strPath=WScript.Arguments.Item(0)

    If fso.FileExists(strPath) Then
        set file=fso.GetFile(strPath)
        strCMD="powershell -nologo -executionpolicy ByPass -command " & Chr(34) & "&{" & file.ShortPath & "}" & Chr(34)
        shell.Run strCMD,0
    End If
"@
    $Path_VBShiddenPS = Join-Path -Path "$global:Path_local\Data" -ChildPath "run-ps-hidden.vbs"
    $scriptBlock | Out-File -FilePath (New-Item -Path $Path_VBShiddenPS -Force) -Force
    return $Path_VBShiddenPS
}

function Check-ExistingTask {
    param (
        [string]$taskName,
        [string]$version
    )
    Write-Host "Checking for existing scheduled task..." -ForegroundColor Magenta
    $task_existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    return $task_existing.Description -like "Version $version*"
}

function Execute-DetectionAndRemediation {
    param (
        [string]$Path_PR
    )
    Write-Host "Executing detection and remediation scripts..." -ForegroundColor Magenta
    Set-Location $Path_PR
    .\detection.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Detection positive, remediation starts now" -ForegroundColor Green
        .\remediation.ps1
    }
    else {
        Write-Host "Detection negative, no further action needed" -ForegroundColor Yellow
    }
}


function MyRegisterScheduledTask {
    param (
        [string]$schtaskName,
        [string]$schtaskDescription,
        [string]$Path_vbs,
        [string]$Path_PSscript
    )

    Write-Host "Registering scheduled task..." -ForegroundColor Magenta

    # Get the current time plus one minute for the trigger start time
    $startTime = (Get-Date).AddMinutes(1).ToString("HH:mm")

    # Creating a basic daily trigger with the start time set dynamically
    $actionParams = @{
        Execute  = Join-Path $env:SystemRoot -ChildPath "System32\wscript.exe"
        Argument = "`"$Path_vbs`" `"$Path_PSscript`""
    }
    $action = New-ScheduledTaskAction @actionParams
    $trigger = New-ScheduledTaskTrigger -Daily -At $startTime

    # Setting principal
    $principalParams = @{
        UserID    = "NT AUTHORITY\SYSTEM"
        LogonType = "ServiceAccount"
        RunLevel  = "Highest"
    }
    $principal = New-ScheduledTaskPrincipal @principalParams

    # Register the task
    $task = Register-ScheduledTask -TaskName $schtaskName -Trigger $trigger -Action $action -Principal $principal -Description $schtaskDescription -Force


    # Updating the task to include repetition with a 5-minute interval
    $task = Get-ScheduledTask -TaskName $schtaskName
    $task.Triggers[0].Repetition.Interval = $RepetitionInterval
    $task | Set-ScheduledTask

    # Check the execution context specified in the config
    if ($PackageExecutionContext -eq "User") {
        # This code block will only execute if ExecutionContext is set to "User"

        # Connect to the Task Scheduler service
        $ShedService = New-Object -comobject 'Schedule.Service'
        $ShedService.Connect()

        # Get the folder where the task is stored (root folder in this case)
        $taskFolder = $ShedService.GetFolder("\")
    
        # Get the existing task by name
        $Task = $taskFolder.GetTask("$schtaskName")

        # Update the task with a new definition
        $taskFolder.RegisterTaskDefinition("$schtaskName", $Task.Definition, 6, 'Users', $null, 4)  # 6 is TASK_CREATE_OR_UPDATE
    }
    else {
        Write-Host "Execution context is not set to 'User', skipping this block."
    }

    Write-Host "Exiting MyRegisterScheduledTask function..." -ForegroundColor Magenta
}


function Set-LocalPathBasedOnContext {
    Write-Host "Checking running context..." -ForegroundColor Cyan
    if (Test-RunningAsSystem) {
        $global:Path_local = "$ENV:Programfiles\_MEM"
        Write-Host "Running as system, setting path to Program Files" -ForegroundColor Yellow
    }
    else {
        $global:Path_local = "$ENV:LOCALAPPDATA\_MEM"
        Write-Host "Running as user, setting path to Local AppData" -ForegroundColor Yellow
    }
}

function Start-ScriptTranscript {
    param (
        [string]$Path_local,
        [string]$PackageName
    )

    Write-Host "Starting transcript..." -ForegroundColor Cyan
    $logFileName = "$Path_local\Log\${PackageName}-install-$(Get-Date -Format 'yyyyMMddHHmmss').log"
    Write-Host "Log file name set to: $logFileName" -ForegroundColor Cyan
    Start-Transcript -Path $logFileName -Force
}

# function Prepare-ScriptExecution {
#     param (
#         [string]$Path_local,
#         [string]$PackageName,
#         [string]$PackageUniqueGUID,
#         [int]$Version
#     )

#     Write-Host "Preparing script execution..." -ForegroundColor Cyan
#     $Path_PR = "$Path_local\Data\PR_$PackageName"
#     $schtaskName = "$PackageName - $PackageUniqueGUID"
#     $schtaskDescription = "Version $Version"
# }


Write-Host "Preparing script execution..." -ForegroundColor Cyan
    $Path_PR = "$Path_local\Data\PR_$PackageName"
    $schtaskName = "$PackageName - $PackageUniqueGUID"
    $schtaskDescription = "Version $Version"

function CheckAndExecuteTask {
    param (
        [string]$schtaskName,
        [int]$Version,
        [string]$Path_PR
    )

    Write-Host "Checking for existing task..." -ForegroundColor Cyan
    if (Check-ExistingTask -taskName $schtaskName -version $Version) {
        Execute-DetectionAndRemediation -Path_PR $Path_PR
    }
    else {
        SetupNewTaskEnvironment -Path_PR $Path_PR -schtaskName $schtaskName -schtaskDescription $schtaskDescription -ScriptMode $ScriptMode
    }
}

function SetupNewTaskEnvironment {
    param (
        [string]$Path_PR,
        [string]$schtaskName,
        [string]$schtaskDescription,
        [string]$ScriptMode
    )

    # Write-Host "Setting up new task environment..." -ForegroundColor Cyan

    Write-EnhancedLog -Message "Setting up new task environment" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)

    New-Item -path $Path_PR -ItemType Directory -Force

    Write-EnhancedLog -Message "created new Path $Path_PR" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
  
    # Set $Path_PSscript based on ScriptMode
    if ($ScriptMode -eq "Remediation") {
        $Path_PSscript = "$Path_PR\remediation.ps1"
    }
    elseif ($ScriptMode -eq "PackageName") {
        $Path_PSscript = "$Path_PR\$PackageName.ps1"
    }
    else {
        Write-Host "Invalid ScriptMode configuration. Defaulting to remediation.ps1" -ForegroundColor Red
        $Path_PSscript = "$Path_PR\remediation.ps1"
    }


    Get-Content -Path $($PSCommandPath) | Out-File -FilePath $Path_PSscript -Force
    $Path_vbs = Create-VBShiddenPS

    Copy-Item detection.ps1 -Destination $Path_PR -Force
    Copy-Item remediation.ps1 -Destination $Path_PR -Force
    Copy-Item config.json -Destination $Path_PR -Force

    $scheduledTaskParams = @{
        schtaskName        = $schtaskName
        schtaskDescription = $schtaskDescription
        Path_vbs           = $Path_vbs
        Path_PSscript      = $Path_PSscript
    }

    Write-Host "Registering scheduled task with provided parameters..." -ForegroundColor Cyan
    MyRegisterScheduledTask @scheduledTaskParams
}

# Main script execution starts here
Set-LocalPathBasedOnContext
Start-ScriptTranscript -Path_local $global:Path_local -PackageName $PackageName

try {
    # Prepare-ScriptExecution -Path_local $global:Path_local -PackageName $PackageName -PackageUniqueGUID $PackageUniqueGUID -Version $Version
    CheckAndExecuteTask -schtaskName $schtaskName -Version $Version -Path_PR $Path_PR
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}


Write-Host "Stopping transcript..." -ForegroundColor Cyan
Stop-Transcript
