# if((Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"|Get-ItemProperty|Where-Object{$_.DisplayName -match "Microsoft 365 Apps" })){ Write-Output "f";exit 0}else{exit 1}

# Define the path of the Detection file you are looking for
$filePath = "C:\Program Files\_MEM\Detect\M365apps\2308_16.0.16731.20234.txt"

# Check if the Detection file exists
$fileExists = Test-Path $filePath

# Check if 'Microsoft 365 Apps' is installed
$ms365AppsInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { $_.DisplayName -match "Microsoft 365 Apps" }

# Conditionally proceed based on the checks
if ($ms365AppsInstalled -and $fileExists) {
    Write-Output "Both Microsoft 365 Apps and the Detection file exist."
    exit 0
} else {
    # Write-Output "Neither Microsoft 365 Apps nor the Detection file exist."
    exit 1
}