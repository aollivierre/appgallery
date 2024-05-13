<#
.SYNOPSIS
    Backs up specific Google Chrome data files to a designated backup location within OneDrive.

.DESCRIPTION
    This script backs up specific files ('bookmarks' and 'Login Data') from the Google Chrome Default user profile to a specified backup directory in OneDrive. It checks for the existence of the source files and OneDrive directory before proceeding.

.EXAMPLE
    .\Backup-ChromeSpecificFiles.ps1
    Executes the backup operation, copying the specified Chrome data files to the backup location in OneDrive.

.NOTES
    Version: 1.0
    Author: Your Name
    Requires: PowerShell 5.1 or later
    Unique Tracking ID: 239f65ce-a4fe-4b0d-82ce-8295ad160753
#>

# Set the user profile path explicitly if different users or paths will use this script.
$userProfilePath = $env:USERPROFILE

# Files to back up
$filesToBackup = @("bookmarks", "Login Data")

# Source path to Chrome's Default profile
$chromeDefaultProfilePath = Join-Path -Path $userProfilePath -ChildPath "AppData\Local\Google\Chrome\User Data\Default"

# Find the OneDrive directory with the specified filter
$oneDriveBackupPath = Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory | Select-Object -First 1 -ExpandProperty FullName

# Destination path for the backup inside OneDrive
$backupDestinationPath = Join-Path -Path $oneDriveBackupPath -ChildPath "ChromeBackup"

# Check and create backup directory if it doesn't exist
if (-not (Test-Path -Path $backupDestinationPath)) {
    New-Item -ItemType Directory -Path $backupDestinationPath | Out-Null
}

foreach ($file in $filesToBackup) {
    $sourceFilePath = Join-Path -Path $chromeDefaultProfilePath -ChildPath $file

    if (Test-Path -Path $sourceFilePath) {
        try {
            $destinationFilePath = Join-Path -Path $backupDestinationPath -ChildPath $file
            Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force
            Write-Host "Successfully backed up '$file' to '$destinationFilePath'."
        }
        catch {
            Write-Error "An error occurred while backing up '$file': $_"
        }
    }
    else {
        Write-Warning "'$sourceFilePath' does not exist and will not be backed up."
    }
}
