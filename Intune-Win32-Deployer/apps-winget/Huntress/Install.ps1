# Get the current script's directory
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

function Invoke-Huntress {
    try {
        # Reference Huntress.exe dynamically based on the script's directory
        $huntressPath = Join-Path -Path $scriptDir -ChildPath "Huntress.exe"

        # Run the Huntress command with the /S flag for a silent install
        & $huntressPath /S
    }
    catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
}

# Call the function
Invoke-Huntress
