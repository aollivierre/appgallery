#Unique Tracking ID: df12a7ad-9937-4dcf-9133-e135501f9516, Timestamp: 2024-02-28 13:18:01
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