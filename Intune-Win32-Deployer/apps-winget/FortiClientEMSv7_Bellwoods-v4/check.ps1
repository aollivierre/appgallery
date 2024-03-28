#Unique Tracking ID: 9e17d4ea-6b5c-4d4a-bac8-f89387197cd4, Timestamp: 2024-02-26 23:08:39
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$productCode = "{611804A7-F14E-45A2-9F55-345D33EDD28E}"
$isInstalled = $false

foreach ($key in $uninstallKeys) {
    Get-ChildItem -Path $key |
    ForEach-Object {
        $app = Get-ItemProperty -Path $_.PsPath
        if ($app.PSChildName -eq $productCode) {
            $isInstalled = $true
            break
        }
    }
    
    if ($isInstalled) {
        break
    }
}

# Conditionally proceed based on the checks
if ($isInstalled) {
    Write-Output "FortiClient v7.2.3 with product code $productCode is installed."
    exit 0
} else {
    # Write-Output "FortiClient v7.0.9 product code $productCode is not installed."
    exit 1
}
