# Get all running processes
$processes = Get-WmiObject Win32_Process

# Loop through each process to find those with "FortiClient" in their description
foreach ($process in $processes) {
    # Get the process description
    $description = $process.Description

    # Check if the description contains "FortiClient"
    if ($description -match "FortiClient") {
        Write-Host "Stopping process $($process.ProcessId) with description $description..."
        
        # Terminate the process
        Stop-Process -Id $process.ProcessId -Force
    }
}
