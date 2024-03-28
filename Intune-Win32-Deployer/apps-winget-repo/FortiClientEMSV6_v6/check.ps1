$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$productCode = "{D6A52B20-063A-4BF6-8228-CDADBF8ACBCF}"
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