# Detect registry values
$rp1="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$rp2="$rp1\AU"

$missingOrCorrectKeys = 'WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnabled' | ForEach-Object {
    ($value = (Get-ItemProperty -Path $rp1 -ErrorAction SilentlyContinue).$_) -eq $null
}

$correctValues = @{
    'UseWUServer' = 0;
    'NoAutoUpdate' = 0;
    'DisableWindowsUpdateAccess' = 0
} | ForEach-Object {
    $path = if ($_.Key -eq 'DisableWindowsUpdateAccess') { $rp1 } else { $rp2 }
    ($value = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).$_.Key) -eq $_.Value -or $value -eq $null
}

# Detect the presence of the scheduled task
$taskName = "WindowsUpdateResetTask"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -eq $taskName }

# Validate and decide on the action
if (($missingOrCorrectKeys + $correctValues) -notcontains $false -and $taskExists) {
    Write-Output "f"
    exit 0
} else {
    exit 1
}