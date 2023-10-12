try {
    # Disable TLS 1.0 and 1.1 for Client and Server
    $tlsKeys = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    )
    
    foreach ($key in $tlsKeys) {
        # Create the registry key if it does not exist
        if (-not (Test-Path $key)) {
            New-Item -Path $key -Force
        }

        # Set registry values
        Set-ItemProperty -Path $key -Name "DisabledByDefault" -Value 1
        Set-ItemProperty -Path $key -Name "Enabled" -Value 0
    }
    
    Write-Host "TLS 1.0 and 1.1 have been disabled."
} catch {
    Write-Error "An error occurred: $_"
}