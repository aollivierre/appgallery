# "Sysnative" itself isn't a folder you can directly access or run tests on. It's a virtual folder name used by 32-bit applications running on a 64-bit Windows system (like Windows 11) through **WOW64** (Windows on Windows 64-bit). This allows 32-bit applications to access the correct 64-bit system files they need to function.

# Here's what you need to know about testing and "Sysnative":

# **Understanding Sysnative:**

# * **Purpose:** When a 32-bit application tries to access the regular "System32" folder (which contains 64-bit system files), WOW64 automatically redirects it to "Sysnative". This ensures the application accesses compatible 32-bit versions of system files instead of incompatible 64-bit ones.
# * **Not a real folder:** "Sysnative" isn't a physical folder on your disk. It's a virtual name that points to the appropriate location based on the application's architecture (32-bit) and the system's architecture (64-bit).

# **Testing and Sysnative:**

# * **Direct testing not possible:** Since "Sysnative" isn't a real folder, you can't directly run tests on it or access it like other directories.
# * **Testing 32-bit applications:** If you're developing or testing a 32-bit application on a 64-bit Windows 11 machine, you might encounter scenarios where the application's behavior is influenced by how it interacts with the "Sysnative" redirection. In such cases, you'd need to test the application specifically on a 64-bit Windows system with WOW64 enabled, as this is the environment it's designed to run in.
# * **Alternative approaches:** If you're not specifically testing how an application interacts with "Sysnative", you can usually test your 32-bit application using other methods, such as:
#     * Running it on a 32-bit Windows machine
#     * Using a virtual machine with a 32-bit Windows installation

# **Additional points:**

# * Be cautious when modifying system files or folders, even through virtual mechanisms like "Sysnative". It's recommended to only perform such actions in controlled testing environments and with proper backups.
# * If you have specific questions or encounter issues related to 32-bit application testing on Windows 11, consider consulting the Microsoft documentation or developer forums for more detailed guidance.




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
        } catch {
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
            } catch {
                Write-EnhancedLog -Message "Failed to elevate privileges: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $_
            }
        } else {
            Write-EnhancedLog -Message "Script is already running with administrative privileges." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }

    end {
        # This block is typically used for cleanup. In this case, there's nothing to clean up,
        # but it's useful to know about this structure for more complex functions.
    }
}






# CheckAndElevate

# #Run Windows PowerShell under System32 in the SYSTEM context to simulate how Intune also works
# $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass'

# # Assuming PsExec64.exe is in the same directory as your script
# $PsExec64Path = Join-Path -Path $PSScriptRoot -ChildPath "PsExec64.exe"

# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -WindowStyle Hidden



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
        [string]$ScriptPathasSYSTEM  # Path to the PowerShell script you want to run as SYSTEM
    )

    begin {
        CheckAndElevate
        # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with the script
        $argList = "-accepteula -i -s -d powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$ScriptPathasSYSTEM`""
        # $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -executionpolicy bypass'
        Write-Host "Preparing to execute PowerShell as SYSTEM using PsExec64 with the script: $ScriptPathasSYSTEM"



        Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }

    process {
        try {
            # Ensure PsExec64Path exists
            if (-not (Test-Path -Path $PsExec64Path)) {
                throw "PsExec64.exe not found at path: $PsExec64Path"
            }

            # Run PsExec64.exe with the defined arguments to execute the script as SYSTEM
            Write-Host "Executing PsExec64.exe to start PowerShell as SYSTEM running script: $ScriptPathasSYSTEM"
            Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -NoNewWindow
        }
        catch {
            Write-Host "An error occurred: $_"
        }
    }
}













# # # Assuming PsExec64.exe is in the same directory as your script
# $PsExec64Path = Join-Path -Path $PSScriptRoot -ChildPath "PsExec64.exe"
# Invoke-AsSystem -PsExec64Path $PsExec64Path