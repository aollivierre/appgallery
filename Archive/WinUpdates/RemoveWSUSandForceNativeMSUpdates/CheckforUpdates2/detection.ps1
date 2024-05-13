#Requires -Version 3.0

# Generate a timestamp for the log file name
$timestampForFileName = Get-Date -Format "yyyyMMdd-HHmmss"
$logDirectory = "C:\Code\WinUpdates\logs\detection"
$logFilePath = Join-Path $logDirectory "_$timestampForFileName.log"

# Function to ensure log directory exists
function Ensure-LogDirectoryExists {
    param([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

# Function to append a message to the log file
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



# Function to ensure PSWindowsUpdate module is installed
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

# Function to detect pending updates

# Function to detect pending updates
function Detect-PendingUpdates {
    [CmdletBinding()]
    param()

    try {
        Ensure-PSWindowsUpdateModule

        Write-Logwithtimestamp "Checking for pending updates..." -MessageType Info
        $availableUpdates = Get-WindowsUpdate -MicrosoftUpdate -Verbose:$false -ErrorAction SilentlyContinue

        if ($availableUpdates.Count -gt 0) {
            Write-Logwithtimestamp "Pending updates found. Number of updates: $($availableUpdates.Count)" -MessageType Info
            foreach ($update in $availableUpdates) {
                $updateDetails = "Update Title: $($update.Title) - KB Article: $($update.KBArticleID)"
                Write-Logwithtimestamp $updateDetails -MessageType Info
            }
            return $true
        } else {
            Write-Logwithtimestamp "No pending updates." -MessageType Info
            return $false
        }
    } catch {
        Write-Error "An error occurred while checking for updates: $_"
        Write-Logwithtimestamp "An error occurred while checking for updates: $_" -MessageType Error
        return $false
    }
}

# Run the detection function
$result = Detect-PendingUpdates -Verbose
if ($result -eq $true) {
    Write-Host "Updates are pending. Remediation needed." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "No updates pending. No remediation needed." -ForegroundColor Green
    exit 0
}