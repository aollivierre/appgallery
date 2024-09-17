# # if((Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"|Get-ItemProperty|Where-Object{$_.DisplayName -match "Microsoft 365 Apps" })){ Write-Output "f";exit 0}else{exit 1}

# # Define the path of the Detection file you are looking for
# $filePath = "C:\Program Files\_MEM\Detect\M365apps\2308_16.0.16731.20234.txt"

# # Check if the Detection file exists
# $fileExists = Test-Path $filePath

# # Check if 'Microsoft 365 Apps' is installed
# $ms365AppsInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { $_.DisplayName -match "Microsoft 365 Apps" }

# # Conditionally proceed based on the checks
# if ($ms365AppsInstalled -and $fileExists) {
#     Write-Output "Both Microsoft 365 Apps and the Detection file exist."
#     exit 0
# } else {
#     # Write-Output "Neither Microsoft 365 Apps nor the Detection file exist."
#     exit 1
# }







# Parameters for validating Microsoft 365 Apps installation
$m365ValidationParams = @{
    SoftwareName         = "Microsoft 365 Apps"
    MinVersion           = [version]"16.0.18025.20030"  # Required minimum version
    MaxRetries           = 3
    DelayBetweenRetries  = 5
}

# Perform the validation
$m365ValidationResult = Validate-SoftwareInstallation @m365ValidationParams

# Check the results of the validation
if ($m365ValidationResult.IsInstalled) {
    Write-Host "Microsoft 365 Apps version $($m365ValidationResult.Version) is installed and validated." -ForegroundColor Green
} else {
    Write-Host "Microsoft 365 Apps are not installed or do not meet the minimum version requirement." -ForegroundColor Red
}