#Unique Tracking ID: dd10157c-ef4e-47f9-9948-b8178807b27e, Timestamp: 2024-02-24 12:28:16

# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
$Version = $config.Version

$schtaskName = "$PackageName - $PackageUniqueGUID"

# Check if Task exist with correct version
$Task_existing = Get-ScheduledTask -TaskName $schtaskName -ErrorAction SilentlyContinue
if ($Task_existing.Description -like "Version $Version*") {
    Write-Host "Found it!"
    exit 0
} else {
    exit 1
}
