try {
    # Get all installed applications using WMI
    $installedApps = Get-WmiObject -Class Win32_Product

    # Filter the results to get Microsoft Office installations
    $officeApps = $installedApps | Where-Object { $_.Name -like "Microsoft Office*" }

    # If no Office installations are found, exit
    if (-not $officeApps) {
        Write-Output "No Microsoft Office installation found."
        exit 1
    }

    # Extract and display the highest version number
    $latestVersion = ($officeApps | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Output "The latest installed version of Microsoft Office is: $latestVersion"

    exit 0
} catch {
    Write-Error "An error occurred: $_"
    exit 2
}
