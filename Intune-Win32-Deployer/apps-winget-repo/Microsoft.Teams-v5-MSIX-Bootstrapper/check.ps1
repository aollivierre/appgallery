# Define the base path for WindowsApps
$windowsAppsPath = "C:\Program Files\WindowsApps"
# Define the search pattern for Microsoft Teams MSIX 64x package
$teamsSearchPattern = "MSTeams_*_x64__*"

# Define the minimum acceptable version of Microsoft Teams
$minimumVersion = [Version]"24004.1307.2669.7070"

# Search for Microsoft Teams installation folders
$teamsInstallations = Get-ChildItem -Path $windowsAppsPath -Directory -Filter $teamsSearchPattern -ErrorAction SilentlyContinue

if ($teamsInstallations) {
    # Assume the last installation is the most recent one if multiple versions are found
    $latestTeamsInstallation = $teamsInstallations[-1]
    # Extract version number from the installation folder name
    $versionRegex = [regex]"_(\d+\.\d+\.\d+\.\d+)_"
    $match = $versionRegex.Match($latestTeamsInstallation.Name)
    if ($match.Success) {
        $installedVersion = [Version]$match.Groups[1].Value
        if ($installedVersion -ge $minimumVersion) {
            Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed and meets the minimum version requirement at $($latestTeamsInstallation.FullName)."
            exit 0
        } else {
            # Write-Host "Microsoft Teams (MSIX 64x) version $installedVersion is installed but does not meet the minimum version requirement."
            exit 1
        }
    } else {
        # Write-Host "Unable to determine the installed version of Microsoft Teams."
        exit 1
    }
} else {
    # Write-Host "Microsoft Teams (MSIX 64x) is not installed."
    exit 1
}


#### Name              : MSTeams
#### Publisher         : CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US
#### Architecture      : X64
#### ResourceId        :
#### Version           : 24004.1307.2669.7070
#### PackageFullName   : MSTeams_24004.1307.2669.7070_x64__8wekyb3d8bbwe
#### InstallLocation   : C:\Program Files\WindowsApps\MSTeams_24004.1307.2669.7070_x64__8wekyb3d8bbwe
#### IsFramework       : False
#### PackageFamilyName : MSTeams_8wekyb3d8bbwe
#### PublisherId       : 8wekyb3d8bbwe
#### IsResourcePackage : False
#### IsBundle          : False
#### IsDevelopmentMode : False
#### NonRemovable      : False
#### IsPartiallyStaged : False
#### SignatureKind     : Developer
#### Status            : Ok

