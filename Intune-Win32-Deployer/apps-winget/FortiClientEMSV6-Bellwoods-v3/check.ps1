#Unique Tracking ID: 47c68641-620d-4938-8eeb-342f9111cfe1, Timestamp: 2024-02-26 23:05:50

$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$productCode = "{611804A7-F14E-45A2-9F55-345D33EDD28E}"
$otherVersionInstalled = $false
$otherVersionProductCode = ""

foreach ($key in $uninstallKeys) {
    Get-ChildItem -Path $key |
    ForEach-Object {
        $app = Get-ItemProperty -Path $_.PsPath
        if ($app.PSChildName -ne $productCode -and $app.DisplayName -like "*Forti*") {
            $otherVersionInstalled = $true
            $otherVersionProductCode = $app.PSChildName
            break
        }
    }
    
    if ($otherVersionInstalled) {
        break
    }
}

# Conditionally proceed based on the checks
if ($otherVersionInstalled) {
    Write-Output "A different version of FortiClient is installed with product code $otherVersionProductCode."
    exit 0
} else {
    # Write-Output "No other version of FortiClient, or only the specified version with product code $productCode, is installed."
    exit 1
}
