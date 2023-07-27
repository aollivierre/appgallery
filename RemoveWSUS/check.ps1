$file_extension = ".detectWin32WSUSRemove"

function DetectRemoveWSUSFiles {
    # Define the files to check
    $filesToCheck = @(
        "C:\Intune\Win32\RemoveWSUS\detect$file_extension"
    )

    # Initialize the flag for detection
    $filesDetected = $false

    # Check if the files exist
    foreach ($file in $filesToCheck) {
        if (Test-Path $file) {
            # Write-Output "$file detected."
            $filesDetected = $true
        }
    }

    # Return a message and exit code based on the detection results
    if ($filesDetected) {
        Write-Output "RemoveWSUS files detected, exiting."
        # exit 0
    } 
    
    # else {
    #     # Write-Output "RemoveWSUS files not detected."
    #     exit 1
    # }
}

# Call the function
DetectRemoveWSUSFiles
