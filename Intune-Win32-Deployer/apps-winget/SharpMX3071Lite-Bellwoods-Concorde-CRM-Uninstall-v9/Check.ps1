#Unique Tracking ID 0e45fe11-693f-4cbf-a8e5-d86cf64f25b1
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
    PrinterName       = "SHARP CRM"
    PrinterIPAddress  = "192.168.53.155"
}
 
CheckPrinterAndPort @params