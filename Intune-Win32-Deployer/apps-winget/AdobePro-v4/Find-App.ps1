#Unique Tracking ID: e40d98b4-03a5-40dd-b624-e2d68d8c33d6, Timestamp: 2024-04-04 18:30:45
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$softwareNamePattern = "*Adobe*"

# Function to check for any installed version of AdobeReader
function Find-AdobeReader {
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
                    Found           = $true
                    DisplayName     = $app.DisplayName
                    Version         = $app.DisplayVersion
                    InstallLocation = $app.InstallLocation
                }
            }
        }
    }

    return @{Found = $false }
}

# Main script execution
$findResult = Find-AdobeReader -RegistryPaths $registryPaths -SoftwareNamePattern $softwareNamePattern

if ($findResult.Found) {
    Write-Output "AdobeReader is installed. Details:"
    Write-Output "Name: $($findResult.DisplayName)"
    Write-Output "Version: $($findResult.Version)"
    Write-Output "Install Location: $($findResult.InstallLocation)"
}
else {
    Write-Output "AdobeReader is not installed."
}



# AdobeReader is installed. Details:
# Name: AdobeReaderRMMAgent
# Version: 5.7.8836
# Install Location: C:\Program Files (x86)/bellwoodsmainoffice-5.7.8836
