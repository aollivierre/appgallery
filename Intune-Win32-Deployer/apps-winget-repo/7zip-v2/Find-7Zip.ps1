#Unique Tracking ID: 8cf8eb75-83a6-4bd9-92c0-2d0e8ae0b417, Timestamp: 2024-03-19 14:18:39
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$softwareNamePattern = "*7-Zip*"

# Function to check for any installed version of 7zip
function Find-7zip {
    param (
        [string[]]$RegistryPaths,
        [string]$SoftwareNamePattern
    )

    foreach ($path in $RegistryPaths) {
        $items = Get-ChildItem -Path $path

        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath
            if ($app.DisplayName -like $SoftwareNamePattern) {
                return @{
                    Found = $true
                    DisplayName = $app.DisplayName
                    Version = $app.DisplayVersion
                    InstallLocation = $app.InstallLocation
                }
            }
        }
    }

    return @{Found = $false}
}

# Main script execution
$findResult = Find-7zip -RegistryPaths $registryPaths -SoftwareNamePattern $softwareNamePattern

if ($findResult.Found) {
    Write-Output "7zip is installed. Details:"
    Write-Output "Name: $($findResult.DisplayName)"
    Write-Output "Version: $($findResult.Version)"
    Write-Output "Install Location: $($findResult.InstallLocation)"
} else {
    Write-Output "7zip is not installed."
}
