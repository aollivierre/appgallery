#Unique Tracking ID: 1d857342-fff3-4fea-8adf-2ca4a3aea6c8, Timestamp: 2024-02-27 16:32:03
# JSON string
$json = @'
{
    "PackageName": "PR4B_RemoveWSUS",
    "PackageUniqueGUID": "790c4c62-1b02-4857-9bc6-fbfb786cd824",
    "Version": 1,
    "PackageExecutionContext": "System",
    "RepetitionInterval": "PT5M",
    "LoggingDeploymentName": "PR4B_RemoveWSUSCustomlog",
    "ScriptMode": "PackageName"
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
