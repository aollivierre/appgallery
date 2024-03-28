#Requires -Version 3.0

function Install-Updates {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param()

    # Generate a timestamp for the log file name
    $timestampForFileName = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFilePath = "C:\code\windowsupdates_$timestampForFileName.log"

    # Function to append a message to the log file
    function Write-Log {
        param([string]$Message)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFilePath -Value "[$timestamp] $Message"
    }

    try {
        Write-Log "Starting update installation process."

        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "Installing PSWindowsUpdate module..."
            Install-Module -Name PSWindowsUpdate -Verbose:$false -Confirm:$false
        }
        
        Write-Log "Importing PSWindowsUpdate module..."
        Import-Module -Name PSWindowsUpdate -Verbose:$false

        Write-Log "Checking for updates..."
        $availableUpdates = Get-WindowsUpdate -MicrosoftUpdate -Verbose:$false

        if ($availableUpdates.Count -gt 0) {
            Write-Log "Found $($availableUpdates.Count) updates. Installing..."
            Get-WindowsUpdate -MicrosoftUpdate -Install -Verbose:$false -Confirm:$false
            Write-Log "Updates installed successfully."
        } else {
            Write-Log "No updates available."
        }
    } catch {
        Write-Error "An error occurred while updating: $_"
        Write-Log "An error occurred: $_"
    }

    Write-Log "Update installation process completed."
}

# Run the function
Install-Updates -Verbose
