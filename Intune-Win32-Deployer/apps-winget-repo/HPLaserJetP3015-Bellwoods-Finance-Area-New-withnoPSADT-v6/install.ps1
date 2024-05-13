#Unique Tracking ID: 5e50240e-d376-4c47-9ea6-a4867768cf72, Timestamp: 2024-03-11 01:58:18
# #Unique Tracking ID: 50ed2b1e-b96b-437b-b3ac-d035dc575793, Timestamp: 2024-02-15 13:23:30
# # Start the process, wait for it to complete, and optionally hide the window

# $d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# # Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
# Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden




param(
    [Parameter(Mandatory=$true)]
    [string]$PrinterName,

    [Parameter(Mandatory=$true)]
    [string]$PrinterIPAddress,

    [Parameter(Mandatory=$true)]
    [string]$PortName,

    [Parameter(Mandatory=$true)]
    [string]$DriverName,

    [Parameter(Mandatory=$true)]
    [string]$InfPathRelative,

    [Parameter(Mandatory=$true)]
    [string]$InfFileName,

    [Parameter(Mandatory=$true)]
    [string]$DriverIdentifier
)



# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$LoggingDeploymentName = $config.LoggingDeploymentName
    
function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "$LoggingDeploymentName" # Replace this with your actual deployment name
    $scriptPath = "C:\code\$deploymentName"
    # $hadError = $false
    
    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }
    
        $computerName = $env:COMPUTERNAME
        $Filename = "$LoggingDeploymentName"
        $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
        $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
            
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
            Write-Host "Created log file at $logPath" -ForegroundColor Green
        }
            
        $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
    
        $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
        $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
            
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Green
        }
    
        return @{
            ScriptPath  = $scriptPath
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }
    
    }
    catch {
        Write-Error "An error occurred while initializing script and logging: $_"
    }
}
$initializationInfo = Initialize-ScriptAndLogging
    
    
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']
    
    
    
    
function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
           
    )
    
    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }
    
    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}
    
    
    
function CreateEventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )
    
    
    # Validate parameters
    if (-not $LogName) {
        Write-Warning "LogName is required."
        return
    }
    if (-not $EventSource) {
        Write-Warning "Source is required."
        return
    }
    
    # Function to create event log and source
    function CreateEventLogSource($logName, $EventSource) {
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                New-EventLog -LogName $logName -Source $EventSource
            }
            else {
                [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $logName)
            }
            Write-Host "Event source '$EventSource' created in log '$logName'" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    }
    
    # Check if the event log exists
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        # CreateEventLogSource $LogName $EventSource
    }
    # Check if the event source exists
    elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Unregister the source if it's registered with a different log
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
        }
        # CreateEventLogSource $LogName $EventSource
    }
    else {
        Write-Host "Event source '$EventSource' already exists in log '$LogName'" -ForegroundColor Yellow
    }
}
    
$LogName = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
$EventSource = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
    
# Call the Create-EventSourceAndLog function
CreateEventSourceAndLog -LogName $LogName -EventSource $EventSource
    
# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'
    
    
    
    
function Write-EventLogMessage {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
    
        [string]$LogName = "$LoggingDeploymentName",
        [string]$EventSource,
    
        [int]$EventID = 1000  # Default event ID
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    $hadError = $false
    
    try {
        if (-not $EventSource) {
            throw "EventSource is required."
        }
    
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $EventSource -EntryType Information -EventId $EventID -Message $Message
        }
        else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $EventSource
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $EventID)
        }
    
        # Write-host "Event log entry created: $Message" 
    }
    catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }
    
    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}
    
    
    
    
function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [switch]$UseModule = $false,
        [string]$Caller = (Get-PSCallStack)[0].Command
    )
    
    # Add timestamp, computer name, and log level to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
    # Set foreground color based on log level
    switch ($Level) {
        'INFO' { $ForegroundColor = [ConsoleColor]::Green }
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
    }
    
    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    # Write-output $formattedMessage
    Write-host $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
    # Append to CSV file
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
    # Adjust this line in your script where you call the function
    # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
    
}
    
function Export-EventLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        wevtutil epl $LogName $ExportPath
    
        if (Test-Path $ExportPath) {
            Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        else {
            Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
    catch {
        Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}
    
# # Example usage
# $LogName = '$LoggingDeploymentNameLog'
# # $ExportPath = 'Path\to\your\exported\eventlog.evtx'
# $ExportPath = "C:\code\$LoggingDeploymentName\exports\Logs\$logname.evtx"
# Export-EventLog -LogName $LogName -ExportPath $ExportPath
    
    
    
    
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
    
    
    
Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################

       <#
.SYNOPSIS
    Installs a printer driver, creates a printer port, and adds a printer with specified settings, and imports a certificate into TrustedPublisher stores.

.DESCRIPTION
    This function automates the process of installing a printer driver, creating a printer port based on the provided IP address, and adding a printer with the specified name and settings. Additionally, it imports a specified certificate into both the Local Machine and Current User TrustedPublisher stores to ensure the printer driver is trusted. It checks for the existence of the printer driver, port, and printer itself, adding or replacing them as necessary. This function is ideal for setting up printers in a scripted, automated manner, ensuring that the necessary security certificates are in place.

.NOTES
    Version: 1.0
    Author: Abdullah Ollivierre
    Creation Date: 2024-Feb-13
    Last Modified: 2024-Feb-13
    Changes Log:
        1.0 - Initial version with capabilities to install printer drivers, create printer ports, add printers, and import certificates into TrustedPublisher stores.

.LINK
    https://call4cloud.nl/2021/07/what-about-printer-drivers/
    https://anthonyfontanez.com/index.php/2023/12/30/importing-certificates-with-remediations/


.EXAMPLE
    $PrinterName = "SHARP Concorde"
    $PrinterIPAddress = "192.168.53.151"
    $DriverName = "SHARP MX-4071 PCL6"
    $InfPathRelativeToscriptDirectory = "Driver\su2emenu.inf"
    $CertificatePathRelativeToscriptDirectory = "Path\To\Certificate\cert_name.cer"

    Install-PrinterAndCert -PrinterName $PrinterName -PrinterIPAddress $PrinterIPAddress -DriverName $DriverName -InfPathRelativeToscriptDirectory $InfPathRelativeToscriptDirectory -CertificatePathRelativeToscriptDirectory $CertificatePathRelativeToscriptDirectory

    This example sets up a printer named 'SHARP Concord' using the 'SHARP MX-4071 PCL6' driver and the specified IP address. It imports a certificate from the specified path into the TrustedPublisher stores.
#>



<#
.SYNOPSIS
Initializes and validates paths for the printer driver and certificate files, and constructs the printer port name.

.DESCRIPTION
This function prepares the environment for printer installation by constructing the full paths to the INF file and certificate based on the script directory. It also generates the port name based on the printer's IP address. This setup is essential for the subsequent steps of the printer installation process.

.PARAMETER InfPathRelativeToscriptDirectory
The relative path to the INF file from the script directory.

.PARAMETER CertificatePathRelativeToscriptDirectory
The relative path to the certificate file from the script directory.

.PARAMETER PrinterIPAddress
The IP address of the printer, used to construct the port name.

.PARAMETER ScriptDirectory
The directory where the script is located, used as the base for constructing full paths to the INF and certificate files.

.OUTPUTS
Custom object with properties for InfPath, CertPath, and PortName, ready for use in printer installation tasks.

.EXAMPLE
$initializationResult = Initialize-PrinterInstallationVariables -InfPathRelativeToscriptDirectory "Driver\su2emenu.inf" -CertificatePathRelativeToscriptDirectory "sharp.cer" -PrinterIPAddress "192.168.1.100" -ScriptDirectory $scriptDirectory

Initializes the paths and port name for the printer installation process.
#>

function Initialize-PrinterInstallationVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InfPathRelativeToscriptDirectory,

        # [Parameter(Mandatory = $true)]
        # [string]$CertificatePathRelativeToscriptDirectory,

        [Parameter(Mandatory = $true)]
        [string]$PrinterIPAddress

        # [Parameter(Mandatory = $true)]
        # [string]$ScriptDirectory
    )

    # $InfPath = Join-Path -Path $ScriptDirectory -ChildPath $InfPathRelativeToscriptDirectory
    $InfPath = Join-Path -Path $PSScriptRoot -ChildPath $InfPathRelativeToscriptDirectory
    # $CertPath = Join-Path -Path $ScriptDirectory -ChildPath $CertificatePathRelativeToscriptDirectory
    $PortName = "IP_$PrinterIPAddress"

    # Return an object with the initialized variables
    return [PSCustomObject]@{
        InfPath = $InfPath
        CertPath = $CertPath
        PortName = $PortName
    }
}




<#
.SYNOPSIS
Imports a certificate for the printer installation process.

.DESCRIPTION
This function imports a specified certificate file into the Trusted Publisher stores of both the Local Machine and Current User. This step is critical for allowing the installation of printer drivers that require signed drivers, especially in environments with strict security policies.

.PARAMETER CertPath
The full path to the certificate file that needs to be imported.

.OUTPUTS
None. This function performs actions but does not return any output. It logs success or failure of the certificate importation process.

.EXAMPLE
Import-PrinterCertificate -CertPath "C:\PrinterInstall\sharp.cer"

Imports the specified certificate into the Trusted Publisher certificate stores of the Local Machine and Current User.
#>

function Import-PrinterCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertPath
    )

    Write-EnhancedLog -Message "Checking certificate file at path: $CertPath" -Level "INFO" -ForegroundColor Green
    
    # Check if the certificate file exists
    if (Test-Path -Path $CertPath) {
        Write-EnhancedLog -Message "Certificate file found. Proceeding with import..." -Level "INFO" -ForegroundColor Green
        try {
            Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
            Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\CurrentUser\TrustedPublisher
            Write-EnhancedLog -Message "Certificate imported successfully into both LocalMachine and CurrentUser stores." -Level "INFO" -ForegroundColor Green
        }
        catch {
            Write-EnhancedLog -Message "Failed to import certificate. Error: $_" -Level "ERROR" -ForegroundColor Red
        }
    }
    else {
        Write-EnhancedLog -Message "Certificate file does not exist at the specified path: $CertPath" -Level "ERROR" -ForegroundColor Red
    }
}





<#
.SYNOPSIS
Installs the printer driver from a specified INF file.

.DESCRIPTION
This function checks for the existence of the specified INF file and whether the printer driver is already installed. If the driver is not found, it proceeds with the installation using the INF file. This process is crucial for setting up printers that require specific drivers not included with the operating system.

.PARAMETER InfPath
The full path to the printer driver's INF file.

.PARAMETER DriverName
The name of the printer driver to check for and install.

.OUTPUTS
None. This function performs actions but does not return any output. It logs the progress and outcome of the driver installation process.

.EXAMPLE
Install-PrinterDriver -InfPath "C:\PrinterInstall\Driver\su2emenu.inf" -DriverName "SHARP MX-3071 PCL6"

Checks for the SHARP MX-3071 PCL6 driver and installs it using the specified INF file if it's not already installed.
#>

function Install-PrinterDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InfPath,

        [Parameter(Mandatory = $true)]
        [string]$DriverName
    )

    Write-EnhancedLog -Message "Checking INF file at path: $InfPath" -Level "INFO" -ForegroundColor Green

    if (Test-Path -Path $InfPath) {
        Write-EnhancedLog -Message "INF file found. Verifying driver installation status..." -Level "INFO" -ForegroundColor Green
        $DriverExists = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
        if (-not $DriverExists) {
            try {
                Write-EnhancedLog -Message "Driver $DriverName not found. Proceeding with installation." -Level "INFO" -ForegroundColor Green
                pnputil.exe /add-driver $InfPath /install
                Add-PrinterDriver -Name $DriverName
                Write-EnhancedLog -Message "Printer driver $DriverName installed successfully." -Level "INFO" -ForegroundColor Green
            }
            catch {
                Write-EnhancedLog -Message "Failed to install printer driver $DriverName. Error: $_" -Level "ERROR" -ForegroundColor Red
            }
        }
        else {
            Write-EnhancedLog -Message "Printer driver $DriverName already exists. Skipping installation." -Level "INFO" -ForegroundColor Yellow
        }
    }
    else {
        Write-EnhancedLog -Message "INF file does not exist at the specified path: $InfPath" -Level "ERROR" -ForegroundColor Red
    }
}




<#
.SYNOPSIS
Adds or verifies a printer port for a network printer based on the IP address.

.DESCRIPTION
This function checks for the existence of a printer port named after the printer's IP address. If the port does not exist, the function creates it. This step is essential for network printer installations where communication is over a specific IP address.

.PARAMETER PortName
The name of the printer port, typically derived from the printer's IP address.

.PARAMETER PrinterIPAddress
The IP address of the printer, used to create the port if it does not exist.

.OUTPUTS
None. This function performs actions but does not return any output. It logs the status of the printer port creation or existence verification.

.EXAMPLE
Configure-PrinterPort -PortName "IP_192.168.1.100" -PrinterIPAddress "192.168.1.100"

Checks for the existence of a printer port for the IP address 192.168.1.100 and adds it if it does not exist.
#>

function Configure-PrinterPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PortName,

        [Parameter(Mandatory = $true)]
        [string]$PrinterIPAddress
    )

    Write-EnhancedLog -Message "Checking for existence of printer port $PortName" -Level "INFO" -ForegroundColor Green

    $PortExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if (-not $PortExists) {
        try {
            Write-EnhancedLog -Message "Printer port $PortName does not exist. Adding new port for IP address $PrinterIPAddress." -Level "INFO" -ForegroundColor Green
            Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIPAddress
            Write-EnhancedLog -Message "Printer port $PortName added successfully." -Level "INFO" -ForegroundColor Green
        }
        catch {
            Write-EnhancedLog -Message "Failed to add printer port $PortName. Error: $_" -Level "ERROR" -ForegroundColor Red
        }
    }
    else {
        Write-EnhancedLog -Message "Printer port $PortName already exists. No action needed." -Level "INFO" -ForegroundColor Yellow
    }
}




<#
.SYNOPSIS
Adds a new printer or updates an existing one with the specified configuration.

.DESCRIPTION
This function checks if a printer with the given name already exists on the system. If it does, the existing printer is removed, and a new one is added with the specified configuration. If the printer does not exist, it is simply added. This ensures the printer is set up with the correct driver and port settings.

.PARAMETER PrinterName
The name of the printer to be added or updated.

.PARAMETER DriverName
The name of the printer driver to be used.

.PARAMETER PortName
The name of the printer port to be used, typically associated with the printer's IP address.

.OUTPUTS
None. This function performs actions but does not return any output. It logs the outcome of the printer addition or update process.

.EXAMPLE
AddOrUpdatePrinter -PrinterName "SHARP MX-3071" -DriverName "SHARP MX-3071 PCL6" -PortName "IP_192.168.1.100"

Adds or updates the SHARP MX-3071 printer with the specified driver and port.
#>

function AddOrUpdatePrinter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrinterName,

        [Parameter(Mandatory = $true)]
        [string]$DriverName,

        [Parameter(Mandatory = $true)]
        [string]$PortName
    )

    Write-EnhancedLog -Message "Checking for existing printer: $PrinterName" -Level "INFO" -ForegroundColor Green

    $PrinterExists = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExists) {
        Write-EnhancedLog -Message "Printer $PrinterName already exists. Removing existing printer to update configuration." -Level "INFO" -ForegroundColor Yellow
        Remove-Printer -Name $PrinterName
    }
    
    try {
        Write-EnhancedLog -Message "Adding printer $PrinterName with driver $DriverName on port $PortName." -Level "INFO" -ForegroundColor Green
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
        Write-EnhancedLog -Message "Printer $PrinterName added or updated successfully." -Level "INFO" -ForegroundColor Green
    }
    catch {
        Write-EnhancedLog -Message "Failed to add or update printer $PrinterName. Error: $_" -Level "ERROR" -ForegroundColor Red
    }
}

# Determine the directory where the script is located
# $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define the path to the printer configuration JSON file
# $printerConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# Read configuration from the JSON file
# $printerConfig = Get-Content -Path $printerConfigPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
# $PrinterName = $printerConfig.PrinterName
# $PrinterIPAddress = $printerConfig.PrinterIPAddress
# $DriverName = $printerConfig.DriverName
# $InfPathRelative = $printerConfig.InfPathRelative

# Use the variables as needed in your script


# Step 1: Initialize Variables using splatting
$params = @{
    InfPathRelativeToscriptDirectory = $InfPathRelative
    # CertificatePathRelativeToscriptDirectory = $CertificatePathRelative
    PrinterIPAddress = $PrinterIPAddress
    # ScriptDirectory = $scriptDirectory
}

$initializationResult = Initialize-PrinterInstallationVariables @params


# Extracting specific variables from the initialization output
$InfPath = $initializationResult.InfPath
$CertPath = $initializationResult.CertPath
$PortName = $initializationResult.PortName

# Step 2: Import Certificate
# Import-PrinterCertificate -CertPath $CertPath

# Step 3: Install Printer Driver
Install-PrinterDriver -InfPath $InfPath -DriverName $DriverName

# Step 4: Configure Printer Port
Configure-PrinterPort -PortName $PortName -PrinterIPAddress $PrinterIPAddress

# Step 5: Add or Update Printer
AddOrUpdatePrinter -PrinterName $PrinterName -DriverName $DriverName -PortName $PortName

# Optionally, add any completion message or further steps
Write-EnhancedLog -Message "Printer installation and configuration completed successfully." -Level "INFO" -ForegroundColor Green
