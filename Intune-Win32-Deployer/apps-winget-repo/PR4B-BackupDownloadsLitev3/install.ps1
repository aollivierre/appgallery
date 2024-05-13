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
        # UserID    = "S-1-5-18" #SYSTEM
        # UserID    = "S-1-5-32-545" #USERS
        # LogonType = "Interactive"
        # LogonType = "ServiceAccount"
        # RunLevel  = "LeastPrivilege"
        # RunLevel  = "LeastPrivilege"

        UserID    = "NT AUTHORITY\SYSTEM"
        LogonType = "ServiceAccount"
        RunLevel  = "Highest"
    }
    $principal = New-ScheduledTaskPrincipal @principalParams

    # Register the task
    $task = Register-ScheduledTask -TaskName $schtaskName -Trigger $trigger -Action $action -Principal $principal -Description $schtaskDescription -Force



#     # This will create a scheduled task which will run a UserLogonScript for any user that logs on changing the regional settings for the user to Australia.
# $ShedService = New-Object -comobject 'Schedule.Service'
# $ShedService.Connect()

# $Task = $ShedService.NewTask(0)
# $Task.RegistrationInfo.Description = 'UserLogonScript'
# $Task.Settings.Enabled = $true
# $Task.Settings.AllowDemandStart = $true

# $trigger = $task.triggers.Create(9)
# $trigger.Enabled = $true

# $action = $Task.Actions.Create(0)
# $action.Path = 'PowerShell.exe'
# $action.Arguments = '-ExecutionPolicy Unrestricted -File c:\UserLogonScript.ps1'
# # $action.WorkingDirectory = ''

# $taskFolder = $ShedService.GetFolder("\")
# $taskFolder.RegisterTaskDefinition('UserLogonScript', $Task , 6, 'Users', $null, 4)







    # Updating the task to include repetition with a 5-minute interval
    $task = Get-ScheduledTask -TaskName $schtaskName
    $task.Triggers[0].Repetition.Interval = "PT60M" # Repeat every 5 minutes
    $task | Set-ScheduledTask





    # Connect to the Task Scheduler service
$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

# Get the folder where the task is stored (root folder in this case)
$taskFolder = $ShedService.GetFolder("\")
 
# Get the existing task by name
$Task = $taskFolder.GetTask("$schtaskName")

# If you need to modify the task's description or settings
# $Task.Definition.RegistrationInfo.Description = 'UpdatedDescription'
# $Task.Definition.Settings.Enabled = $true
# $Task.Definition.Settings.AllowDemandStart = $true

# Modify the trigger if needed (this example assumes there's at least one trigger already)
# $Task.Definition.Triggers.Item(1).Enabled = $true  # Modify the first trigger

# Modify the action if needed (this example assumes there's at least one action already)
# $Task.Definition.Actions.Item(1).Path = 'PowerShell.exe'
# $Task.Definition.Actions.Item(1).Arguments = '-ExecutionPolicy Unrestricted -File "C:\Path\To\UpdatedScript.ps1"'

# Update the task with a new definition
# $taskFolder.RegisterTaskDefinition("$schtaskName", $Task.Definition, 6, 'Users', $null, 4)  # 6 is TASK_CREATE_OR_UPDATE
$taskFolder.RegisterTaskDefinition("$schtaskName", $Task.Definition, 6, 'Users', $null, 4)  # 6 is TASK_CREATE_OR_UPDATE

    Write-Host "Exiting MyRegisterScheduledTask function..." -ForegroundColor Magenta
}

Write-Host "Checking running context..." -ForegroundColor Cyan
if (Test-RunningAsSystem) {
    $global:Path_local = "$ENV:Programfiles\_MEM"
    Write-Host "Running as system, setting path to Program Files" -ForegroundColor Yellow
}
else {
    $global:Path_local = "$ENV:LOCALAPPDATA\_MEM"
    Write-Host "Running as user, setting path to Local AppData" -ForegroundColor Yellow
}

Write-Host "Starting transcript..." -ForegroundColor Cyan
$logFileName = "$global:Path_local\Log\${PackageName}-install-$(Get-Date -Format 'yyyyMMddHHmmss').log"
Write-Host "Log file name set to: $logFileName" -ForegroundColor Cyan
Start-Transcript -Path $logFileName -Force

try {
    Write-Host "Preparing script execution..." -ForegroundColor Cyan
    $Path_PR = "$global:Path_local\Data\PR_$PackageName"
    $schtaskName = "$PackageName - $PackageUniqueGUID"
    $schtaskDescription = "Version $Version"

    Write-Host "Checking for existing task..." -ForegroundColor Cyan
    if (Check-ExistingTask -taskName $schtaskName -version $Version) {
        Execute-DetectionAndRemediation -Path_PR $Path_PR
    }
    else {
        Write-Host "Setting up new task environment..." -ForegroundColor Cyan
        New-Item -path $Path_PR -ItemType Directory -Force
        # $Path_PSscript = "$Path_PR\$PackageName.ps1"
        $Path_PSscript = "$Path_PR\remediation.ps1"
        Get-Content -Path $($PSCommandPath) | Out-File -FilePath $Path_PSscript -Force
        $Path_vbs = Create-VBShiddenPS

        Copy-Item detection.ps1 -Destination $Path_PR -Force
        Copy-Item remediation.ps1 -Destination $Path_PR -Force


        # Creating a hashtable for splatting
        $scheduledTaskParams = @{
            schtaskName             = $schtaskName
            schtaskDescription      = $schtaskDescription
            Path_vbs                = $Path_vbs
            Path_PSscript           = $Path_PSscript
        }

        Write-Host "Registering scheduled task with provided parameters..." -ForegroundColor Cyan
        # Using splatting to pass parameters to the Register-ScheduledTask function

        Write-Host "About to call MyRegisterScheduledTask function..." -ForegroundColor Green
        MyRegisterScheduledTask @scheduledTaskParams

        Write-Host "MyRegisterScheduledTask function called..." -ForegroundColor Green
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "Stopping transcript..." -ForegroundColor Cyan
Stop-Transcript