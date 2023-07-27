$huntressUninstallPath = "C:\Program Files\Huntress\uninstall.exe"

function Uninstall-Huntress {
    try {
        # Check if the uninstall.exe exists at the specified path
        if (Test-Path $huntressUninstallPath) {
            # Run the Huntress uninstall.exe with the /S flag for a silent uninstall
            & $huntressUninstallPath /S
        } else {
            Write-Host "Huntress uninstall.exe not found at $huntressUninstallPath" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
}

# Call the function
Uninstall-Huntress
