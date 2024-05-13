# param (
#     [switch]$Elevated
# )


# function CheckAndElevate {
#     param (
#         [switch]$Elevated
#     )

#     $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
#     $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
#     if (-not $isAdmin -and -not $Elevated) {
#         $scriptWithParams = "-Elevated -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments -join ' '
#         Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass $scriptWithParams" -Verb RunAs
#         exit
#     }
# }



# function CheckAndElevate {
#     param (
#         [switch]$Elevated
#     )

#     $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
#     $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
#     if (-not $isAdmin -and -not $Elevated) {
#         $scriptWithParams = "-Elevated -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments -join ' '
#         Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass $scriptWithParams" -Verb RunAs
#         exit
#     }
# }







function CheckAndElevate {
    [CmdletBinding()]
    param (
        # Advanced parameters could be added here if needed. For this function, parameters aren't strictly necessary,
        # but you could, for example, add parameters to control logging behavior or to specify a different method of elevation.
        # [switch]$Elevated

        # [switch]$Elevated
    )

    begin {
        try {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

            # Write-EnhancedLog -Message "Checking for administrative privileges..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Blue)
        }
        catch {
            # Write-EnhancedLog -Message "Error determining administrative status: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            throw $_
        }
    }

    process {
        if (-not $isAdmin) {
            try {
                # Write-EnhancedLog -Message "The script is not running with administrative privileges. Attempting to elevate..." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
                
                $arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" $args"
                Start-Process PowerShell -Verb RunAs -ArgumentList $arguments

                # Invoke-AsSystem -PsExec64Path $PsExec64Path
                
                # Write-EnhancedLog -Message "Script re-launched with administrative privileges. Exiting current session." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                exit
            }
            catch {
                # Write-EnhancedLog -Message "Failed to elevate privileges: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $_
            }
        }
        else {
            # Write-EnhancedLog -Message "Script is already running with administrative privileges." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }

    end {
        # This block is typically used for cleanup. In this case, there's nothing to clean up,
        # but it's useful to know about this structure for more complex functions.
    }
}


# function Invoke-AsSystem {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$PsExec64Path
#     )

#     begin {
#         # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with -NoExit to keep the window open
#         $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -executionpolicy bypass'
#         # Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#     }

#     process {
#         try {
#             # Ensure we are running with administrative privileges
#             CheckAndElevate

#             # Ensure PsExec64Path exists
#             if (-not (Test-Path -Path $PsExec64Path)) {
#                 throw "PsExec64.exe not found at path: $PsExec64Path"
#             }

#             # Run PsExec64.exe with the defined arguments
#             # Write-EnhancedLog -Message "Executing PsExec64.exe to start PowerShell as SYSTEM with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#             Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -WindowStyle Hidden
#             # Write-EnhancedLog -Message "PowerShell executed as SYSTEM and window will remain open." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         }
#         catch {
#             # Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#         }
#     }
# }










function Invoke-AsSystem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,
        [string]$ScriptPath  # Path to the PowerShell script you want to run as SYSTEM
    )

    begin {
        CheckAndElevate
        # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with the script
        $argList = "-accepteula -i -s -d powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$ScriptPath`""
        # $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -executionpolicy bypass'
        Write-Host "Preparing to execute PowerShell as SYSTEM using PsExec64 with the script: $ScriptPath"



        # Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }

    process {
        try {
            # Ensure PsExec64Path exists
            if (-not (Test-Path -Path $PsExec64Path)) {
                throw "PsExec64.exe not found at path: $PsExec64Path"
            }

            # Run PsExec64.exe with the defined arguments to execute the script as SYSTEM
            Write-Host "Executing PsExec64.exe to start PowerShell as SYSTEM running script: $ScriptPath"
            Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -NoNewWindow
        }
        catch {
            Write-Host "An error occurred: $_"
        }
    }
}
















function Test-RunningAsSystem {
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-18"
    $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

    return $currentSid -eq $systemSid
}

# CheckAndElevate

# Assuming PsExec64.exe is in the same directory as your script
# $PsExec64Path = Join-Path -Path $PSScriptRoot -ChildPath "PsExec64.exe"
# Invoke-AsSystem -PsExec64Path $PsExec64Path


# Assuming Invoke-AsSystem and Write-EnhancedLog are already defined

# Update the path to your actual location of PsExec64.exe
$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

if (-not (Test-RunningAsSystem)) {
    # Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

    write-host 'Current session is not running as SYSTEM. Attempting to invoke as SYSTEM'
    # CheckAndElevate
    # Invoke-AsSystem -PsExec64Path $PsExec64Path


    # $PsExecPath = "C:\Path\To\PsExec64.exe"
    # $ScriptToRunAsSystem = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget-repo\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v7\test2.ps1"
    $ScriptToRunAsSystem = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget-repo\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v7\Uninstall copy.ps1"
    Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem



    # Write-Host "Running Get-Service in an elevated session..."
    # Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object DisplayName, Status
    
    #     # Wait for user input before exiting, to allow the user to see the output
    Write-Host "Press any key to continue ..."
}
else {
    Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}



# This line checks and elevates if needed.
# CheckAndElevate -Elevated:$Elevated
# CheckAndElevate

# If the script is elevated (either was already, or just has been by CheckAndElevate), execute Get-Service.
# if ($Elevated -or (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
# Write-Host "Running Get-Service in an elevated session..."
# Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object DisplayName, Status
    
#     # Wait for user input before exiting, to allow the user to see the output
# Write-Host "Press any key to continue ..."
#     $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
# }





# $DBG