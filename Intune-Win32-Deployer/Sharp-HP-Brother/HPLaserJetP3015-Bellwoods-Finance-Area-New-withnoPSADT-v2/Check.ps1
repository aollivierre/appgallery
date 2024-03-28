#Unique Tracking ID: 50ed2b1e-b96b-437b-b3ac-d035dc575793, Timestamp: 2024-02-15 13:23:30


$json = @'
{
    "PrinterName": "HP LaserJet P3015 - Finance - New",
    "PrinterIPAddress": "192.168.53.20",
    "PortName": "IP_192.168.53.20",
    "DriverName": "HP Universal Printing PCL 6",
    "InfPathRelative": "Driver\\hpcu270u.inf",
    "InfFileName": "hpcu270u.inf",
    "DriverIdentifier": "amd64_3e20dbae029ad04a"
}
'@

# Convert JSON string to a PowerShell object
# $Config = $json | ConvertFrom-Json


function AOCheckCertificatePrinterPortAndDriver {

    param(
        # [Parameter(Mandatory)]
        # [string]$CertificateThumbprint,
        
        [Parameter(Mandatory)]
        [string]$PrinterName,
        
        [Parameter(Mandatory)]
        [string]$PrinterDriverName,
        
        [Parameter(Mandatory)]  
        [string]$PrinterIPAddress,

        [Parameter(Mandatory)]  
        [string]$InfFileName,

        [Parameter(Mandatory)]
        [string]$DriverIdentifier  # New parameter
    )


    # $certificateExists = $false
    $printerExists = $false 
    $portExists = $false
    $driverExists = $false
    $driverStoreExists = $false
    $spoolDriverExists = $false

    # $certificateStorePath = "Cert:\LocalMachine\TrustedPublisher\$CertificateThumbprint"
    $printerRegistryKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$PrinterName"
    $driverStorePath = "C:\Windows\System32\DriverStore\FileRepository\$InfFileName`_$DriverIdentifier"
    $spoolDriverPath = "C:\Windows\System32\spool\drivers\x64\PCC\$InfFileName`_$DriverIdentifier.cab"



    if (Test-Path -Path $driverStorePath) {
        $driverStoreExists = $true
    }
    
    if (Test-Path -Path $spoolDriverPath) {
        $spoolDriverExists = $true
    }


    # Check for Certificate existence
    # if (Test-Path -Path $certificateStorePath) {
        # $certificateExists = $true
    # }
    # else {
        # Write-Host "Certificate with thumbprint '$CertificateThumbprint' does not exist in TrustedPublisher store."
    # }

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
    # if ($certificateExists -and $printerExists -and $portExists -and $driverExists -and $driverStoreExists -and $spoolDriverExists) {
    if ($printerExists -and $portExists -and $driverExists -and $driverStoreExists -and $spoolDriverExists) {
      
        # Write-Host "Certificate, Printer, Port and Drivers detected successfully."
        Write-Host "Printer, Port and Drivers detected successfully."
        exit 0
    }
    else {
        # Uncomment below to display message when any component is missing
        # Write-Host "One or more components not detected." 
        exit 1
    }
}


# Usage

# $params = @{
#     # CertificateThumbprint = 'F6E9917F79C80297197F3DC35D1909565BB423CD'
#     PrinterName           = "HP LaserJet P3015 - Finance - New"  
#     PrinterDriverName     = "HP Universal Printing PCL 6"
#     PrinterIPAddress      = "192.168.53.20"
#     InfFileName           = "hpcu270u.inf"
# }
 
# AOCheckCertificatePrinterPortAndDriver @params





# Determine the directory where the script is located
# $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the printer setup configuration JSON file
# $printerSetupConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# Read configuration from the JSON file
# $printerSetupConfig = Get-Content -Path $printerSetupConfigPath -Raw | ConvertFrom-Json




# # Convert the configuration into a hashtable suitable for splatting
# $params = @{
#     PrinterName       = $printerSetupConfig.PrinterName
#     PrinterDriverName = $printerSetupConfig.DriverName
#     PrinterIPAddress  = $printerSetupConfig.PrinterIPAddress
#     InfFileName       = $printerSetupConfig.InfFileName
# }

# # Optional: Add CertificateThumbprint to $params if needed
# # If your JSON file contains a CertificateThumbprint, uncomment the following line
# # $params.CertificateThumbprint = $printerSetupConfig.CertificateThumbprint

# # Call the function with parameters using splatting
# AOCheckCertificatePrinterPortAndDriver @params




# Define the path to the printer setup configuration JSON file
# $printerSetupConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"


# # Convert JSON string to a PowerShell object
$printerSetupConfig = $json | ConvertFrom-Json

# Read configuration from the JSON file
# $printerSetupConfig = Get-Content -Path $printerSetupConfigPath -Raw | ConvertFrom-Json

# Convert the configuration into a hashtable suitable for splatting
$params = @{
    PrinterName       = $printerSetupConfig.PrinterName
    PrinterDriverName = $printerSetupConfig.DriverName
    PrinterIPAddress  = $printerSetupConfig.PrinterIPAddress
    InfFileName       = $printerSetupConfig.InfFileName
    DriverIdentifier  = $printerSetupConfig.DriverIdentifier  # Include the new parameter
}

# Call the function with parameters using splatting
AOCheckCertificatePrinterPortAndDriver @params