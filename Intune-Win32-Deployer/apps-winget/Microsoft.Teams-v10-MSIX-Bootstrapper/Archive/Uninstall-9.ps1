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
    # "C:\Program Files"
)

# Define the pattern to match the Teams installation and related data
$teamsPattern = "MSTeams_*_x64__*"

# Adjusted portion of the script for clarity and correctness

foreach ($basePath in $pathsToSearch) {
    # $foundItems = $false

    $teamsItems = Get-ChildItem -Path $basePath -Filter $teamsPattern -Recurse -ErrorAction SilentlyContinue
    if ($teamsItems) {
        # $foundItems = $true
        foreach ($item in $teamsItems) {
            # Existing logic for handling found items
            $itemPath = $item.FullName
            Write-Log "Found item: $itemPath"
            # Followed by take ownership and remove logic...
        }
    } else {
        Write-Log "No Microsoft Teams items found under $basePath."
    }

    # if (-not $foundItems -and $basePath -eq "C:\Program Files") {
    #     Write-Error "No Microsoft Teams items found under $basePath. Halting operation."
    #     exit 1
    # }
}


# $windowsAppsPath = "C:\Program Files\WindowsApps"
# $teamsPattern = "MSTeams_*_x64__*"

# # Attempting direct enumeration within WindowsApps might require adjusting access permissions or using different cmdlets/tools
# $teamsInstallations = Get-ChildItem -Path $windowsAppsPath -Include $teamsPattern -Recurse -Directory -ErrorAction SilentlyContinue -Force

# if (-not $teamsInstallations) {
#     Write-Error "No Microsoft Teams items found under $windowsAppsPath. Halting operation."
#     exit 1
# } else {
#     foreach ($installation in $teamsInstallations) {
#         Write-Host "Found Microsoft Teams installation: $($installation.FullName)"
#         # Proceed with your logic for each found item
#     }
# }

# Note: Using -Force to attempt to bypass some permission restrictions, though success may vary



# PowerShell script to forcefully remove a specific Microsoft Teams directory

# Specify the full path of the target directory
# $targetDirectory = "C:\Program Files\WindowsApps\MSTeams_24004.1307.2669.7070_x64__8wekyb3d8bbwe"

# # Take ownership of the directory
# takeown /f $targetDirectory /r /d y

# # Grant full control to the current user (replace 'USERNAME' with your actual username or use a wildcard like '*S-1-5-32-544' for administrators)
# icacls $targetDirectory /grant "${env:USERNAME}:(F)" /t

# # Attempt to remove the directory
# try {
#     Remove-Item -Path $targetDirectory -Recurse -Force
#     Write-Host "Successfully removed: $targetDirectory"
# } catch {
#     Write-Error "Failed to remove: $targetDirectory. Error: $_"
# }












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
        icacls $targetDirectory /grant "Administrators:(F)" /t

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
