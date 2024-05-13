# #Unique Tracking ID: 50ed2b1e-b96b-437b-b3ac-d035dc575793, Timestamp: 2024-02-15 13:23:30
# $d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# # Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe -DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden


# Start-Process -FilePath "$d_1002\Deploy-Application.exe" -ArgumentList "-DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden

# # Start-Process -FilePath ".\sara\SaRAcmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden
# # Start-Process -FilePath "C:\Users\AOllivierre_CloudAdm\Downloads\SaRACmd_17_01_0495_021\SaRACmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden



function Remove-PrinterAndCleanup {
    param(
        [Parameter(Mandatory)]
        [string]$PrinterName,
        # [string]$DriverName,
        [string]$PortName
    )

    # Remove Printer
    if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
        Remove-Printer -Name $PrinterName -Confirm:$false
        # Write-Host "Printer '$PrinterName' removed."
        Start-Sleep -Seconds 120
    }

    # Remove Printer Port
    $portExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if ($portExists) {
        Remove-PrinterPort -Name $PortName -Confirm:$false
        # Write-Host "Printer port '$PortName' removed."
        Start-Sleep -Seconds 120
    }
}

# # Set parameters here
# $PrinterName = "HP LaserJet P3015 - Finance - New"
# # $DriverName = "SHARP MX-3071 PCL6" # Adjust as necessary
# $PortName = "IP_192.168.53.20" # Adjust as necessary
# # $InfFileName = "su2emenu.inf" # Adjust as necessary

# # Call the function with specified parameters
# # Remove-PrinterAndCleanup -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName -InfFileName $InfFileName
# # Remove-PrinterAndCleanup -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName
# Remove-PrinterAndCleanup -PrinterName $PrinterName -PortName $PortName







# Determine the directory where the script is located
# $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the printer removal configuration JSON file
$removePrinterConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# Read configuration from the JSON file
$removePrinterConfig = Get-Content -Path $removePrinterConfigPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$PrinterName = $removePrinterConfig.PrinterName
$PortName = $removePrinterConfig.PortName
# Uncomment and adjust these if your JSON includes them and your function needs them
# $DriverName = $removePrinterConfig.DriverName
# $InfFileName = $removePrinterConfig.InfFileName

# Call the function with parameters read from JSON
# Adjust the function call according to which parameters are actually needed/used
Remove-PrinterAndCleanup -PrinterName $PrinterName -PortName $PortName
# Include these in the function call if applicable
# -DriverName $DriverName -InfFileName $InfFileName