# Define the path of the Detection file you are looking for
$filePath = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

# Check if the Detection file exists
$fileExists = Test-Path $filePath


# Conditionally proceed based on the checks
if ($fileExists) {
    Write-Output "FortiClient is installed"
    exit 0
} else {
    # Write-Output "FortiClient is not installed"
    exit 1
}