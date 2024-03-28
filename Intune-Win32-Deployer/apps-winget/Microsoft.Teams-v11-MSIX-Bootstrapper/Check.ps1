#Unique Tracking ID: f6556b94-6e44-471b-a3ff-3d212324786c, Timestamp: 2024-02-29 22:43:37
# Define the base path for WindowsApps
$windowsAppsPath = "C:\Program Files\WindowsApps"
# Define the search pattern for Microsoft Teams MSIX 64x package
$teamsSearchPattern = "MSTeams_*_x64__*"

# Define the minimum acceptable version of Microsoft Teams
$minimumVersion = [Version]"24004.1307.2669.7070"

# Initialize a flag to track the overall check status
$allChecksPassed = $true

# Check for Microsoft Teams provisioned packages
$teamsProvisioned = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*MSTeams*"
if (-not $teamsProvisioned) {
    # Write-Host "Microsoft Teams is not provisioned for new users."
    $allChecksPassed = $false
} else {
    # Write-Host "Microsoft Teams is provisioned for new users."
}

# Search for Microsoft Teams installation folders in WindowsApps
$teamsInstallations = Get-ChildItem -Path $windowsAppsPath -Directory -Filter $teamsSearchPattern -ErrorAction SilentlyContinue
if ($teamsInstallations) {
    $latestTeamsInstallation = $teamsInstallations[-1]
    $versionRegex = [regex]"_(\d+\.\d+\.\d+\.\d+)_"
    $match = $versionRegex.Match($latestTeamsInstallation.Name)
    if ($match.Success) {
        $installedVersion = [Version]$match.Groups[1].Value
        if ($installedVersion -ge $minimumVersion) {
            # Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed in WindowsApps and meets the minimum version requirement."
        } else {
            # Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed in WindowsApps but does not meet the minimum version requirement."
            $allChecksPassed = $false
        }
    } else {
        # Write-Host "Unable to determine the installed version of Microsoft Teams in WindowsApps."
        $allChecksPassed = $false
    }
} else {
    # Write-Host "Microsoft Teams (MSIX 64x) is not installed in WindowsApps."
    $allChecksPassed = $false
}

# Final decision based on all checks
if ($allChecksPassed) {
    Write-Host "All checks passed. Write-Host Microsoft Teams (MSIX 64x) version $installedVersion is installed in WindowsApps and meets the minimum version requirement."
    exit 0
} else {
    # Write-Host "One or more checks failed."
    exit 1
}
