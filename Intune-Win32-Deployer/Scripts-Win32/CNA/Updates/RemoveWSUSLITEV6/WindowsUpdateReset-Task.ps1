# Script content
$scriptContent = @'
# Define the registry paths
$rp1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$rp2 = "$rp1\AU"

# Check for missing or correct keys
$missingOrCorrectKeys = 'WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnabled' | ForEach-Object {
    $value = (Get-ItemProperty -Path $rp1 -ErrorAction SilentlyContinue).$_
    $value -eq $null
}

# Check for correct values in the registry
$correctValues = @{
    'UseWUServer' = 0
    'NoAutoUpdate' = 0
    'DisableWindowsUpdateAccess' = 0
} | ForEach-Object {
    if ($_.Key -eq 'DisableWindowsUpdateAccess') {
        $path = $rp1
    } else {
        $path = $rp2
    }
    $value = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).$_.Key
    $value -eq $_.Value -or $value -eq $null
}

# Check detection results and decide on action
if (($missingOrCorrectKeys + $correctValues) -notcontains $false) {
    Write-Output "f"
    exit 0
} else {
    # Run remediation script if the detection script determines it's needed

    'WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnabled' | ForEach-Object {
        Remove-ItemProperty -Path $rp1 -Name $_ 
    }

    @{
        'UseWUServer' = 0
        'NoAutoUpdate' = 0
        'DisableWindowsUpdateAccess' = 0
    }.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path $(if ($_.Key -eq 'DisableWindowsUpdateAccess') {$rp1} else {$rp2}) -Name $_.Key -Value $_.Value
    }
    
    Restart-Service wuauserv -Force
    exit 1
}
'@

# Check if C:\code exists and if not create it
if (-not (Test-Path "C:\taskscripts")) {
        New-Item -Path "C:\taskscripts" -ItemType Directory -Force
    }

# Save the script to a file on the root of the C drive
$scriptFilePath = "C:\taskscripts\WindowsUpdateReset.ps1"
$scriptContent | Out-File -Path $scriptFilePath -Force

# Scheduled task properties
$TaskName = "WindowsUpdateResetTask_03f5f774-7ea5-4163-a969-4994ba7b20c5_2023_08_16_11_27_29"
$TaskDescription = "Task to reset specific Windows Update registry settings and restart the update service."
$ScriptPath = $scriptFilePath

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $ScriptPath"
<<<<<<< Updated upstream:AppGallery/Intune-Win32-Deployer/Scripts-Win32/RemoveWSUSLITEV6/WindowsUpdateReset-Task.ps1
$Trigger = New-ScheduledTaskTrigger -AtLogon

#trigger the task every 5 minutes
# $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)


=======
# Create a trigger that starts at a specific time and then repeats every 5 minutes
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval ([TimeSpan]::FromMinutes(5))
>>>>>>> Stashed changes:AppGallery/Intune-Win32-Deployer/apps-winget/RemoveWSUSLITEV6/WindowsUpdateReset-Task.ps1
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description $TaskDescription

Register-ScheduledTask -TaskName $TaskName -InputObject $Task