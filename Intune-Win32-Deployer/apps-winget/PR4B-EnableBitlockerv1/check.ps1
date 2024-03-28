# JSON string
$json = @'
{
  "PackageName": "PR4B_EnableBitlocker",
  "PackageUniqueGUID": "419499a4-f334-4cbb-bfdb-f1cbe856829f",
  "Version": 1,
  "PackageExecutionContext": "system",
  "RepetitionInterval": "PT5M",
  "LoggingDeploymentName": "PR4B_EnableBitlockerCustomlog",
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
