#Unique Tracking ID: 3cf0029f-7513-41f8-9f31-49d30b26374c, Timestamp: 2024-03-20 11:20:47
function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath_1001
           
    )
    
    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }
    
    $csvData | Export-Csv -Path $CSVFilePath_1001 -Append -NoTypeInformation -Force
}
