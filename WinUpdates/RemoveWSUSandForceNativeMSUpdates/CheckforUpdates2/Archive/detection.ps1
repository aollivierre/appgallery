# try {
#     $serviceName = "wuauserv"  # Windows Update Service

#     # Get the status of the Windows Update service
#     $serviceStatus = Get-Service -Name $serviceName -ErrorAction Stop

#     # Check if the service is running
#     if ($serviceStatus.Status -eq 'Running') {
#         # Write-Host "Windows Update service is running."
#         exit 0
#     } else {
#         # Write-Host "Windows Update service is not running. Action may be required."
#         exit 1
#     }
# } catch {
#     # Service not found or another error occurred
#     # Write-Error "An error occurred: $_"
#     exit 2
# }




 # Generate a timestamp for the log file name
 $timestampForFileName = Get-Date -Format "yyyyMMdd-HHmmss"
 $logDirectory = "C:\Code\WinUpdates\logs"
 $logFilePath = Join-Path $logDirectory "_$timestampForFileName.log"

 # Function to ensure log directory exists
 function Ensure-LogDirectoryExists {
     param([string]$Path)
     if (-not (Test-Path -Path $Path)) {
         New-Item -Path $Path -ItemType Directory | Out-Null
     }
 }

 # Function to append a message to the log file
 function Write-Logwithtimestampwithtimestamp {
     param([string]$Message)
     Ensure-LogDirectoryExists -Path $logDirectory
     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
     Add-Content -Path $logFilePath -Value "[$timestamp] $Message"
 }

try {
    $serviceName = "wuauserv"  # Windows Update Service

    # Get the status of the Windows Update service
    $serviceStatus = Get-Service -Name $serviceName -ErrorAction Stop

    # Check if the service is running
    if ($serviceStatus.Status -eq 'Running') {
        Write-Host "Windows Update service is running. running remediation with exit code 1"
        Write-Logwithtimestamp "Windows Update service is running. running remediation with exit code 1"
        exit 1
    } else {
        Write-Host "Windows Update service is not running. Remediation NOT required. exit code 0"
        Write-Logwithtimestamp "Windows Update service is not running. Remediation NOT required. exit code 0"
        exit 0
    }
} catch {
    # Service not found or another error occurred
    Write-Error "An error occurred: $_"
    Write-Logwithtimestamp "An error occurred: $_"
    exit 2
}