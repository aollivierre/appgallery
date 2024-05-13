#Unique Tracking ID: 44aff377-0a75-4a32-811d-102b5acd0fa5, Timestamp: 2024-03-10 14:50:44

# Read configuration from the JSON file
# Assign values from JSON to variables


<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>

$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$scriptFiles = Get-ChildItem -Path $privateFolderPath -Filter "*.ps1"

try {
    $scriptFiles = Get-ChildItem -Path $privateFolderPath -Filter "*.ps1"
    foreach ($file in $scriptFiles) {
        $filePath = $file.FullName
        
        . $filePath
        Write-EnhancedLog -Message "Dot-sourcing script: $($file.Name)" -Level INFO -ForegroundColor Cyan
        # $DBG
    }
}
catch {
    # Write-EnhancedLog -Message "Error dot-sourcing scripts: $_" -Level ERROR -ForegroundColor Red
}

# ################################################################################################################################
# ################################################ END DOT SOURCING ##############################################################
# ################################################################################################################################


if (Get-Command Write-EnhancedLog -ErrorAction SilentlyContinue) {
    Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}
else {
    Write-Host "Write-EnhancedLog not found."
}



function Test-RunningAsSystem {
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-18"
    $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

    return $currentSid -eq $systemSid
}

<#
.SYNOPSIS
Elevates the script to run with administrative privileges if not already running as an administrator.

.DESCRIPTION
The CheckAndElevate function checks if the current PowerShell session is running with administrative privileges. If it is not, the function attempts to restart the script with elevated privileges using the 'RunAs' verb. This is useful for scripts that require administrative privileges to perform their tasks.

.EXAMPLE
CheckAndElevate

Checks the current session for administrative privileges and elevates if necessary.

.NOTES
This function will cause the script to exit and restart if it is not already running with administrative privileges. Ensure that any state or data required after elevation is managed appropriately.
#>
function CheckAndElevate {
    [CmdletBinding()]
    param (
        # Advanced parameters could be added here if needed. For this function, parameters aren't strictly necessary,
        # but you could, for example, add parameters to control logging behavior or to specify a different method of elevation.
        # [switch]$Elevated
    )

    begin {
        try {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

            Write-EnhancedLog -Message "Checking for administrative privileges..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Blue)
        }
        catch {
            Write-EnhancedLog -Message "Error determining administrative status: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            throw $_
        }
    }

    process {
        if (-not $isAdmin) {
            try {
                Write-EnhancedLog -Message "The script is not running with administrative privileges. Attempting to elevate..." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
                
                $arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" $args"
                Start-Process PowerShell -Verb RunAs -ArgumentList $arguments

                # Invoke-AsSystem -PsExec64Path $PsExec64Path
                
                Write-EnhancedLog -Message "Script re-launched with administrative privileges. Exiting current session." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                exit
            }
            catch {
                Write-EnhancedLog -Message "Failed to elevate privileges: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $_
            }
        }
        else {
            Write-EnhancedLog -Message "Script is already running with administrative privileges." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }

    end {
        # This block is typically used for cleanup. In this case, there's nothing to clean up,
        # but it's useful to know about this structure for more complex functions.
    }
}



<#
.SYNOPSIS
Executes a PowerShell script under the SYSTEM context, similar to Intune's execution context.

.DESCRIPTION
The Invoke-AsSystem function executes a PowerShell script using PsExec64.exe to run under the SYSTEM context. This method is useful for scenarios requiring elevated privileges beyond the current user's capabilities.

.PARAMETER PsExec64Path
Specifies the full path to PsExec64.exe. If not provided, it assumes PsExec64.exe is in the same directory as the script.

.EXAMPLE
Invoke-AsSystem -PsExec64Path "C:\Tools\PsExec64.exe"

Executes PowerShell as SYSTEM using PsExec64.exe located at "C:\Tools\PsExec64.exe".

.NOTES
Ensure PsExec64.exe is available and the script has the necessary permissions to execute it.

.LINK
https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
#>

function Invoke-AsSystem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,
        [string]$ScriptPathAsSYSTEM  # Path to the PowerShell script you want to run as SYSTEM
    )

    begin {
        CheckAndElevate
        # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with the script
        $argList = "-accepteula -i -s -d powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$ScriptPathAsSYSTEM`""
        Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with the script: $ScriptPathAsSYSTEM" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }

    process {
        try {
            # Ensure PsExec64Path exists
            if (-not (Test-Path -Path $PsExec64Path)) {
                $errorMessage = "PsExec64.exe not found at path: $PsExec64Path"
                Write-EnhancedLog -Message $errorMessage -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $errorMessage
            }

            # Run PsExec64.exe with the defined arguments to execute the script as SYSTEM
            $executingMessage = "Executing PsExec64.exe to start PowerShell as SYSTEM running script: $ScriptPathAsSYSTEM"
            Write-EnhancedLog -Message $executingMessage -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -NoNewWindow

            Write-EnhancedLog -Message "SYSTEM session started. Closing elevated session..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            exit
        }
        catch {
            Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        }
    }
}




# Assuming Invoke-AsSystem and Write-EnhancedLog are already defined
# Update the path to your actual location of PsExec64.exe
$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

if (-not (Test-RunningAsSystem)) {
    Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

    $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
    Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem

}
else {
    Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}

    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################




# function Invoke-MDMReenrollment {
#     <#
#     .SYNOPSIS
#     Function for resetting device Intune management connection.

#     .DESCRIPTION
#     Force re-enrollment of Intune managed devices.

#     It will:
#     - remove Intune certificates
#     - remove Intune scheduled tasks & registry keys
#     - force re-enrollment via DeviceEnroller.exe

#     .PARAMETER computerName
#     (optional) Name of the remote computer, which you want to re-enroll.

#     .PARAMETER asSystem
#     Switch for invoking re-enroll as a SYSTEM instead of logged user.

#     .EXAMPLE
#     Invoke-MDMReenrollment

#     Invoking re-enroll to Intune on local computer under logged user.

#     .EXAMPLE
#     Invoke-MDMReenrollment -computerName PC-01 -asSystem

#     Invoking re-enroll to Intune on computer PC-01 under SYSTEM account.

#     .NOTES
#     https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

#     Based on work of MauriceDaly.
#     #>

#     [Alias("Invoke-IntuneReenrollment")]
#     [CmdletBinding()]
#     param (
#         [switch] $asSystem,


#         [string] $computerName = $env:COMPUTERNAME,


#         $ErrorActionPreference = "Stop"



#     )



#     try {
#         # foreach ($functionDef in $allFunctionDefs) {
#         #     . ([ScriptBlock]::Create($functionDef))
#         # }

#         Write-Host "Checking for MDM certificate in computer certificate store"

#         #TODO Check&Delete MDM device certificate
#         Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA" | ForEach-Object {
#             Write-EnhancedLog -Message "Removing Intune certificate $($_.DnsNameList.Unicode)" -MessageType Info
#             Remove-Item $_.PSPath
#         }

#         #TODO Obtain current management GUID from Task Scheduler
#         # $EnrollmentGUID = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*Windows*EnterpriseMgmt\*" } | Select-Object -ExpandProperty TaskPath -Unique | Where-Object { $_ -like "*-*-*" } | Split-Path -Leaf

#         $taskScheduler = New-Object -ComObject Schedule.Service
#         $taskScheduler.Connect()

#         $taskRoot = "\Microsoft\Windows\EnterpriseMgmt"
#         $rootFolder = $taskScheduler.GetFolder($taskRoot)

#         $subfolders = $rootFolder.GetFolders(0)

#         foreach ($folder in $subfolders) {
#             Write-EnhancedLog -Message "Folder Name: $($folder.Name)" -MessageType Info
#             Write-EnhancedLog -Message "Folder Path: $($folder.Path)" -MessageType Info
#             Write-EnhancedLog -Message "-----------------------------" -MessageType Info

#             $EnrollmentGUID = $folder.Name

#             #TODO Start cleanup process
#             if (![string]::IsNullOrEmpty($EnrollmentGUID)) {
#                 Write-Host "Current enrollment GUID detected as $([string]$EnrollmentGUID)"

#                 # TODO Remove task scheduler entries
#                 Write-EnhancedLog -Message "Removing task scheduler Enterprise Management entries for GUID - $([string]$EnrollmentGUID)" -MessageType Info
#                 Get-ScheduledTask | Where-Object { $_.Taskpath -match $EnrollmentGUID } | Unregister-ScheduledTask -Confirm:$false

#                 #TODO Calling Remove-Item against Task Sched for EnterpriseMgmt and EnterpriseMgmtNoncritical
#                 try {
#                     $taskPath1 = "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID"
#                     $taskPath2 = "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmtNoncritical\$EnrollmentGUID"

#                     Remove-Item -Path $taskPath1 -Force -ErrorAction Stop
#                     Write-Host "Task removed successfully from path: $taskPath1" -ForegroundColor Green

#                     Remove-Item -Path $taskPath2 -Force -ErrorAction Stop
#                     Write-EnhancedLog -Message "Task removed successfully from path: $taskPath2" -MessageType Success
#                 }
#                 catch {
#                     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
#                 }

#                 #TODO Delete the parent folder in Task Scheduler
#                 try {
#                     $rootFolder.DeleteFolder("\$EnrollmentGUID", 0)
#                     Write-EnhancedLog -Message "Parent task folder for GUID - $([string]$EnrollmentGUID) removed successfully" -MessageType Success
#                 }
#                 catch {
#                     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
#                 }

#                 <#
# .SYNOPSIS
# Removes registry entries related to Intune enrollment.

# .DESCRIPTION
# This script removes registry entries related to Intune enrollment, including entries for Enrollments, Status, EnterpriseResourceManager, PolicyManager, and Provisioning.

# .PARAMETER EnrollmentGUID
# The GUID of the enrollment to remove.

# .NOTES
# This script should be run as an administrator.

# .EXAMPLE
# .\Reset-IntuneEnrollment_v11_InterActive_CleanupOnly.ps1 -EnrollmentGUID "12345678-1234-1234-1234-1234567890ab"
# #>

#                 #TODO Calling Remove-Item against Regedit for Enrollments and PolicyManager and Provisioning
#                 # Define registry keys to be processed
#                 $RegistryKeys = "HKLM:\SOFTWARE\Microsoft\Enrollments",
#                 "HKLM:\SOFTWARE\Microsoft\Enrollments\Status",
#                 "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked",
#                 "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled",
#                 "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers",
#                 "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts",
#                 "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger",
#                 "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
#                 foreach ($Key in $RegistryKeys) {
#                     Write-Host "Processing registry key $Key"
#                     # TODO Remove registry entries
#                     if (Test-Path -Path $Key) {
#                         #TODO Search for and remove keys with matching GUID
#                         Write-EnhancedLog -Message "GUID entry found in $Key. Removing..." -MessageType Information
#                         Get-ChildItem -Path $Key | Where-Object { $_.Name -match $EnrollmentGUID } | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
#                     }
#                     else {
#                         # throw "Unable to obtain enrollment GUID value from task scheduler. Aborting"

#                         Write-EnhancedLog -Message "Error: unable to obtain enrollment GUID $EnrollmentGUID value from $key" -MessageType Error
#                         Write-EnhancedLog -Message "Error: $($_.Exception.Message)" -MessageType Error
#                     }
#                 }

#             }
#         }

#     }
#     catch [System.Exception] {
#         throw "Error message: $($_.Exception.Message)"
#     }



# }


# Write-Host "Invoking re-enrollment of Intune connection" -ForegroundColor Cyan
#TODO Calling Invoke-MDMReenrollment
# Invoke-MDMReenrollment -computerName $computerName -asSystem





function Remove-MDMCertificates {
    Write-EnhancedLog -Message "Checking for MDM certificate in computer certificate store" -MessageType "Info"
    Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA" | ForEach-Object {
        Write-EnhancedLog -Message "Removing Intune certificate $($_.DnsNameList.Unicode)" -MessageType "Info"
        Remove-Item $_.PSPath
    }
}





<#
.SYNOPSIS
Retrieves GUIDs from the Task Scheduler within a specified root directory.

.DESCRIPTION
The Get-ManagementGUID function connects to the Task Scheduler service and enumerates all subfolders within a specified root directory, collecting the names of these subfolders (assumed to be GUIDs) into a list. This function is designed to work with the Task Scheduler's Microsoft\Windows\EnterpriseMgmt directory to gather enrollment GUIDs but can be adapted to other directories. It utilizes advanced logging through a custom function `Write-EnhancedLog` for consistent and detailed logging of its operations.

.PARAMETER taskRoot
The root directory within the Task Scheduler from which to start collecting GUIDs. Defaults to "\Microsoft\Windows\EnterpriseMgmt".

.EXAMPLE
PS> Get-ManagementGUID
This example runs the function with its default parameter to collect GUIDs from the "\Microsoft\Windows\EnterpriseMgmt" directory in the Task Scheduler.

.EXAMPLE
PS> Get-ManagementGUID -taskRoot "\Microsoft\Windows\CustomDirectory"
This example specifies a custom root directory from which to collect GUIDs.

.NOTES
Ensure that the custom logging function `Write-EnhancedLog` is defined in your script or module for logging to work correctly.

#>
function Get-ManagementGUID {
    [CmdletBinding()]
    param (
        # Specifies the root directory within the Task Scheduler from which to collect GUIDs.
        [string]$taskRoot = "\Microsoft\Windows\EnterpriseMgmt"
    )

    begin {
        # Attempt to connect to the Task Scheduler service and initialize the list for GUIDs.
        try {
            $taskScheduler = New-Object -ComObject Schedule.Service
            $taskScheduler.Connect()
            $EnrollmentGUIDs = New-Object System.Collections.Generic.List[object]
        } catch {
            Write-EnhancedLog -Message "Failed to connect to the Task Scheduler service. Error: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            return
        }
    }

    process {
        # Attempt to retrieve the specified root folder and its subfolders.
        try {
            $rootFolder = $taskScheduler.GetFolder($taskRoot)
            $subfolders = $rootFolder.GetFolders(0)
        } catch {
            Write-EnhancedLog -Message "Failed to get subfolders for the task root '$taskRoot'. Error: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            return
        }

        # Log if no subfolders are found, otherwise, iterate through each subfolder.
        if ($subfolders.Count -eq 0) {
            Write-EnhancedLog -Message "No subfolders found in '$taskRoot'." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
        } else {
            foreach ($folder in $subfolders) {
                try {
                    # Add the name of each subfolder to the list and log the action.
                    $EnrollmentGUIDs.Add($folder.Name)
                    Write-EnhancedLog -Message "Added GUID: $($folder.Name)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                } catch {
                    Write-EnhancedLog -Message "Failed to add GUID: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                }
            }
        }
    }

    end {
        # At the end, log the total count of collected GUIDs, or warn if none were found.
        if ($EnrollmentGUIDs.Count -gt 0) {
            Write-EnhancedLog -Message "$($EnrollmentGUIDs.Count) GUIDs collected successfully." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            return $EnrollmentGUIDs
        } else {
            Write-EnhancedLog -Message "No GUIDs found in '$taskRoot'." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
}





function Remove-TaskSchedulerEntriesAndTasks {
    param (
        [string]$EnrollmentGUID
    )

    Write-EnhancedLog -Message "Removing task scheduler Enterprise Management entries for GUID - $EnrollmentGUID" -MessageType "Info"
    Get-ScheduledTask | Where-Object { $_.TaskPath -match $EnrollmentGUID } | Unregister-ScheduledTask -Confirm:$false

    # Additional steps for removing specific tasks and handling errors omitted for brevity.
}





function Remove-RegistryEntries {
    param (
        [string]$EnrollmentGUID
    )

    $RegistryKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Enrollments"
        # "HKLM:\SOFTWARE\Microsoft\Enrollments\Status",
        # Additional keys omitted for brevity.
    )

    foreach ($Key in $RegistryKeys) {
        if (Test-Path -Path $Key) {
            Get-ChildItem -Path $Key | Where-Object { $_.Name -match $EnrollmentGUID } | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
            Write-EnhancedLog -Message "GUID entry found and removed from $Key." -MessageType "Info"
        } else {
            Write-EnhancedLog -Message "Registry key $Key not found or has no matching GUID entries." -MessageType "Warning"
        }
    }
}










































<#
.SYNOPSIS
Checks for the presence of Intune certificates in the local machine's personal certificate store.

.DESCRIPTION
This function waits for up to a specified timeout for Intune certificates to be created in the local machine's personal certificate store. It looks specifically for certificates issued by "CN=Microsoft Intune MDM Device CA". The function logs the waiting process and the outcome, successfully finding the certificates or timing out.

.PARAMETER Timeout
The maximum amount of time, in seconds, to wait for the Intune certificates. Default is 30 seconds.

.EXAMPLE
Check-IntuneCertificates
Checks for Intune certificates with the default timeout of 30 seconds.

.EXAMPLE
Check-IntuneCertificates -Timeout 60
Checks for Intune certificates with a custom timeout of 60 seconds.

.NOTES
Ensure that the 'Write-EnhancedLog' function is defined in your environment for logging.

#>

function Check-IntuneCertificates {
    [CmdletBinding()]
    Param(
        # Maximum wait time in seconds for the Intune certificates to appear.
        [int]$Timeout = 30
    )

    Begin {
        # Log the start of the certificate check process.
        Write-EnhancedLog -Message "Waiting for Intune certificate creation" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    }

    Process {
        $i = $Timeout
        # Loop to check for certificates, decrementing the timer each second.
        while (!(Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { $_.Issuer -match "CN=Microsoft Intune MDM Device CA" }) -and $i -gt 0) {
            Start-Sleep -Seconds 1
            $i--
            # Log each second of waiting, indicating the remaining time.
            Write-EnhancedLog -Message "Waiting... ($i seconds remaining)" -Level "INFO" -ForegroundColor ([ConsoleColor]::DarkYellow)
        }

        # Check if the timeout was reached without finding the certificates.
        if ($i -eq 0) {
            Write-EnhancedLog -Message "Intune certificate (issuer: Microsoft Intune MDM Device CA) isn't created (yet?)." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
        else {
            # Success log when the certificates are found before the timeout.
            Write-EnhancedLog -Message "Intune certificate creation confirmed :)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }

    End {
        # Log the completion of the function.
        Write-EnhancedLog -Message "Check-IntuneCertificates function has completed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    }
}


# Check-IntuneCertificates
















function Perform-IntuneCleanup {


    Check-IntuneCertificates

    # First, remove any MDM certificates.
    Remove-MDMCertificates


    Check-IntuneCertificates

    # Obtain the current management GUIDs.
    $EnrollmentGUIDs = Get-ManagementGUID

    if ($EnrollmentGUIDs.Count -eq 0) {
        Write-EnhancedLog -Message "No enrollment GUIDs found. Exiting cleanup process." -MessageType "Warning" -ForegroundColor Yellow
        return
    }

    foreach ($EnrollmentGUID in $EnrollmentGUIDs) {
        Write-EnhancedLog -Message "Current enrollment GUID detected as $EnrollmentGUID" -MessageType "Info" -ForegroundColor Cyan

        # Remove task scheduler entries and tasks.
        Remove-TaskSchedulerEntriesAndTasks -EnrollmentGUID $EnrollmentGUID

        # Delete specific registry entries associated with the GUID.
        Remove-RegistryEntries -EnrollmentGUID $EnrollmentGUID
    }

    Write-EnhancedLog -Message "Intune cleanup process completed." -MessageType "Success" -ForegroundColor Green
}

# Start the cleanup process
Perform-IntuneCleanup








# New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"; New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM" -Name AutoEnrollMDM -Value 1; & "$env:windir\system32\deviceenroller.exe" /c /AutoEnrollMDM



<#
.SYNOPSIS
Enables AutoEnrollment to Mobile Device Management (MDM) by modifying the registry and invoking the device enrollment process.

.DESCRIPTION
This function creates a new registry key for Mobile Device Management under Microsoft Windows CurrentVersion policies. It then sets the AutoEnrollMDM property to enable automatic MDM enrollment. Finally, it invokes the device enroller executable to apply the changes.

.EXAMPLE
Enable-MDMAutoEnrollment

This command runs the Enable-MDMAutoEnrollment function to enable automatic device enrollment in MDM.

.NOTES
This function requires administrative privileges to modify the registry and to run the device enrollment executable.

#>

function Enable-MDMAutoEnrollment {
    [CmdletBinding()]
    Param()

    Begin {
        # # Ensure the function is running with administrative privileges
        # If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        #     Write-EnhancedLog -Message "This function requires administrative privileges." -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        #     return
        # }
        # Write-EnhancedLog -Message "Starting the MDM AutoEnrollment process." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }

    Process {
        Try {
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

            # Check if the registry key exists
            if (-not (Test-Path $registryPath)) {
                Write-EnhancedLog -Message "Creating registry key for MDM AutoEnrollment." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                New-Item $registryPath -ErrorAction Stop | Out-Null
            } else {
                Write-EnhancedLog -Message "Registry key for MDM AutoEnrollment already exists. Skipping creation." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
            }

            # Check if the AutoEnrollMDM property exists
            $propertyExists = $false
            Try {
                $propertyExists = [bool](Get-ItemProperty -Path $registryPath -Name AutoEnrollMDM -ErrorAction Stop)
            } Catch {
                $propertyExists = $false
            }

            if (-not $propertyExists) {
                Write-EnhancedLog -Message "Setting AutoEnrollMDM property." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                New-ItemProperty -Path $registryPath -Name AutoEnrollMDM -Value 1 -ErrorAction Stop | Out-Null
            } else {
                Write-EnhancedLog -Message "AutoEnrollMDM property already set. Skipping." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
            }

            # Invoke the device enrollment process
            Write-EnhancedLog -Message "Invoking the device enrollment process." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            & "$env:windir\system32\deviceenroller.exe" /c /AutoEnrollMDM

            Write-EnhancedLog -Message "MDM AutoEnrollment process completed successfully." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        Catch {
            Write-EnhancedLog -Message "An error occurred during the MDM AutoEnrollment process: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        }
    }

    End {
        Write-EnhancedLog -Message "MDM AutoEnrollment function has completed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        Check-IntuneCertificates
    }
}

Enable-MDMAutoEnrollment

