try {
    $keyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $parameterName = "LmCompatibilityLevel"
    $parameterValue = 5

    # Create the registry key if it does not exist
    if (-not (Test-Path $keyPath)) {
        New-Item -Path $keyPath -Force
    }

    # Set the registry value to disable NTLMv1
    Set-ItemProperty -Path $keyPath -Name $parameterName -Value $parameterValue

    Write-Host "NTLMv1 has been disabled."
} catch {
    Write-Error "An error occurred: $_"
}