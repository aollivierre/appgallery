#Unique Tracking ID 73aa74ec-e150-4afe-8c61-20faa5ee756e

function AOCheckCertificatePrinterAndDrivers {

    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory)]
        [string]$PrinterName
    )

    $certificateExists = $false
    $printerExists = $false 
    $portExists = $false
    $driversExist = $false

    $certificateStorePath = "Cert:\LocalMachine\TrustedPublisher\$CertificateThumbprint"
    
    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"

    # Check for Certificate existence
    if (Test-Path -Path $certificateStorePath) {
        $certificateExists = $true
    }
    else {
        # Write-Host "Certificate with thumbprint '$CertificateThumbprint' does not exist in TrustedPublisher store."
    }

    # Check for Printer existence
    try {
        $printerProperty = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Name" -ErrorAction Stop
        
        if ($printerProperty.Name -eq $PrinterName) {
            $printerExists = $true
            
            # Check if printer port exists
            $port = Get-PrinterPort -Name $printerProperty.PortName
            if ($port) {
                $portExists = $true 
            }
            
            # Check if printer drivers exist
            $drivers = Get-PrinterDriver -Name $PrinterName
            if ($drivers) {
                $driversExist = $true
            }
        }
        else {
            # Write-Host "Printer '$PrinterName' not detected."
        }
    }
    catch {
        # Write-Host "Error accessing registry to check for printer: $\_"
    }

    # Check if Certificate, Printer, Port and Drivers exist
    if ($certificateExists -and $printerExists -and $portExists -and $driversExist) {
        Write-Host "Certificate, Printer, Port and Drivers detected successfully."
        exit 0
    }
    else {
        # Uncomment below to display message when any component is missing
        # Write-Host "One or more components not detected." 
        exit 1
    }
}

# Usage example
$CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
$PrinterName = "SHARP Concord"

AOCheckCertificatePrinterAndDrivers -CertificateThumbprint $CertificateThumbprint -PrinterName $PrinterName