function Remove-RestoredOutlookSignatureLogs {
    # Get all logs containing '_RestoreOutlookSignatures' in their name
    $logsToRemove = Get-WinEvent -ListLog * | Where-Object { $_.LogName -match "_RestoreOutlookSignatures" }

    # Remove each log
    foreach ($log in $logsToRemove) {
        try {
            Remove-EventLog -LogName $log.LogName
            Write-Host "Removed log: $($log.LogName)"
        } catch {
            Write-Warning "Error removing log: $($log.LogName). Make sure you run PowerShell as an Administrator."
        }
    }
}

# Call the Remove-RestoredOutlookSignatureLogs function to delete the logs
Remove-RestoredOutlookSignatureLogs
