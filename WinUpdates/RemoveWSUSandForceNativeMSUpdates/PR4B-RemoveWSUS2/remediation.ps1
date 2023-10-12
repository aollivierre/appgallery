try {
    $rp1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $rp2 = "$rp1\AU"

    # Remove problematic keys
    'WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnabled' | ForEach-Object {
        Remove-ItemProperty -Path $rp1 -Name $_ -ErrorAction SilentlyContinue
    }

    # Set the correct values
    @{
        'UseWUServer' = 0
        'NoAutoUpdate' = 0
        'DisableWindowsUpdateAccess' = 0
    }.GetEnumerator() | ForEach-Object {
        $path = if ($_.Key -eq 'DisableWindowsUpdateAccess') {$rp1} else {$rp2}
        Set-ItemProperty -Path $path -Name $_.Key -Value $_.Value
    }

    # Restart the Windows Update service
    Restart-Service wuauserv -Force
    Write-Host "Remediation completed successfully."
    # exit 0
} catch {
    Write-Error "An error occurred during remediation: $_"
    # exit 2
}
