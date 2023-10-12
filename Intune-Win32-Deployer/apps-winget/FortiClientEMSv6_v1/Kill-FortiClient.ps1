# Get all FortiClient.exe processes
$processes = Get-Process -Name "FortiClient" -ErrorAction SilentlyContinue

# Check if any FortiClient processes were found
if ($processes) {
    # Loop through each process and terminate it
    foreach ($process in $processes) {
        Write-Host "Stopping process $($process.Id)..."
        $process | Stop-Process -Force
    }
} else {
    Write-Host "No FortiClient processes found."
}
