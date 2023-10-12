# Define the path of the Detection file you are looking for
$filePath = "C:\Program Files\_MEM\Detect\DSregcmd\debug_leave.txt"

# Check if the Detection file exists
$fileExists = Test-Path $filePath

# Conditionally proceed based on the checks
if ($fileExists) {
    Write-Output "Detection file exist and the machine did a dsregcmd /debug /leave"
    exit 0
} else {
    # Write-Output "Neither Microsoft 365 Apps nor the Detection file exist."
    exit 1
}