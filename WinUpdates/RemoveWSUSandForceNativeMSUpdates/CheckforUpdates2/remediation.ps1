#Requires -Version 3.0

# Generate a timestamp for the log file name
$timestampForFileName = Get-Date -Format "yyyyMMdd-HHmmss"
$logDirectory = "C:\Code\WinUpdates\logs"
$logFilePath = Join-Path $logDirectory "_$timestampForFileName.log"

# Function to ensure log directory exists
function Ensure-LogDirectoryExists {
    param([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

function Write-Logwithtimestamp {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$MessageType = "Info"
    )
    Ensure-LogDirectoryExists -Path $logDirectory
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFilePath -Value "[$timestamp] $Message"

    # Color-coding for console output
    switch ($MessageType) {
        "Info" {
            Write-Host "[$timestamp] $Message" -ForegroundColor Green
        }
        "Warning" {
            Write-Host "[$timestamp] $Message" -ForegroundColor Yellow
        }
        "Error" {
            Write-Host "[$timestamp] $Message" -ForegroundColor Red
        }
    }
}

function Ensure-PSWindowsUpdateModule {
    [CmdletBinding()]
    param()

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Logwithtimestamp "PSWindowsUpdate module not installed. Installing..." -MessageType Warning
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        Install-Module -Name PSWindowsUpdate -Verbose:$false -Confirm:$false -Scope AllUsers
    }

    Import-Module -Name PSWindowsUpdate -Verbose:$false
    Write-Logwithtimestamp "PSWindowsUpdate module is available." -MessageType Info
}

function Install-Updates {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param()

    # [Existing code for log file path and Ensure-LogDirectoryExists function]

    try {
        Write-Logwithtimestamp "Starting update installation process." -MessageType Info

        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Logwithtimestamp "Installing PSWindowsUpdate module..." -MessageType Warning
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Install-Module -Name PSWindowsUpdate -Verbose:$false -Confirm:$false -Scope AllUsers
        }
        
        Write-Logwithtimestamp "Importing PSWindowsUpdate module..." -MessageType Info
        Import-Module -Name PSWindowsUpdate -Verbose:$false

        Write-Logwithtimestamp "Checking for updates..." -MessageType Info
        $availableUpdates = Get-WindowsUpdate -MicrosoftUpdate -Verbose:$false

        if ($availableUpdates.Count -gt 0) {
            Write-Logwithtimestamp "Found $($availableUpdates.Count) updates. Installing..." -MessageType Info
            Get-WindowsUpdate -MicrosoftUpdate -Install -Verbose:$false -Confirm:$false
            Write-Logwithtimestamp "Updates installed successfully." -MessageType Info
        } else {
            Write-Logwithtimestamp "No updates available." -MessageType Info
        }
    } catch {
        Write-Error "An error occurred while updating: $_"
        Write-Logwithtimestamp "An error occurred: $_" -MessageType Error
    }

    Write-Logwithtimestamp "Update installation process completed." -MessageType Info
}


# Run the function
Install-Updates -Verbose

