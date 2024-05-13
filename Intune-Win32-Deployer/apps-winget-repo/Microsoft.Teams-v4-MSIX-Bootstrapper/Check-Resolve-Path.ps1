# Define the search pattern for the Microsoft Teams installation directory
$teamsSearchPattern = "C:\Program Files\WindowsApps\MSTeams_*_x64__*"

# Define the minimum acceptable version of Microsoft Teams
$minimumVersion = [Version]"24004.1307.2669.7070"

try {
    # Attempt to resolve the path(s) for Microsoft Teams installation(s)
    $resolvedPaths = Resolve-Path -Path $teamsSearchPattern -ErrorAction Stop
    
    # If multiple installations are found, use the last one assuming it's the most recent
    $mostRecentPath = ($resolvedPaths.Path)[-1]
    
    # Extract the version number from the installation path
    $versionMatch = [regex]::Match($mostRecentPath, 'MSTeams_(\d+\.\d+\.\d+\.\d+)_x64__').Groups[1].Value
    if ($versionMatch.Success -and [Version]$versionMatch.Value -ge $minimumVersion) {
        Write-Host "Microsoft Teams (MSIX 64x) version $versionMatch is installed and meets the minimum version requirement at $mostRecentPath."
        exit 0
    } else {
        Write-Host "Microsoft Teams (MSIX 64x) version found does not meet the minimum version requirement."
        exit 1
    }
} catch {
    # Handle errors (e.g., path not found)
    Write-Host "Error finding Microsoft Teams installation: $_"
    exit 1
}