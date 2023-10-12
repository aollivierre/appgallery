$taskName = "WindowsUpdateResetTask_03f5f774-7ea5-4163-a969-4994ba7b20c5_2023_08_16_11_27_29"

# Check for the presence of the scheduled task
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -eq $taskName }

# Decide on the action based on the task's presence
if ($taskExists) {
    Write-Output "f"
    exit 0
} else {
    exit 1
}