#Unique Tracking ID: eb934004-9280-4ed1-8c21-a7c345802f61, Timestamp: 2024-03-11 01:58:18

# param(
#     [Parameter(Mandatory=$true)]
#     [string]$PrinterName,

#     [Parameter(Mandatory=$true)]
#     [string]$PrinterIPAddress,

#     [Parameter(Mandatory=$true)]
#     [string]$PortName,

#     [Parameter(Mandatory=$true)]
#     [string]$DriverName,

#     [Parameter(Mandatory=$true)]
#     [string]$InfPathRelative,

#     [Parameter(Mandatory=$true)]
#     [string]$InfFileName,

#     [Parameter(Mandatory=$true)]
#     [string]$DriverIdentifier
# )

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
} catch {
    # Write-EnhancedLog -Message "Error dot-sourcing scripts: $_" -Level ERROR -ForegroundColor Red
}

# ################################################################################################################################
# ################################################ END DOT SOURCING ##############################################################
# ################################################################################################################################


if (Get-Command Write-EnhancedLog -ErrorAction SilentlyContinue) {
    Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
} else {
    Write-Host "Write-EnhancedLog not found."
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
























# function CheckAndElevate {
#     [CmdletBinding()]
#     param (
#         # Advanced parameters could be added here if needed. For this function, parameters aren't strictly necessary,
#         # but you could, for example, add parameters to control logging behavior or to specify a different method of elevation.
#         # [switch]$Elevated
#     )

#     begin {
#         try {
#             $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
#             $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

#             Write-EnhancedLog -Message "Checking for administrative privileges..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Blue)
#         } catch {
#             Write-EnhancedLog -Message "Error determining administrative status: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#             throw $_
#         }
#     }

#     process {
#         if (-not $isAdmin) {
#             try {
#                 Write-EnhancedLog -Message "The script is not running with administrative privileges. Attempting to elevate..." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
                
#                 $arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" $args"
#                 Start-Process PowerShell -Verb RunAs -ArgumentList $arguments

#                 # Invoke-AsSystem -PsExec64Path $PsExec64Path
                
#                 Write-EnhancedLog -Message "Script re-launched with administrative privileges. Exiting current session." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#                 exit
#             } catch {
#                 Write-EnhancedLog -Message "Failed to elevate privileges: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#                 throw $_
#             }
#         } else {
#             Write-EnhancedLog -Message "Script is already running with administrative privileges." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         }
#     }

#     end {
#         # This block is typically used for cleanup. In this case, there's nothing to clean up,
#         # but it's useful to know about this structure for more complex functions.
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
# function Invoke-AsSystem {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$PsExec64Path
#     )

#     begin {
#         # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM
#         $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass'
#         Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#     }

#     process {
#         try {
#             # Ensure PsExec64Path exists
#             if (-not (Test-Path -Path $PsExec64Path)) {
#                 throw "PsExec64.exe not found at path: $PsExec64Path"
#             }

#             # Run PsExec64.exe with the defined arguments
#             Write-EnhancedLog -Message "Executing PsExec64.exe to start PowerShell as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#             CheckAndElevate
#             Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -WindowStyle Hidden
#             Write-EnhancedLog -Message "PowerShell executed as SYSTEM successfully." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#         }
#     }
# }






# function Invoke-AsSystem {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$PsExec64Path
#     )

#     begin {
#         # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with -NoExit to keep the window open
#         $argList = '-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -executionpolicy bypass'
#         Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
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
#             Write-EnhancedLog -Message "Executing PsExec64.exe to start PowerShell as SYSTEM with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#             Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -WindowStyle Hidden
#             Write-EnhancedLog -Message "PowerShell executed as SYSTEM and window will remain open." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#         }
#     }
# }




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



        # Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with -NoExit." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
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








# Assuming Invoke-AsSystem and Write-EnhancedLog are already defined

# Update the path to your actual location of PsExec64.exe
$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

if (-not (Test-RunningAsSystem)) {
    Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)



    # write-host 'Current session is not running as SYSTEM. Attempting to invoke as SYSTEM'
    # CheckAndElevate


    if (Get-Command Invoke-AsSystem  -ErrorAction SilentlyContinue) {
        Write-EnhancedLog -Message "Invoke-AsSystem exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    } else {
        Write-Host "Invoke-AsSystem does not exist"
    }

    # Invoke-AsSystem -PsExec64Path $PsExec64Path


    # $ScriptToRunAsSystem = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget-repo\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v7\Uninstall copy.ps1"

    $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
    # $DBG
    Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem

    # exit

    # Write-Host "Running Get-Service in an elevated session..."
    # Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object DisplayName, Status
    
#     # Wait for user input before exiting, to allow the user to see the output
    Write-Host "Press any key to continue ..."
} else {
    Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}



# param (
#     [switch]$Elevated
# )

# $PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

# if (-not $Elevated -and -not (Test-RunningAsSystem)) {
#     Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
#     # Add a parameter to indicate the script has been elevated when it restarts
#     # CheckAndElevate -Elevated:$true
# } elseif ($Elevated) {
#     # Now running with elevated privileges, proceed to invoke as SYSTEM
#     Invoke-AsSystem -PsExec64Path $PsExec64Path
# } else {
#     Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# }





# param (
#     [switch]$Elevated
# )

# # This line checks and elevates if needed.
# CheckAndElevate -Elevated:$Elevated

# # If the script is elevated (either was already, or just has been by CheckAndElevate), execute Get-Service.
# if ($Elevated -or (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#     Write-Host "Running Get-Service in an elevated session..."
#     Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object DisplayName, Status
# } else {
#     Write-Host "Failed to run elevated."
# }




# $DBG

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

# if ($null -ne $printerConfig) {
#     # Remove the printer and printer port based on the loaded configuration
#     Remove-PrinterByName -PrinterName $printerConfig.PrinterName
#     Remove-PrinterPortByName -PortName $printerConfig.PortName
# }

