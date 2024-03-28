function DetectRestoredSignatures {
    try {
        $signaturePath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"
        
        if (Test-Path $signaturePath) {
            $OneDriveFolder = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName
            
            if ($OneDriveFolder) {
                $OneDrivePath = Join-Path $OneDriveFolder "Documents\OutlookSignatures"
            }
            
            if ($OneDrivePath -and (Test-Path $OneDrivePath)) {
                $restoredFiles = Get-ChildItem -Path $signaturePath -Recurse -File
                if ($restoredFiles.Count -gt 0) {
                    Write-Output "Restored Outlook Signatures detected at $signaturePath."
                    exit 0
                } else {
                    # Write-Output "No restored files found at $signaturePath."
                    exit 1
                }
            } else {
                # Write-Output "Backup not found at $OneDrivePath."
                exit 1
            }
        } else {
            # Write-Output "Signatures folder not found at $signaturePath."
            exit 1
        }
    } catch {
        # Write-Output "Error encountered during DetectRestoredSignatures: $_"
        exit 1
    }
}

# Call the function
DetectRestoredSignatures
