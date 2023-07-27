function DetectESETFiles {
    # Define the files to check
    $filesToCheck = @(
        "C:\Program Files\ESET\RemoteAdministrator\Agent\ERAAgent.exe",
        "C:\Program Files\ESET\ESET Security\ekrn.exe"
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
        Write-Output "ESET files detected, exiting."
        # exit 0
    } 
    
    # else {
    #     # Write-Output "ESET files not detected."
    #     exit 1
    # }
}

# Call the function
DetectESETFiles
