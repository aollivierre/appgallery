#Unique Tracking ID: 67ac28e1-1b2e-4bbc-a68e-39e0d5e387d8, Timestamp: 2024-02-15 13:14:52
#Unique Tracking ID 5cf3fcd8-49a8-4733-8726-94876ba7130e

function AOCheckCertificatePrinterPortAndDriver {

    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        
        [Parameter(Mandatory)]
        [string]$PrinterName,
        
        [Parameter(Mandatory)]
        [string]$PrinterDriverName,
        
        [Parameter(Mandatory)]  
        [string]$PrinterIPAddress,

        [Parameter(Mandatory)]  
        [string]$InfFileName
    )


    $certificateExists = $false
    $printerExists = $false 
    $portExists = $false
    $driverExists = $false
    $driverStoreExists = $false
    $spoolDriverExists = $false

    $certificateStorePath = "Cert:\LocalMachine\TrustedPublisher\$CertificateThumbprint"
    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"
    $driverStorePath = "C:\Windows\System32\DriverStore\FileRepository\$InfFileName`_amd64_634bca3944391527"
    $spoolDriverPath = "C:\Windows\System32\spool\drivers\x64\PCC\$InfFileName`_amd64_634bca3944391527.cab"



    if (Test-Path -Path $driverStorePath) {
        $driverStoreExists = $true
    }
    
    if (Test-Path -Path $spoolDriverPath) {
        $spoolDriverExists = $true
    }


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
    # Final check
    if ($certificateExists -and $printerExists -and $portExists -and $driverExists -and $driverStoreExists -and $spoolDriverExists) {
      
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
    PrinterName           = "SHARP DUNDAS"  
    PrinterDriverName     = "SHARP MX-3071 PCL6"
    PrinterIPAddress      = "192.168.43.2"
    InfFileName           = "su2emenu.inf"
}
 
AOCheckCertificatePrinterPortAndDriver @params
