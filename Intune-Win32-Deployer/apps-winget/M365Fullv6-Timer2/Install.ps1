param (
    [Switch]$SimulatingIntune = $false
)

function Reset-ModulePaths {
    [CmdletBinding()]
    param ()

    begin {
        # Initialization block, typically used for setup tasks
        write-host "Initializing Reset-ModulePaths function..."
    }

    process {
        try {
            # Log the start of the process
            write-host "Resetting module paths to default values..."

            # Get the current user's Documents path
            $userModulesPath = [System.IO.Path]::Combine($env:USERPROFILE, 'Documents\WindowsPowerShell\Modules')

            # Define the default module paths
            $defaultModulePaths = @(
                "C:\Program Files\WindowsPowerShell\Modules",
                $userModulesPath,
                "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
            )

            # Attempt to reset the PSModulePath environment variable
            $env:PSModulePath = [string]::Join(';', $defaultModulePaths)
            write-host "PSModulePath successfully set to: $($env:PSModulePath -split ';' | Out-String)"

            # Optionally persist the change for the current user
            [Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath, [EnvironmentVariableTarget]::User)
            write-host "PSModulePath environment variable set for the current user."
        }
        catch {
            # Capture and log any errors that occur during the process
            $errorMessage = $_.Exception.Message
            write-host "Error resetting module paths: $errorMessage"

            # Optionally, you could throw the error to halt the script
            throw $_
        }
    }

    end {
        # Finalization block, typically used for cleanup tasks
        write-host "Reset-ModulePaths function completed."
    }
}

Reset-ModulePaths

$currentExecutionPolicy = Get-ExecutionPolicy

# If it's not already set to Bypass, change it
if ($currentExecutionPolicy -ne 'Bypass') {
    Write-Host "Setting Execution Policy to Bypass..."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
else {
    Write-Host "Execution Policy is already set to Bypass."
}

function Relaunch-InPowerShell5 {
    # Check the current version of PowerShell
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "Hello from PowerShell 7"

        # Get the script path (works inside a function as well)
        $scriptPath = $PSCommandPath

        # $scriptPath = $MyInvocation.MyCommand.Definition
        $ps5Path = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Build the argument to relaunch this script in PowerShell 5 with -NoExit
        $ps5Args = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

        Write-Host "Relaunching in PowerShell 5..."
        Start-Process -FilePath $ps5Path -ArgumentList $ps5Args

        # Exit the current PowerShell 7 session to allow PowerShell 5 to take over
        exit
    }

    # If relaunching in PowerShell 5
    Write-Host "Hello from PowerShell 5"
    
}

Relaunch-InPowerShell5

# ################################################################################################################################
# ################################################ END Setting Execution Policy ##################################################
# ################################################################################################################################

#region SIMULATING INTUNE AS SYSTEM  
#################################################################################################
#                                                                                               #
#                                 SIMULATING INTUNE AS SYSTEM                                   #
#                                                                                               #
#################################################################################################

# Create a time-stamped folder in the temp directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempFolder = [System.IO.Path]::Combine($env:TEMP, "Ensure-RunningAsSystem_$timestamp")

# Ensure the temp folder exists
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
}

# Use the time-stamped temp folder for your paths
$privateFolderPath = Join-Path -Path $tempFolder -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

# Check if running as a web script (no $MyInvocation.MyCommand.Path)
if (-not $MyInvocation.MyCommand.Path) {
    Write-Host "Running as web script, downloading and executing locally..."

    # Ensure TLS 1.2 is used for the download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Create a time-stamped folder in the temp directory
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $downloadFolder = Join-Path -Path $env:TEMP -ChildPath "UpdateM365Apps_$timestamp"

    # Ensure the folder exists
    if (-not (Test-Path -Path $downloadFolder)) {
        New-Item -Path $downloadFolder -ItemType Directory | Out-Null
    }

    # Download the script to the time-stamped folder
    $localScriptPath = Join-Path -Path $downloadFolder -ChildPath "install.ps1"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aollivierre/WinUpdates/main/PR4B_TriggerWindowsUpdates-v4/install.ps1" -OutFile $localScriptPath

    Write-Host "Downloading config.psd1 file..."

    # Download the config.psd1 file to the time-stamped folder
    $configFilePath = Join-Path -Path $downloadFolder -ChildPath "config.psd1"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aollivierre/WinUpdates/main/PR4B_TriggerWindowsUpdates-v4/config.psd1" -OutFile $configFilePath

    # Execute the script locally
    & $localScriptPath

    Exit # Exit after running the script locally
}

else {
    # If running in a regular context, use the actual path of the script
    $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
}

# Ensure the private folder exists before continuing
if (-not (Test-Path -Path $privateFolderPath)) {
    New-Item -Path $privateFolderPath -ItemType Directory | Out-Null
}



# Conditional check for SimulatingIntune switch
if ($SimulatingIntune) {
    # If not running as a web script, run as SYSTEM using PsExec
    Write-Host "Simulating Intune environment. Running script as SYSTEM..."

    Write-Host "Running as SYSTEM..."


    # Call the function to run as SYSTEM
    $EnsureRunningAsSystemParams = @{
        PsExec64Path = $PsExec64Path
        ScriptPath   = $ScriptToRunAsSystem
        TargetFolder = $privateFolderPath
    }

    # Run Ensure-RunningAsSystem only if SimulatingIntune is set
    Ensure-RunningAsSystem @EnsureRunningAsSystemParams
}
else {
    Write-Host "Not simulating Intune. Skipping SYSTEM execution."
}

#endregion SIMULATING INTUNE AS SYSTEM


# Set environment variable globally for all users
[System.Environment]::SetEnvironmentVariable('EnvironmentMode', 'prod', 'Machine')

# Retrieve the environment mode (default to 'prod' if not set)
$mode = $env:EnvironmentMode

#region FIRING UP MODULE STARTER
#################################################################################################
#                                                                                               #
#                                 FIRING UP MODULE STARTER                                      #
#                                                                                               #
#################################################################################################

Invoke-Expression (Invoke-RestMethod "https://raw.githubusercontent.com/aollivierre/module-starter/main/Install-EnhancedModuleStarterAO.ps1")

# Define a hashtable for splatting
$moduleStarterParams = @{
    Mode                   = 'prod'
    SkipPSGalleryModules   = $false
    SkipCheckandElevate    = $false
    SkipPowerShell7Install = $false
    SkipEnhancedModules    = $false
    SkipGitRepos           = $true
}

# Call the function using the splat
Invoke-ModuleStarter @moduleStarterParams
#endregion FIRING UP MODULE STARTER


#region Cleaning up Logs
#################################################################################################
#                                                                                               #
#                            Cleaning up Logs                                                   #
#                                                                                               #
#################################################################################################
# if ($Mode -eq "Dev") {
#     Write-EnhancedLog -Message "Removing Logs in Dev Mode " -Level "WARNING"
#     Remove-LogsFolder -LogFolderPath "C:\Logs"
#     Write-EnhancedLog -Message "Migration in progress form displayed" -Level "INFO"
# }
# else {
#     Write-EnhancedLog -Message "Skipping Removing Logs in Prod mode" -Level "WARNING"
# }
#endregion Cleaning up Logs

#region HANDLE PSF MODERN LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE PSF MODERN LOGGING                                          #
#                                                                                               #
#################################################################################################
Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true -PassThru | Register-PSFConfig -Scope SystemDefault

# Define the base logs path and job name
$JobName = "M365AppsUpdate"
$parentScriptName = Get-ParentScriptName
Write-EnhancedLog -Message "Parent Script Name: $parentScriptName"

# Call the Get-PSFCSVLogFilePath function to generate the dynamic log file path
$GetPSFCSVLogFilePathParam = @{
    LogsPath         = 'C:\Logs\PSF'
    JobName          = $jobName
    parentScriptName = $parentScriptName
}

$csvLogFilePath = Get-PSFCSVLogFilePath @GetPSFCSVLogFilePathParam
Write-EnhancedLog -Message "Generated Log File Path: $csvLogFilePath"

$instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Configure the PSFramework logging provider to use CSV format
$paramSetPSFLoggingProvider = @{
    Name            = 'logfile'
    InstanceName    = $instanceName  # Use a unique instance name
    FilePath        = $csvLogFilePath  # Use the dynamically generated file path
    Enabled         = $true
    FileType        = 'CSV'
    EnableException = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider



# # Set up the EventLog logging provider with the calling function as the source
# $paramSetPSFLoggingProvider = @{
#     Name         = 'EventLog'
#     # InstanceName = 'DynamicEventLog'
#     InstanceName = $instanceName
#     Enabled      = $true
#     LogName      = $parentScriptName
#     Source       = $callingFunction
# }
# Set-PSFLoggingProvider @paramSetPSFLoggingProvider

# Write-EnhancedLog -Message "This is a test from $parentScriptName via PSF to Event Logs" -Level 'INFO'

# $DBG

#endregion HANDLE PSF MODERN LOGGING


#region HANDLE Transript LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE Transript LOGGING                                           #
#                                                                                               #
#################################################################################################
# Start the script with error handling
try {
    # Generate the transcript file path
    $GetTranscriptFilePathParams = @{
        TranscriptsPath  = "C:\Logs\Transcript"
        JobName          = $jobName
        parentScriptName = $parentScriptName
    }
    $transcriptPath = Get-TranscriptFilePath @GetTranscriptFilePathParams
    
    # Start the transcript
    Write-EnhancedLog -Message "Starting transcript at: $transcriptPath" -Level 'INFO'
    Start-Transcript -Path $transcriptPath
}
catch {
    Write-EnhancedLog -Message "An error occurred during script execution: $_" -Level 'ERROR'
    if ($transcriptPath) {
        Stop-Transcript
        Write-Host "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block

    }
    else {
        Write-Host "Transcript was not started due to an earlier error." -ForegroundColor Red
    }

    # Stop PSF Logging

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

    Handle-Error -ErrorRecord $_
    throw $_  # Re-throw the error after logging it
} 
#endregion HANDLE Transript LOGGING

$DBG

try {

    #region CALLING AS SYSTEM
    #################################################################################################
    #                                                                                               #
    #                                 CALLING AS SYSTEM                                             #
    #                Simulate Intune deployment as SYSTEM (Uncomment for debugging)                 #
    #                                                                                               #
    #################################################################################################

    $ensureRunningAsSystemParams = @{
        PsExec64Path = Join-Path -Path $PSScriptRoot -ChildPath "private\PsExec64.exe"
        ScriptPath   = $MyInvocation.MyCommand.Path
        TargetFolder = Join-Path -Path $PSScriptRoot -ChildPath "private"
    }

    Ensure-RunningAsSystem @ensureRunningAsSystemParams
    #endregion


    #region Script Logic
    #################################################################################################
    #                                                                                               #
    #                                    Script Logic                                               #
    #                                                                                               #
    #################################################################################################

    #region END Downloading Service UI and PSADT
    #################################################################################################
    #                                                                                               #
    #                       END Downloading Service UI and PSADT                                    #
    #                                                                                               #
    #################################################################################################
    $DownloadAndInstallServiceUIparams = @{
        TargetFolder           = "$PSScriptRoot"
        DownloadUrl            = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"
        MsiFileName            = "MicrosoftDeploymentToolkit_x64.msi"
        InstalledServiceUIPath = "C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe"
    }
    Download-And-Install-ServiceUI @DownloadAndInstallServiceUIparams

    $DownloadPSAppDeployToolkitParams = @{
        GithubRepository     = 'PSAppDeployToolkit/PSAppDeployToolkit'
        FilenamePatternMatch = '*.zip'
        DestinationDirectory = $PSScriptRoot
        CustomizationsPath   = 'C:\code\IntuneDeviceMigration\DeviceMigration\PSADT-Customizations'
    }
    Download-PSAppDeployToolkit @DownloadPSAppDeployToolkitParams
    #endregion

    # Import migration configuration
    $ConfigFileName = "MigrationConfig.psd1"
    $ConfigBaseDirectory = $PSScriptRoot
    $MigrationConfig = Import-LocalizedData -BaseDirectory $ConfigBaseDirectory -FileName $ConfigFileName

    $TenantID = $MigrationConfig.TenantID
    $OneDriveKFM = $MigrationConfig.UseOneDriveKFM
    $InstallOneDrive = $MigrationConfig.InstallOneDrive

    # Define parameters
    $PrepareAADMigrationParams = @{
        MigrationPath       = "C:\ProgramData\AADMigration"
        PSScriptbase        = $PSScriptRoot
        ConfigBaseDirectory = $PSScriptRoot
        ConfigFileName      = "MigrationConfig.psd1"
        TenantID            = $TenantID
        OneDriveKFM         = $OneDriveKFM
        InstallOneDrive     = $InstallOneDrive
    }
    Prepare-AADMigration @PrepareAADMigrationParams


    $CreateInteractiveMigrationTaskParams = @{
        TaskPath               = "AAD Migration"
        TaskName               = "PR4B-AADM Launch PSADT for Interactive Migration"
        ServiceUIPath          = "C:\ProgramData\AADMigration\ServiceUI.exe"
        ToolkitExecutablePath  = "C:\ProgramData\AADMigration\PSAppDeployToolkit\Toolkit\Deploy-Application.exe"
        ProcessName            = "explorer.exe"
        DeploymentType         = "Install"
        DeployMode             = "Interactive"
        TaskTriggerType        = "AtLogOn"
        TaskRepetitionDuration = "P1D"  # 1 day
        TaskRepetitionInterval = "PT15M"  # 15 minutes
        TaskPrincipalUserId    = "NT AUTHORITY\SYSTEM"
        TaskRunLevel           = "Highest"
        TaskDescription        = "AADM Launch PSADT for Interactive Migration Version 1.0"
        Delay                  = "PT2H"  # 2 hours delay before starting
    }

    Create-InteractiveMigrationTask @CreateInteractiveMigrationTaskParams



    # Show migration in progress form
    if ($Mode -eq "dev") {
        Write-EnhancedLog -Message "Running all Post Run Once and Post Run Scheduled Tasks in Dev Mode" -Level "WARNING"
     
    
        $taskParams = @{
            TaskPath = "\AAD Migration"
            TaskName = "PR4B-AADM Launch PSADT for Interactive Migration"
        }

        # Trigger OneDrive Sync Status Scheduled Task
        Trigger-ScheduledTask @taskParams


        # Post Run 1
        #The following is mainly responsible about enrolling the device in the tenant's Entra ID via a PPKG
        $PostRunOncePhase1EntraJoinParams = @{
            MigrationConfigPath = "C:\ProgramData\AADMigration\MigrationConfig.psd1"
            ImagePath           = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
            RunOnceScriptPath   = "C:\ProgramData\AADMigration\Scripts\PostRunOnce2.ps1"
            RunOnceKey          = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
            PowershellPath      = "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe"
            ExecutionPolicy     = "Unrestricted"
            RunOnceName         = "NextRun"
            Mode                = "Dev"
        }
        # PostRunOnce-Phase1EntraJoin @PostRunOncePhase1EntraJoinParams



        # Post Run 2
        #blocks user input, displays a migration in progress form, creates a scheduled task for post-migration cleanup, escrows the BitLocker recovery key, sets various registry values for legal noctices, and optionally restarts the computer.
        $PostRunOncePhase2EscrowBitlockerParams = @{
            ImagePath        = "C:\ProgramData\AADMigration\Files\MigrationInProgress.bmp"
            TaskPath         = "AAD Migration"
            TaskName         = "Run Post migration cleanup"
            # BitlockerDrives       = @("C:", "D:")
            BitlockerDrives  = @("C:")
            RegistrySettings = @{
                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"     = @{
                    "AutoAdminLogon" = @{
                        "Type" = "DWORD"
                        "Data" = "0"
                    }
                }
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
                    "dontdisplaylastusername" = @{
                        "Type" = "DWORD"
                        "Data" = "1"
                    }
                    "legalnoticecaption"      = @{
                        "Type" = "String"
                        "Data" = "Migration Completed"
                    }
                    "legalnoticetext"         = @{
                        "Type" = "String"
                        "Data" = "This PC has been migrated to Azure Active Directory. Please log in to Windows using your email address and password."
                    }
                }
            }
            Mode             = "Dev"
        }
        # PostRunOnce-Phase2EscrowBitlocker @PostRunOncePhase2EscrowBitlockerParams



        $taskParams = @{
            TaskPath = "\AAD Migration"
            TaskName = "Run Post migration cleanup"
        }

        # Trigger OneDrive Sync Status Scheduled Task
        # Trigger-ScheduledTask @taskParams


        # Post Run 3
        # Scheduled task (not Once) for cleaning up temp user accounts and disabling all local accounts
        # $ExecuteMigrationCleanupTasksParams = @{
        #     TempUser             = "MigrationInProgress"
        #     RegistrySettings     = @{
        #         "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
        #             "dontdisplaylastusername" = @{
        #                 "Type" = "DWORD"
        #                 "Data" = "0"
        #             }
        #             "legalnoticecaption"      = @{
        #                 "Type" = "String"
        #                 "Data" = ""
        #             }
        #             "legalnoticetext"         = @{
        #                 "Type" = "String"
        #                 "Data" = ""
        #             }
        #         }
        #         "HKLM:\Software\Policies\Microsoft\Windows\Personalization"       = @{
        #             "NoLockScreen" = @{
        #                 "Type" = "DWORD"
        #                 "Data" = "0"
        #             }
        #         }
        #     }
        #     MigrationDirectories = @(
        #         "C:\ProgramData\AADMigration\Files",
        #         # "C:\ProgramData\AADMigration\Scripts",
        #         "C:\ProgramData\AADMigration\Toolkit"
        #     )
        #     Mode                 = "Dev"
        # }
        # Execute-MigrationCleanupTasks @ExecuteMigrationCleanupTasksParams


        Write-EnhancedLog -Message "All Post Run Once and Post Run Scheduled Tasks in Dev Mode completed" -Level "INFO"
    }
    else {
        Write-EnhancedLog -Message "Skipping Running all Post Run Once and Post Run Scheduled Tasks in prod Mode" -Level "WARNING"
    }








    #endregion Script Logic
    
    #region HANDLE PSF LOGGING
    #################################################################################################
    #                                                                                               #
    #                                 HANDLE PSF LOGGING                                            #
    #                                                                                               #
    #################################################################################################
    # $parentScriptName = Get-ParentScriptName
    # Write-Host "Parent Script Name: $parentScriptName"

    # $HandlePSFLoggingParams = @{
    #     SystemSourcePathWindowsPS = "C:\Windows\System32\config\systemprofile\AppData\Roaming\WindowsPowerShell\PSFramework\Logs\"
    #     SystemSourcePathPS        = "C:\Windows\System32\config\systemprofile\AppData\Roaming\PowerShell\PSFramework\Logs\"
    #     UserSourcePathWindowsPS   = "$env:USERPROFILE\AppData\Roaming\WindowsPowerShell\PSFramework\Logs\"
    #     UserSourcePathPS          = "$env:USERPROFILE\AppData\Roaming\PowerShell\PSFramework\Logs\"
    #     PSFPath                   = "C:\Logs\PSF"
    #     ParentScriptName          = $parentScriptName
    #     JobName                   = $JobName
    #     SkipSYSTEMLogCopy         = $false
    #     SkipSYSTEMLogRemoval      = $false
    # }

    # Handle-PSFLogging @HandlePSFLoggingParams

    #endregion
}
catch {
    Write-EnhancedLog -Message "An error occurred during script execution: $_" -Level 'ERROR'
    if ($transcriptPath) {
        Stop-Transcript
        Write-Host "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block
    }

    # Stop PSF Logging

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

    Handle-Error -ErrorRecord $_
    throw $_  # Re-throw the error after logging it
} 
finally {
    # Ensure that the transcript is stopped even if an error occurs
    if ($transcriptPath) {
        Stop-Transcript
        Write-Host "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block

    }
    else {
        Write-Host "Transcript was not started due to an earlier error." -ForegroundColor Red
    }
    
    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

}