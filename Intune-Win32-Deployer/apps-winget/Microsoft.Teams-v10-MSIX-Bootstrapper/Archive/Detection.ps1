# PowerShell script to check if Microsoft Teams is running

try {
    # Attempt to find the Microsoft Teams process
    $teamsProcess = Get-Process ms-teams -ErrorAction Stop

    # If found, print a message and exit with code 0
    Write-Host "Microsoft Teams is running. Remediation needed."
    exit 1
}
catch {
    # If the process is not found, an exception is thrown and caught here
    Write-Host "Microsoft Teams is not running. Remediation needed."
    exit 1
}
