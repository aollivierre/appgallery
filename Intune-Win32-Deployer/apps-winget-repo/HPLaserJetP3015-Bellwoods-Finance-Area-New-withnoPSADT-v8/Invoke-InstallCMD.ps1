# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -File "install.ps1" -PrinterName "HP LaserJet P3015 - Finance - New" -PrinterIPAddress "192.168.53.20" -PortName "IP_192.168.53.20" -DriverName "HP Universal Printing PCL 6" -InfPathRelative "Driver\hpcu270u.inf" -InfFileName "hpcu270u.inf" -DriverIdentifier "amd64_3e20dbae029ad04a"


# powershell.exe -executionpolicy bypass -File "install.ps1" -PrinterName "HP LaserJet P3015 - Finance - New" -PrinterIPAddress "192.168.53.20" -PortName "IP_192.168.53.20" -DriverName "HP Universal Printing PCL 6" -InfPathRelative "Driver\hpcu270u.inf" -InfFileName "hpcu270u.inf" -DriverIdentifier "amd64_3e20dbae029ad04a"



# .\install.ps1 -PrinterName "HP LaserJet P3015 - Finance - New" `
#               -PrinterIPAddress "192.168.53.20" `
#               -PortName "IP_192.168.53.20" `
#               -DriverName "HP Universal Printing PCL 6" `
#               -InfPathRelative "Driver\hpcu270u.inf" `
#               -InfFileName "hpcu270u.inf" `
#               -DriverIdentifier "amd64_3e20dbae029ad04a"



# # Define the path to the printer configuration JSON file
# $printerConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# # $params = Get-Content $printerConfigPath | ConvertFrom-Json -AsHashtable
# $params = Get-Content $printerConfigPath | ConvertFrom-Json


# .\install.ps1 @params




# powershell.exe -executionpolicy bypass -File "uninstall.ps1" -PrinterName "HP LaserJet P3015 - Finance - New" -PrinterIPAddress "192.168.53.20" -PortName "IP_192.168.53.20" -DriverName "HP Universal Printing PCL 6" -InfPathRelative "Driver\hpcu270u.inf" -InfFileName "hpcu270u.inf" -DriverIdentifier "amd64_3e20dbae029ad04a"




# .\Uninstall.ps1 -PrinterName "HP LaserJet P3015 - Finance - New" `
#               -PrinterIPAddress "192.168.53.20" `
#               -PortName "IP_192.168.53.20" `
#               -DriverName "HP Universal Printing PCL 6" `
#               -InfPathRelative "Driver\hpcu270u.inf" `
#               -InfFileName "hpcu270u.inf" `
#               -DriverIdentifier "amd64_3e20dbae029ad04a"



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

    Write-Error "Error dot-sourcing scripts: $_"
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
function Invoke-AsSystemWithParams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPathAsSYSTEM,

        [hashtable]$Params
    )


    CheckAndElevate

    # Correctly build parameter string
    $paramString = ($Params.GetEnumerator() | 
        ForEach-Object { "-{0} `"{1}`"" -f $_.Key, $_.Value }) -join " "


    $commandToRun = "`"powershell.exe`" -NoExit -ExecutionPolicy Bypass -File `"`"$ScriptPathAsSYSTEM`"`" $paramString"
    $argList = "-accepteula -i -s $commandToRun"


    # $argList = "-accepteula -i -s -d powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$ScriptPathAsSYSTEM`""


    try {
        Start-Process -FilePath $PsExec64Path -ArgumentList $argList -Wait -NoNewWindow
        # Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -NoNewWindow
        Write-Host "Executed script as SYSTEM successfully with parameters."
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}



# $ScriptToRunAsSystem = "C:\code\Printers\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v8\Uninstall.ps1"
$ScriptToRunAsSystem = "C:\code\Printers\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v8\install.ps1"
$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

if (-not (Test-RunningAsSystem)) {
    Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

    $parameters = @{
        PrinterName      = "HP LaserJet P3015 - Finance - New"
        PrinterIPAddress = "192.168.53.20"
        PortName         = "IP_192.168.53.20"
        DriverName       = "HP Universal Printing PCL 6"
        InfPathRelative  = "Driver\hpcu270u.inf"
        InfFileName      = "hpcu270u.inf"
        DriverIdentifier = "amd64_3e20dbae029ad04a"
    }
    
    # Call the function with the specified parameters
    Invoke-AsSystemWithParams -PsExec64Path $PsExec64Path -ScriptPathAsSYSTEM $ScriptToRunAsSystem -Params $parameters
}
else {
    Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}