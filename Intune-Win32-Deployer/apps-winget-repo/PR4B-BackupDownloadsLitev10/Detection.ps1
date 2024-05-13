#Unique Tracking ID: 505c652b-4986-49e8-b0c6-96243b8ff939, Timestamp: 2024-02-24 21:07:37
# Attempt to find the OneDrive directory
$oneDriveDirectory = (Get-ChildItem "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName

# Check if the OneDrive directory exists
if (-not $oneDriveDirectory) {
    Write-Host "OneDrive directory does not exist. Remediation is not possible for now."
    exit 0
}

# Define the backup path within the OneDrive directory
$backupPath = Join-Path $oneDriveDirectory "DownloadsBackup"

# Check if the DownloadsBackup folder exists and contains files
if (Test-Path $backupPath) {
    $fileCount = (Get-ChildItem -Path $backupPath -Recurse -File).Count
    if ($fileCount -gt 0) {
        Write-Host "DownloadsBackup folder detected with files at $backupPath. Remediation needed."
        exit 1
    } else {
        Write-Host "DownloadsBackup folder exists at $backupPath but is empty. Remediation needed."
        exit 1
    }
} else {
    Write-Host "DownloadsBackup folder does not exist at $backupPath. Remediation needed."
    exit 1
}
