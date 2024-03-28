Start-Process -FilePath ".\f.exe" -ArgumentList "/S", "/V`"/qn ALLUSERS=1`"" -Wait

function WaitForFile {
    $filePath = "C:\Program Files (x86)\FileHold\FDA\FDA.exe"
    $desiredVersion = "17.0.0.0"
    $timeoutSeconds = 120 # 2 minutes
    $elapsedSeconds = 0

    while ($elapsedSeconds -lt $timeoutSeconds) {
        if (Test-Path $filePath) {
            $fileVersion = (Get-ItemProperty $filePath).VersionInfo.FileVersion
            if ($fileVersion -eq $desiredVersion) {
                # Write-Host "File with desired version found."
                return $true
            }
        }

        Start-Sleep -Seconds 1
        $elapsedSeconds++
    }

    # Write-Host "Timeout reached or file not found with the desired version."
    return $false
}

# Call the function
$result = WaitForFile
if ($result) {
    # Write-Host "Exiting with success."
} else {
    # Write-Host "Exiting with failure."
}