$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$productCode = "{079B00DA-23ED-4F29-AED8-7137A11CCD4A}"
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
    Write-Output "The application with product code $productCode is installed."
    exit 0
} else {
    # Write-Output "The application with product code $productCode is not installed."
    exit 1
}