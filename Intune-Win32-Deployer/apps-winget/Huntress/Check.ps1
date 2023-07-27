$huntressAgentPath = "C:\Program Files\Huntress\HuntressAgent.exe"

function DetectHuntress {
    # Check if the Huntress Agent executable exists at the specified path
    $huntressAgent = Test-Path $huntressAgentPath

    # If the Huntress Agent executable is found, print a message and exit with a success code
    if ($huntressAgent) {
        Write-Output "Huntress Agent found at $huntressAgentPath"
        exit 0
    } else {
        # Write-Output "Huntress Agent not found at $huntressAgentPath"
        exit 1
    }
}

# Call the function
DetectHuntress
