#Unique Tracking ID: 239f65ce-a4fe-4b0d-82ce-8295ad160753, Timestamp: 2024-02-26 14:44:46
# JSON string
$json = @'
{
    "PackageName": "PR4B_BackupDownloadsFolder",
    "PackageUniqueGUID": "f18f8d73-cf1d-41d9-b8a1-cc6d9e7873ce",
    "Version": 1,
    "PackageExecutionContext": "User",
    "RepetitionInterval": "PT60M",
    "LoggingDeploymentName": "PR4B_BackupDownloadsFolderCustomlog",
    "ScriptMode": "Remediation"
  }
'@

# Convert JSON string to a PowerShell object
$Config = $json | ConvertFrom-Json

# Assign values from JSON to variables
$PackageName = $Config.PackageName
$PackageUniqueGUID = $Config.PackageUniqueGUID
$Version = $Config.Version

# Construct the scheduled task name
$schtaskName = "$PackageName - $PackageUniqueGUID"

# Check if the scheduled task exists and matches the version
$Task_existing = Get-ScheduledTask -TaskName $schtaskName -ErrorAction SilentlyContinue
if ($Task_existing -and $Task_existing.Description -like "Version $Version*") {
    Write-Host "Found it!"
    exit 0
} else {
    exit 1
}
