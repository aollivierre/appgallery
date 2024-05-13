#Unique Tracking ID: 14a1cda5-5728-4e60-86c3-434acabb9b2e, Timestamp: 2024-03-05 11:43:45
<#
.SYNOPSIS
Checks for the installation of FortiClient versions older than 7.2.3.0929.

.DESCRIPTION
This script searches the system's uninstallation registry keys for FortiClient installations. 
It checks if any installed version is older than 7.2.3.0929 and provides feedback based on this condition.

.NOTES
Version:        1.0
Author:         Abdullah Ollivierre
Creation Date:  2024-03-05
#>

# Define global variables
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$softwareNamePattern = "*Forti*"
$versionThreshold = New-Object Version "7.2.3.0929"

# Function to check for FortiClient versions older than a specified version
function Find-OlderFortiClientVersion {
    param (
        [string[]]$RegistryPaths,
        [string]$SoftwareNamePattern,
        [version]$VersionThreshold
    )

    foreach ($path in $RegistryPaths) {
        $items = Get-ChildItem -Path $path

        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath
            if ($app.DisplayName -like $SoftwareNamePattern) {
                $appVersion = New-Object Version $app.DisplayVersion
                if ($appVersion -lt $VersionThreshold) {
                    return @{
                        Found = $true
                        ProductCode = $app.PSChildName
                        Version = $app.DisplayVersion
                    }
                }
            }
        }
    }

    return @{Found = $false}
}

# Main script execution
$findResult = Find-OlderFortiClientVersion -RegistryPaths $registryPaths -SoftwareNamePattern $softwareNamePattern -VersionThreshold $versionThreshold

if ($findResult.Found) {
    Write-Output "An older version of FortiClient (version $($findResult.Version)) is installed with product code $($findResult.ProductCode)."
    exit 0
} else {
    # Write-Output "No version of FortiClient older than 7.2.3.0929 is installed."
    exit 1
}
