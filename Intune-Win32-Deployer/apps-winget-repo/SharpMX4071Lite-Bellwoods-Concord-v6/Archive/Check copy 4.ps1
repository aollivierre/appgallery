#Unique Tracking ID 73aa74ec-e150-4afe-8c61-20faa5ee756e

function AOCheckCertificatePrinterPortAndDriver {

    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        
        [Parameter(Mandatory)]
        [string]$PrinterName,
        
        [Parameter(Mandatory)]
        [string]$PrinterDriverName,
        
        [Parameter(Mandatory)]  
        [string]$PrinterIPAddress
    )


    $certificateExists = $false
    $printerExists = $false 
    $portExists = $false
    $driverExists = $false

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

            $portName = "IP_$PrinterIPAddress"
    
            # Check if printer port exists
            $port = Get-PrinterPort -Name $portName
            if ($port) {
                $portExists = $true 
            }   
   
            # Check if printer driver exists
            $driver = Get-PrinterDriver -Name $PrinterDriverName
            if ($driver) {
                $driverExists = $true
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
    if ($certificateExists -and $printerExists -and $portExists -and $driverExists) {
        Write-Host "Certificate, Printer, Port and Drivers detected successfully."
        exit 0
    }
    else {
        # Uncomment below to display message when any component is missing
        # Write-Host "One or more components not detected." 
        exit 1
    }
}


# Usage

$params = @{
    CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD' 
    PrinterName           = "SHARP Concord"  
    PrinterDriverName     = "SHARP MX-4071 PCL6"
    PrinterIPAddress      = "192.168.53.151"
}
 
AOCheckCertificatePrinterPortAndDriver @params