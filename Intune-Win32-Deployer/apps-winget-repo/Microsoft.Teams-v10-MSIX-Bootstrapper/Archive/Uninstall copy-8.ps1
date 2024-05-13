#Unique Tracking ID: 40b55e68-84ef-4105-bb22-255dd14e51f8, Timestamp: 2024-02-29 09:26:28

Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-x" -Wait -WindowStyle Hidden

# Start-Sleep -Seconds 30

# Define a function for logging messages
function Write-Log {
    param ([string]$Message)
    Write-Host $Message
}

# Define a function for logging and stopping on errors
function Write-ErrorAndExit {
    param ([string]$Message)
    Write-Error $Message
    exit 1
}

# Get all provisioned app packages and filter for Microsoft Teams
$teamsProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like "*MSTeams*"
foreach ($package in $teamsProvisionedPackages) {
    try {
        # Remove the provisioned Teams package
        Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName
        Write-Log "Successfully removed provisioned package: $($package.DisplayName)"
    } catch {
        Write-Log "Failed to remove provisioned package: $($package.DisplayName). Error: $_"
    }
}

# Find the Microsoft Teams package for the current user
$teamsPackage = Get-AppxPackage | Where-Object { $_.Name -like "*MSTeams*" }
if ($teamsPackage) {
    # Attempt to remove the found package
    Remove-AppxPackage -Package $teamsPackage.PackageFullName
}


# Define base paths for cleanup
$pathsToSearch = @(
    "C:\ProgramData"
    # "C:\Program Files" # Uncomment or add other paths as needed
)

# Define the pattern to match the Teams installation and related data
$teamsPattern = "MSTeams_*_x64__*"

foreach ($basePath in $pathsToSearch) {
    $teamsItems = Get-ChildItem -Path $basePath -Filter $teamsPattern -Recurse -ErrorAction SilentlyContinue -Force

    if ($teamsItems.Count -gt 0) {
        foreach ($item in $teamsItems) {
            $itemPath = $item.FullName
            Write-Log "Processing item: $itemPath"

            # Take ownership of the item
            takeown /f "$itemPath" /r /d y | Out-Null

            # Grant full control permissions to the SYSTEM account for the item
            icacls "$itemPath" /grant "SYSTEM:(F)" /t /c | Out-Null

            # Remove the item forcefully
            try {
                Remove-Item -Path "$itemPath" -Recurse -Force -ErrorAction Stop
                Write-Log "Successfully removed: $itemPath"
            } catch {
                Write-Log "Failed to remove: $itemPath. Error: $_"
            }
        }
    } else {
        Write-Log "No Microsoft Teams items found under $basePath."
    }
}






# Base path where Microsoft Teams directories are located
$basePath = "C:\Program Files\WindowsApps"
# Pattern to match Microsoft Teams directories, accommodating version changes
$teamsPattern = "MSTeams_*_x64__*"

# Find Microsoft Teams directories matching the pattern
$teamsDirectories = Get-ChildItem -Path $basePath -Directory -Filter $teamsPattern -ErrorAction SilentlyContinue

# Check if any matching directories were found
if ($teamsDirectories.Count -gt 0) {
    foreach ($dir in $teamsDirectories) {
        $targetDirectory = $dir.FullName

        # Take ownership of the directory
        takeown /f $targetDirectory /r /d y

        # Grant full control to the Administrators group
        icacls $targetDirectory /grant "SYSTEM:(F)" /t

        # Attempt to remove the directory
        try {
            Remove-Item -Path $targetDirectory -Recurse -Force
            Write-Host "Successfully removed: $targetDirectory"
        } catch {
            Write-Error "Failed to remove: $targetDirectory. Error: $_"
        }
    }
} else {
    Write-Host "No Microsoft Teams directories found matching the pattern: $teamsPattern"
}
