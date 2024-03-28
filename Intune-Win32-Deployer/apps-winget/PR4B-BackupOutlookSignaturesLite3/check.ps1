#Unique Tracking ID: 7a01561e-e86e-4f68-9dd5-c0bbd363642e, Timestamp: 2024-02-26 14:22:51
# JSON string
$json = @'
{
  "PackageName": "PR4B_BackupOutlookSignature",
  "PackageUniqueGUID": "59538485-f73b-42b2-975d-3365aa81ec3b",
  "Version": 1,
  "PackageExecutionContext": "User",
  "RepetitionInterval": "PT60M",
  "LoggingDeploymentName": "PR4B_BackupOutlookSignatureCustomlog",
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
