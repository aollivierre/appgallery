#Unique Tracking ID: 31cc7032-f1f1-464e-99b3-e6d64f1e965f, Timestamp: 2024-02-26 14:44:16


# Find the most recently created GUID-named folder under C:\Windows\IMECache\
$latestGUIDFolder = Get-ChildItem -Path 'C:\Windows\IMECache\' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# If a folder is found, proceed to locate config.json within it
if ($latestGUIDFolder) {
    $sourceConfigPath = Join-Path -Path $latestGUIDFolder.FullName -ChildPath "config.json"

    # Check if config.json exists in the found folder
    if (Test-Path -Path $sourceConfigPath) {
        # Define the destination path for config.json using $PSScriptRoot
        $destinationConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

        # Copy the config.json from the source to the destination path
        Copy-Item -Path $sourceConfigPath -Destination $destinationConfigPath -Force

        # Attempt to read the copied config.json file
        $config = Get-Content -Path $destinationConfigPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue

    } else {
        # write-host "config.json not found in the latest GUID folder: $($latestGUIDFolder.FullName)"
    }
} else {
    # write-host "No GUID-named folder found under C:\Windows\IMECache\"
}



# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json


# Your existing script with added logging
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue


# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
$Version = $config.Version

$schtaskName = "$PackageName - $PackageUniqueGUID"

$Task_existing = Get-ScheduledTask -TaskName $schtaskName -ErrorAction SilentlyContinue
if ($Task_existing.Description -like "Version $Version*") {
    Write-Host "Found it!"
    exit 0
}
else {
    exit 1
}
