#Unique Tracking ID: 4063c752-cc15-4855-ab83-410142e59c16, Timestamp: 2024-02-15 12:55:52
function CheckPrinterAndPort {
    param(
        [Parameter(Mandatory)]
        [string]$PrinterName,
        
        [Parameter(Mandatory)]
        [string]$PrinterIPAddress
    )

    $printerExists = $false 
    $portExists = $false

    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"

    # Check for Printer existence
    try {
        $printerProperty = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Name" -ErrorAction Stop
        
        if ($printerProperty.Name -eq $PrinterName) {
            $printerExists = $true

            $portName = "IP_$PrinterIPAddress"
    
            # Check if printer port exists
            $port = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
            if ($port) {
                $portExists = $true 
            } else {
                # Write-Host "Printer port '$portName' not detected."
            }
        } else {
            # Write-Host "Printer '$PrinterName' not detected."
        }
    } catch {
        # Write-Host "Error accessing registry to check for printer: $_"
    }

    # Final check
    if ($printerExists -and $portExists) {
        Write-Host "Printer and Port detected successfully."
        exit 0
    } else {
        # Write-Host "One or more components not detected."
        exit 1
    }
}

# Usage example
$params = @{
    PrinterName       = "SHARP SHAW"
    PrinterIPAddress  = "192.168.41.20"
}
 
CheckPrinterAndPort @params