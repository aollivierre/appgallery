# Get the directory where the script is located
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Resolve paths for MSI and settings files
$msiPath = Join-Path -Path $scriptPath -ChildPath "TV.msi"
$settingsFilePath = Join-Path -Path $scriptPath -ChildPath "s.tvopt"

# Verify files exist
if (-not (Test-Path $msiPath)) {
    Write-Error "TeamViewer MSI file not found at: $msiPath"
    exit 1
}

if (-not (Test-Path $settingsFilePath)) {
    Write-Error "TeamViewer settings file not found at: $settingsFilePath"
    exit 1
}

# Install TeamViewer
Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "/i", $msiPath, "/qn", "CUSTOMCONFIGID=he26pyq", "SETTINGSFILE=$settingsFilePath" -Wait
Start-Sleep -Seconds 30

# Possible TeamViewer installation paths
$teamViewerPaths = @(
    "C:\Program Files\TeamViewer\TeamViewer.exe",
    "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
)

# Find the actual TeamViewer path
$teamViewerExe = $null
foreach ($path in $teamViewerPaths) {
    if (Test-Path $path) {
        $teamViewerExe = $path
        break
    }
}

if ($teamViewerExe) {
    Start-Process -FilePath $teamViewerExe -ArgumentList "assignment", "--id", "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY"
} else {
    Write-Error "TeamViewer executable not found in any of the expected locations"
    exit 1
}