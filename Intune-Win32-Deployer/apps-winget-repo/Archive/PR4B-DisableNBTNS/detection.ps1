try {
    $regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
    $allDisabled = $true

    Get-ChildItem $regkey | ForEach-Object {
        $netbiosOption = Get-ItemProperty -Path "$regkey\$($_.pschildname)" -Name "NetbiosOptions" -ErrorAction SilentlyContinue
        if ($netbiosOption -eq $null -or $netbiosOption.NetbiosOptions -ne 2) {
            $allDisabled = $false
            break
        }
    }

    if ($allDisabled) {
        exit 0 # exit 0 = all good, no remediation needed
    } else {
        exit 1 # exit 1 = detected, remediation needed
    }
} catch {
    Write-Error $_
    exit 2 # exit 2 = some error occurred during execution
}