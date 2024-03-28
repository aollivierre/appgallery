# Name pattern for Microsoft Teams MSIX 64x package
$teamsPackageNamePattern = "MSTeams*"

# Define the minimum acceptable version of Microsoft Teams
$minimumVersion = [Version]"24004.1307.2669.7070"

# Attempt to find the Teams package
$teamsPackage = Get-AppxPackage -Name $teamsPackageNamePattern -ErrorAction SilentlyContinue

if ($teamsPackage) {
    # Convert the installed version string to a Version object
    $installedVersion = [Version]$teamsPackage.Version

    # Compare the installed version to the minimum version
    if ($installedVersion -ge $minimumVersion) {
        Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed and meets the minimum version requirement."
        exit 0
    } else {
        # Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed but does not meet the minimum version requirement."
        exit 1
    }
} else {
    # Write-Host "Microsoft Teams (MSIX 64x) is not installed."
    exit 1
}