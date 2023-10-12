try {
    $regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
    Get-ChildItem $regkey | ForEach-Object { 
        Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 0 -Verbose
    }
} catch {
    Write-Error $_
}