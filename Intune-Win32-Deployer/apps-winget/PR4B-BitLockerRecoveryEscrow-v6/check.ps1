#Unique Tracking ID: cbc86570-9426-4ca6-b839-6c94503a49ad, Timestamp: 2024-02-28 11:59:02
# JSON string
$json = @'
{
    "PackageName": "PR4B_BitLockerRecoveryEscrow",
    "PackageUniqueGUID": "70e7afd0-bad3-4282-aa02-c443b533b9e2",
    "Version": 1,
    "PackageExecutionContext": "System",
    "RepetitionInterval": "PT5M",
    "LoggingDeploymentName": "PR4B_BitLockerRecoveryEscrowCustomlog",
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
