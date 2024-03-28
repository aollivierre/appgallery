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

    # Check for Printer existence
    try {
        $printerProperty = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Name" -ErrorAction Stop
        if ($printerProperty.Name -eq $PrinterName) {
            $printerExists = $true

            # Additional checks for printer port and driver
            $printerDriverName = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Printer Driver" -ErrorAction SilentlyContinue
            $printerPortName = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Port" -ErrorAction SilentlyContinue

            # Check for Printer Driver existence
            $driverExists = Get-PrinterDriver -Name $printerDriverName.'Printer Driver' -ErrorAction SilentlyContinue
            if ($driverExists) {
                $printerDriverExists = $true
            }

        
            # Check for Printer Port existence
            $portExists = Get-PrinterPort -Name $printerPortName.Port -ErrorAction SilentlyContinue
            if ($portExists) {
                $printerPortExists = $true
            }
        }
    }
    catch {
        # Error accessing registry to check for printer; you can log or handle the error as needed
    }
        
    # Summary of checks
    if ($certificateExists -and $printerExists -and $printerPortExists -and $printerDriverExists) {
        Write-Host "Certificate, printer, printer port, and printer driver were all detected successfully."
        exit 0 # Success
    }
    else {
        # Here you can add detailed messages based on which checks failed, for
        
        # Check for Printer Port existence
        $portExists = Get-PrinterPort -Name $printerPortName.Port -ErrorAction SilentlyContinue
        if ($portExists) {
            $printerPortExists = $true
        }
    }
}
catch {
    # Error accessing registry to check for printer; you can log or handle the error as needed
}

# Summary of checks
if ($certificateExists -and $printerExists -and $printerPortExists -and $printerDriverExists) {
    Write-Host "Certificate, printer, printer port, and printer driver were all detected successfully."
    exit 0 # Success
}
else {
    # Here you can add detailed messages based on which checks failed, for


}

# Usage example
$CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
$PrinterName = "SHARP Concord"

AOCheckCertificatePrinterAndDrivers -CertificateThumbprint $CertificateThumbprint -PrinterName $PrinterName