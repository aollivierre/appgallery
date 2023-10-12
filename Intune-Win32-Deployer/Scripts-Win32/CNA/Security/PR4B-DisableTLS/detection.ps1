try {
    $tlsKeys = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    )

    $nonCompliantKeys = @()

    foreach ($key in $tlsKeys) {
        if (Test-Path $key) {
            $disabledByDefault = Get-ItemPropertyValue -Path $key -Name "DisabledByDefault"
            $enabled = Get-ItemPropertyValue -Path $key -Name "Enabled"

            if ($disabledByDefault -ne 1 -or $enabled -ne 0) {
                $nonCompliantKeys += $key
                # Write-Host "$key is not correctly configured to disable TLS."
            }
        } else {
            $nonCompliantKeys += $key
            # Write-Host "$key does not exist."
        }
    }

    if ($nonCompliantKeys.Count -eq 0) {
        # Write-Host "TLS 1.0 and 1.1 are disabled. No remediation needed."
        exit 0
    } else {
        # Write-Host "TLS 1.0 and 1.1 are not fully disabled. Remediation needed."
        exit 1
    }
} catch {
    # Write-Error "An error occurred: $_"
    exit 2
}
