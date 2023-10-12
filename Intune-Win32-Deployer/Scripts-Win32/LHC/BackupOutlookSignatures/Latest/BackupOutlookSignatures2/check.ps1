function DetectBackupOutlookSignatures {
    try {
        $signaturePath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"
        
        if (Test-Path $signaturePath) {
            $OneDriveFolder = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName
            
            if ($OneDriveFolder) {
                $OneDrivePath = Join-Path $OneDriveFolder "Documents\OutlookSignatures"
            }
            $defaultPath = "$env:USERPROFILE\Documents\OutlookSignatures"
            
            if ($OneDrivePath) {
                $destinationPath = $OneDrivePath
            } else {
                $destinationPath = $defaultPath
            }
            
            if (Test-Path $destinationPath) {
                $backupFiles = Get-ChildItem -Path $destinationPath -Recurse -File
                if ($backupFiles.Count -gt 0) {
                    Write-Output "Backup Outlook Signatures detected at $destinationPath."
                    exit 0
                } else {
                    # Write-Output "No backup files found at $destinationPath."
                    exit 1
                }
            } else {
                # Write-Output "Backup destination path not found: $destinationPath."
                exit 1
            }
        } else {
            # Write-Output "Signatures folder not found at $signaturePath."
            exit 1
        }
    } catch {
        # Write-Output "Error encountered during DetectBackupOutlookSignatures: $_"
        exit 1
    }
}

# Call the function
DetectBackupOutlookSignatures







