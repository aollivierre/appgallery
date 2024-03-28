$file = "C:\Program Files (x86)\FileHold\FDA\FDA.exe"
$requiredVersion = "17.0.0.0"  # Assuming version 17 is denoted as 17.0.0.0

if (Test-Path $file) {
    $versionInfo = (Get-ItemProperty $file).VersionInfo
    if ($versionInfo.FileVersion -eq $requiredVersion) {
        Write-Output "File Hold version 17 found."
        exit 0
    } else {
        # Write-Output "File Hold 17 not found."
        exit 1
    }
} else {
    # Write-Output "File Hold not found."
    exit 1
}


