function AOCheckCertificateAndPrinter {
    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        [Parameter(Mandatory)]
        [string]$PrinterName
    )

    $certificateStorePath = "Cert:\LocalMachine\TrustedPublisher\$CertificateThumbprint"
    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"

    # Check for Certificate existence
    if (Test-Path -Path $certificateStorePath) {
        Write-Host "Certificate with thumbprint '$CertificateThumbprint' exists in TrustedPublisher store."
    }
    else {
        Write-Host "Certificate with thumbprint '$CertificateThumbprint' does not exist in TrustedPublisher store."
        exit 1
    }

    # Check for Printer existence
    try {
        $printerProperty = Get-ItemProperty -Path $printerRegistryKeyPath -Name "Name" -ErrorAction Stop
        if ($printerProperty.Name -eq $PrinterName) {
            Write-Host "Printer '$PrinterName' detected."
        }
        else {
            Write-Host "Printer '$PrinterName' not detected."
            exit 1
        }
    }
    catch {
        Write-Host "Error accessing registry to check for printer: $_"
        exit 1
    }
}

# Usage example:
$CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
$PrinterName = "SHARP Concord"

AOCheckCertificateAndPrinter -CertificateThumbprint $CertificateThumbprint -PrinterName $PrinterName