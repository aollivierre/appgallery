try {
    $keyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $parameterName = "LmCompatibilityLevel"

    if (Test-Path $keyPath) {
        $currentValue = Get-ItemPropertyValue -Path $keyPath -Name $parameterName -ErrorAction SilentlyContinue

        if ($currentValue -eq 5) {
            Write-Host "NTLMv1 is already disabled. No remediation needed."
            exit 0
        } else {
            Write-Host "NTLMv1 is not disabled. Remediation needed."
            exit 1
        }
    } else {
        Write-Host "Registry key does not exist. Remediation needed."
        exit 1
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 2
}