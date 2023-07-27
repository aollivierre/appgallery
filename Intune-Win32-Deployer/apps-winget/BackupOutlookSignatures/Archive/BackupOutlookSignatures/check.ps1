$file_extension = ".detectWin32BackupOutlookSignatures"

function DetectBackupOutlookSignaturesFiles {
    # Define the files to check
    $filesToCheck = @(
        "C:\Intune\Win32\BackupOutlookSignatures\detect$file_extension"
    )

    # Initialize the flag for detection
    $filesDetected = $false

    # Check if the files exist
    foreach ($file in $filesToCheck) {
        if (Test-Path $file) {
            $filesDetected = $true
            break
        }
    }

    # Return a message and exit code based on the detection results
    if ($filesDetected) {
        Write-Output "BackupOutlookSignatures file detected."
        exit 0
    } else {
        exit 1
    }
}

# Call the function
DetectBackupOutlookSignaturesFiles