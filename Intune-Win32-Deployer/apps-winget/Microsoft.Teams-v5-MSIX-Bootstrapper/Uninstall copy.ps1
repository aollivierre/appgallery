#Unique Tracking ID: 40b55e68-84ef-4105-bb22-255dd14e51f8, Timestamp: 2024-02-29 09:26:28
# .\teamsbootstrapper.exe -x


Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-x" -Wait -WindowStyle Hidden

Start-Sleep -Seconds '30'


# Define base paths for cleanup
$windowsAppsDeletedPath = "C:\Program Files\WindowsApps\Deleted"
$appRepositoryPath = "C:\ProgramData\Microsoft\Windows\AppRepository"

# Define the pattern to match the Teams installation and related data
$teamsPattern = "MSTeams_*_x64__*"

# Logging function for easier message output
# function Write-Log {
#     param ([string]$Message)
#     Write-Host $Message
# }

# Find and attempt to remove the Teams directories under WindowsApps\Deleted
$teamsDirs = Get-ChildItem -Path $windowsAppsDeletedPath -Filter $teamsPattern -Recurse -Directory -ErrorAction SilentlyContinue
if ($teamsDirs) {
    foreach ($dir in $teamsDirs) {
        # Write-Log "Attempting to delete directory: $($dir.FullName)"
        try {
            Remove-Item $dir.FullName -Recurse -Force -ErrorAction Stop
            # Write-Log "Successfully deleted: $($dir.FullName)"
        } catch {
            # Write-Log "Failed to delete: $($dir.FullName). Error: $_"
        }
    }
} else {
    # Write-Log "No Microsoft Teams directories found in $windowsAppsDeletedPath"
}

# Find and attempt to remove the Teams XML files in AppRepository
$teamsFiles = Get-ChildItem -Path $appRepositoryPath -Filter "$teamsPattern.xml" -Recurse -File -ErrorAction SilentlyContinue
if ($teamsFiles) {
    foreach ($file in $teamsFiles) {
        # Write-Log "Attempting to delete file: $($file.FullName)"
        try {
            Remove-Item $file.FullName -Force -ErrorAction Stop
            # Write-Log "Successfully deleted: $($file.FullName)"
        } catch {
            # Write-Log "Failed to delete: $($file.FullName). Error: $_"
        }
    }
} else {
    # Write-Log "No Microsoft Teams XML files found in $appRepositoryPath"
}
