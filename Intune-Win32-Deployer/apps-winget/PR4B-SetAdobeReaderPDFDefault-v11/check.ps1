#Unique Tracking ID: b198e008-7184-43d9-ab6d-7143432ca508, Timestamp: 2024-02-28 14:02:26
# JSON string
$json = @'
{
    "PackageName": "PR4B_SetAdobeReaderPDFDefault",
    "PackageUniqueGUID": "db96ca9b-3d44-4d86-9bb5-742e85a63724",
    "Version": 1,
    "PackageExecutionContext": "user",
    "RepetitionInterval": "PT5M",
    "LoggingDeploymentName": "PR4B_SetAdobeReaderPDFDefaultCustomlog",
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
