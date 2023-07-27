$archiveFolderPath = "C:\Intune\Win32\cylr"
$minimumFileSize = 1MB

function DetectCyLR {
    # Get all files containing 'cylr_archive.zip' in their name
    $archiveFiles = Get-ChildItem -Path $archiveFolderPath -Filter "*cylr_archive.zip*"

    # Loop through each file and check if its size is greater than 1 MB
    $largeFiles = $archiveFiles | Where-Object { $_.Length -gt $minimumFileSize }

    # If any matching files with a size greater than 1 MB are found, print a message and exit with a success code
    if ($largeFiles.Count -gt 0) {
        Write-Output "Found $($largeFiles.Count) CyLR archive file(s) larger than 1 MB in the folder $archiveFolderPath"
        exit 0
    } else {
        # Write-Output "No CyLR archive files larger than 1 MB were found in the folder $archiveFolderPath"
        exit 1
    }
}

# Call the function
DetectCyLR
