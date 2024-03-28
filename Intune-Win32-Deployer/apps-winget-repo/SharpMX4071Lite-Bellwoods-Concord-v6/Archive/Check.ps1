#Unique Tracking ID 73aa74ec-e150-4afe-8c61-20faa5ee756e

function AOCheckCertificateAndPrinter {
    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        [Parameter(Mandatory)]
        [string]$PrinterName
    )

    $certificateExists = $false
    $printerExists = $false

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
        }
        else {
            # Write-Host "Printer '$PrinterName' not detected."
        }
    }
    catch {
        # Write-Host "Error accessing registry to check for printer: $_"
    }

    # Check if both Certificate and Printer exist
    if ($certificateExists -and $printerExists) {
        Write-Host "Both the certificate and the printer were detected successfully."
        exit 0
    }
    else {
        # Uncomment the line below to display a message when either the certificate or the printer is not detected
        # Write-Host "Either the certificate or the printer was not detected."
        exit 1
    }
}

# Usage example:
$CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
$PrinterName = "SHARP Concord"

AOCheckCertificateAndPrinter -CertificateThumbprint $CertificateThumbprint -PrinterName $PrinterName
