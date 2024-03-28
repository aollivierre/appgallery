<#
.SYNOPSIS
    Installs a printer driver, creates a printer port, and adds a printer with specified settings, and imports a certificate into TrustedPublisher stores.

.DESCRIPTION
    This function automates the process of installing a printer driver, creating a printer port based on the provided IP address, and adding a printer with the specified name and settings. Additionally, it imports a specified certificate into both the Local Machine and Current User TrustedPublisher stores to ensure the printer driver is trusted. It checks for the existence of the printer driver, port, and printer itself, adding or replacing them as necessary. This function is ideal for setting up printers in a scripted, automated manner, ensuring that the necessary security certificates are in place.

.NOTES
    Version: 1.0
    Author: Abdullah Ollivierre
    Creation Date: YYYY-MM-DD
    Last Modified: YYYY-MM-DD
    Changes Log:
        1.0 - Initial version with capabilities to install printer drivers, create printer ports, add printers, and import certificates into TrustedPublisher stores.

.LINK
    https://call4cloud.nl/2021/07/what-about-printer-drivers/
    https://anthonyfontanez.com/index.php/2023/12/30/importing-certificates-with-remediations/


.EXAMPLE
    $PrinterName = "SHARP Concord"
    $PrinterIPAddress = "192.168.53.151"
    $DriverName = "SHARP MX-4071 PCL6"
    $InfPathRelativeToScriptRoot = "Driver\su2emenu.inf"
    $CertificatePathRelativeToScriptRoot = "Path\To\Certificate\cert_name.cer"

    Install-PrinterAndCert -PrinterName $PrinterName -PrinterIPAddress $PrinterIPAddress -DriverName $DriverName -InfPathRelativeToScriptRoot $InfPathRelativeToScriptRoot -CertificatePathRelativeToScriptRoot $CertificatePathRelativeToScriptRoot

    This example sets up a printer named 'SHARP Concord' using the 'SHARP MX-4071 PCL6' driver and the specified IP address. It imports a certificate from the specified path into the TrustedPublisher stores.
#>



function Install-PrinterAndCert {
    param(
        [string]$PrinterName,
        [string]$PrinterIPAddress,
        [string]$DriverName,
        [string]$InfPathRelativeToScriptRoot,
        [string]$CertificatePathRelativeToScriptRoot
    )

    $ScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    $InfPath = Join-Path -Path $ScriptRoot -ChildPath $InfPathRelativeToScriptRoot
    $CertPath = Join-Path -Path $ScriptRoot -ChildPath $CertificatePathRelativeToScriptRoot
    $PortName = "IP_$PrinterIPAddress"

    # Import the certificate into the Trusted Publisher store for both Local Machine and Current User
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
    Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\CurrentUser\TrustedPublisher

    # Check if the printer driver exists, if not, add it
    $DriverExists = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
    if (-not $DriverExists) {
        pnputil /add-driver $InfPath /install
        Add-PrinterDriver -Name $DriverName
    }

    # Check if the printer port exists, if not, add it
    $PortExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if (-not $PortExists) {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIPAddress
    }

    # Check if the printer exists, if not, add it, otherwise replace it
    $PrinterExists = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if (-not $PrinterExists) {
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
    } else {
        Remove-Printer -Name $PrinterName
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
    }
}

# Usage example
$PrinterName = "SHARP Concord"
$PrinterIPAddress = "192.168.53.151"
$DriverName = "SHARP MX-4071 PCL6"
$InfPathRelativeToScriptRoot = "Driver\su2emenu.inf"
$CertificatePathRelativeToScriptRoot = "cert_name.cer"

Install-PrinterAndCert -PrinterName $PrinterName -PrinterIPAddress $PrinterIPAddress -DriverName $DriverName -InfPathRelativeToScriptRoot $InfPathRelativeToScriptRoot -CertificatePathRelativeToScriptRoot $CertificatePathRelativeToScriptRoot