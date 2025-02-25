﻿function DetectDUOFiles {
    # Define the files to check
    $filesToCheck = @(
        "C:\Program Files\Duo Security\WindowsLogon\DuoCredFilter.dll",
        "C:\Program Files\Duo Security\WindowsLogon\DuoCredProv.dll",
        "C:\Program Files\Duo Security\WindowsLogon\Winlogon-Diag.ps1",
        "C:\ProgramData\Duo Security\duo.log"
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
        # Write-Output "ESET files detected, exiting."
        Write-Output "DUO files detected, exiting."
        exit 0
    } 
    
    else {
        # Write-Output "DUO files not detected."
        exit 1
    }
}

# Call the function
DetectDUOFiles
