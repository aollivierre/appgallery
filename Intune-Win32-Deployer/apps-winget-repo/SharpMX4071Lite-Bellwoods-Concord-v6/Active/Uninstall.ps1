function Remove-PrinterAndCleanup {
    param(
        [Parameter(Mandatory)]
        [string]$PrinterName,
        [string]$DriverName,
        [string]$PortName,
        [string]$InfFileName
    )

    # Remove Printer
    if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
        Remove-Printer -Name $PrinterName -Confirm:$false
        Write-Host "Printer '$PrinterName' removed."
        Start-Sleep -Seconds 120
    }

    # Remove Printer Port
    $portExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if ($portExists) {
        Remove-PrinterPort -Name $PortName -Confirm:$false
        Write-Host "Printer port '$PortName' removed."
        Start-Sleep -Seconds 120
    }
}

# Set parameters here
$PrinterName = "SHARP Concord"
$DriverName = "SHARP MX-4071 PCL6" # Adjust as necessary
$PortName = "IP_192.168.53.151" # Adjust as necessary
$InfFileName = "su2emenu.inf" # Adjust as necessary

# Call the function with specified parameters
Remove-PrinterAndCleanup -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName -InfFileName $InfFileName
