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


# function Dot-SourcePrivateScripts {
#     [CmdletBinding()]
#     param ()

#     Begin {
        
#         # Write-EnhancedLog -Message "Starting to dot-source scripts from the 'private' folder..." -Level INFO -ForegroundColor Green
#     }

#     Process {
#         try {
#             $scriptFiles = Get-ChildItem -Path $privateFolderPath -Filter "*.ps1"
#             foreach ($file in $scriptFiles) {
#                 $filePath = $file.FullName
#                 # Write-EnhancedLog -Message "Dot-sourcing script: $($file.Name)" -Level INFO -ForegroundColor Cyan
#                 . $filePath
#                 $DBG
#             }
#         } catch {
#             # Write-EnhancedLog -Message "Error dot-sourcing scripts: $_" -Level ERROR -ForegroundColor Red
#         }
#     }

#     End {
#         # Write-EnhancedLog -Message "Completed dot-sourcing scripts." -Level INFO -ForegroundColor Green
#     }
# }

# Dot-SourcePrivateScripts

# ################################################################################################################################
# ################################################ END DOT SOURCING ##############################################################
# ################################################################################################################################

# Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)





# $privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"



# function Dot-SourcePrivateScripts {
#     [CmdletBinding()]
#     param ()

#     Begin {
        
#         # Explicitly dot-source the Write-EnhancedLog script
#         . .\(Join-Path -Path $privateFolderPath -ChildPath "00-Write-EnhancedLog.ps1")
#     }

#     Process {
#         try {
#             # Now, get all script files excluding the Write-EnhancedLog script
#             $scriptFiles = Get-ChildItem -Path $privateFolderPath -Filter "*.ps1" | Where-Object { $_.Name -ne "00-Write-EnhancedLog.ps1" }
#             foreach ($file in $scriptFiles) {
#                 $filePath = $file.FullName
#                 $DBG
#                 # Assuming Write-EnhancedLog is available now
#                 . .\$filePath
#             }
#         } catch {
#             # Assuming Write-EnhancedLog is available now
#         }
#     }

#     End {
#         # Assuming Write-EnhancedLog is available now
#     }
# }

# Dot-SourcePrivateScripts




# $DBG








# Navigate to the script's directory (if needed)
# Set-Location -Path "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget-repo\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v7\Private"

# Dot-source the script
# . .\00-Write-EnhancedLog.ps1

if (Get-Command Write-EnhancedLog -ErrorAction SilentlyContinue) {
    Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
} else {
    Write-Host "Write-EnhancedLog not found."
}

$DBG

# # Determine the directory where the script is located
# # $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Define the path to the printer removal configuration JSON file
# $removePrinterConfigPath = Join-Path -Path $PSPSScriptRoot -ChildPath "printer.json"

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
$configPath = Join-Path -Path $PSPSScriptRoot -ChildPath "printer.json"

# Load the printer configuration
$printerConfig = Get-PrinterConfig -ConfigPath $configPath

if ($null -ne $printerConfig) {
    # Remove the printer and printer port based on the loaded configuration
    Remove-PrinterByName -PrinterName $printerConfig.PrinterName
    Remove-PrinterPortByName -PortName $printerConfig.PortName
}

