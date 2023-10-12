try {
    # Define the registry key for NetBIOS settings
    $regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
    
    # Initialize a list to track non-compliant interfaces
    $nonCompliantInterfaces = @()

    # Output a message to indicate the start of the check
    Write-Host "Starting NetBIOS status check..."

    # Loop through each network interface in the registry
    Get-ChildItem $regkey | ForEach-Object {
        # Attempt to retrieve the NetbiosOptions value for the current interface
        $netbiosOption = Get-ItemProperty -Path "$regkey\$($_.pschildname)" -Name "NetbiosOptions" -ErrorAction SilentlyContinue
        
        # Check if the retrieved value is either null or not equal to 2
        if ($netbiosOption -eq $null -or $netbiosOption.NetbiosOptions -ne 2) {
            # Write-Host "NetBIOS is not disabled on interface: $($_.pschildname)"
            $nonCompliantInterfaces += $_.pschildname
        }
    }

    # Provide a summary based on the check
    if ($nonCompliantInterfaces.Count -eq 0) {
        # Write-Host "NetBIOS is disabled on all network interfaces. No remediation needed."
        exit 0 # exit 0 = all good, no remediation needed
    } else {
        # Write-Host "NetBIOS is not disabled on some network interfaces. Remediation needed."
        exit 1 # exit 1 = detected, remediation needed
    }
} catch {
    # Output an error message if something goes wrong
    # Write-Error "An error occurred during the NetBIOS status check: $_"
    # exit 2 # exit 2 = some error occurred during execution
}