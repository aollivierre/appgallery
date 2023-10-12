$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$productCode = "{4B553DAB-DE27-4424-B32E-E849A3517AA2}"
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
    Write-Output "FortiClient v6.4.3 with product code $productCode is installed."
    exit 0
} else {
    # Write-Output "FortiClient v7.0.9 product code $productCode is not installed."
    exit 1
}