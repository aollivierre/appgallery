function Install-NetworkPrinter {
    param (
        [string]$PrinterHostAddress,
        [string]$PrinterName
    )
    
    # $PortName = "IP_$($PrinterHostAddress.Replace('.', '_'))"

    # Add Printer Port
    # Write-Host "Adding printer port: $PortName with Printer Host Address: $PrinterHostAddress"
    # Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterHostAddress

    # Add Printer Driver (assuming the driver is already staged using pnputil)
    # Replace the 'DriverName' with the actual driver name you want to install
    $DriverName = "Ricoh RICOH MP C3504ex PCL 6"
    Write-Host "Adding printer driver: $DriverName"
    Add-PrinterDriver -Name $DriverName

    # Add Printer
    Write-Host "Adding printer: $PrinterName"
    # Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName

    Write-Host "Printer installation complete."
}

# Call the function to install the printer
Install-NetworkPrinter -PrinterHostAddress "10.0.0.47" -PrinterName "IP_10.0.0.47"
