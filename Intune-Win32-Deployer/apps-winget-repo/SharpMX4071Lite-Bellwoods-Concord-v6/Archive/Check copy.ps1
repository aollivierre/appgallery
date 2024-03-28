# Unique Tracking ID 73aa74ec-e150-4afe-8c61-20faa5ee756e

function AOCheckCertificateAndPrinter {
    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        [Parameter(Mandatory)]
        [string]$PrinterName
    )

    $certificateExists = $false
    $printerExists = $false
    $portExists = $false
    $driverExists = $false

    $certificateStorePath = "Cert:\LocalMachine\TrustedPublisher\$CertificateThumbprint"
    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"
    $portRegistryKeyPath = "HKLM:\System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\$PrinterName"
    $driverRegistryKeyPath = "HKLM:\System\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\$PrinterName"

    # Check for Certificate existence
    if (Test-Path -Path $certificateStorePath) {
        $certificateExists = $true
    }

    # Check for Printer existence
    try {
        $printerProperty = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Name" -ErrorAction Stop
        if ($printerProperty.Name -eq $PrinterName) {
            $printerExists = $true
        }
    }
    catch {
        # Write-Host "Error accessing registry to check for printer: $_"
    }

    # Check for Port existence
    if (Test-Path -Path $portRegistryKeyPath) {
        $portExists = $true
    }

    # Check for Driver existence
    if (Test-Path -Path $driverRegistryKeyPath) {
        $driverExists = $true
    }

    # Check if both Certificate, Printer, Port, and Driver exist
    if ($certificateExists -and $printerExists -and $portExists -and $driverExists) {
        Write-Host "Certificate, printer, port, and driver were detected successfully."
        exit 0
    }
    else {
        # Uncomment the line below to display a message when any component is not detected
        # Write-Host "One or more components (certificate, printer, port, or driver) were not detected."
        exit 1
    }
}

# Usage example:
$CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
$PrinterName = "SHARP Concord"

AOCheckCertificateAndPrinter -CertificateThumbprint $CertificateThumbprint -PrinterName $PrinterName
