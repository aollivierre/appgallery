# $argList = '-accepteula -i -d -s C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1'
# Start-Process -FilePath ".\PsExec64.exe" -ArgumentList $argList

# .\PsExec64.exe -accepteula -i -d -s powershell.exe

$d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# $d\PsExec64.exe -accepteula -i -d -s C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass

$argList = "-accepteula -i -d -s C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass"
# $argList = "-accepteula -i -d -s C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass"


Start-Process -FilePath "$d\PsExec64.exe" -ArgumentList $argList -Wait


# Create a single argument string for ServiceUI.exe
# $serviceUIArgs = "-process:explorer.exe `"C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\Deploy-Application.exe -DeploymentType Uninstall`""

# Run ServiceUI.exe with the defined arguments
# Start-Process -FilePath "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\ServiceUI.exe" -ArgumentList $serviceUIArgs -Wait -WindowStyle Hidden




# C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\ServiceUI.exe -process:explorer.exe C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\Deploy-Application.exe -DeploymentType Uninstall


# C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\ServiceUI.exe -process:explorer.exe C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\Deploy-Application.exe

# $argList = '%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1'
# Start-Process -FilePath ".\ServiceUI.exe" -ArgumentList $argList -Wait -WindowStyle Hidden


# .\PsExec64.exe -accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -WindowStyle Hidden -NoProfile -Executionpolicy bypass -file C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\install.ps1


# Define the complex argument list as a single string
# $argList = '-accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -NoProfile -Executionpolicy bypass -file C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\install.ps1"'
# $argList = '-accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"'

# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# $argList = '-accepteula -i -d -s $d\ServiceUI.exe -process:explorer.exe "$d\Deploy-Application.exe"'


# Run PsExec64.exe with the defined arguments
# Start-Process -FilePath ".\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden





# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Using double quotes for variable expansion and backticks to escape inner double quotes
# $argList = "-accepteula -i -d -s `"$d\ServiceUI.exe`" -process:explorer.exe `"$d\Deploy-Application.exe -DeploymentType `"`"Uninstall`"`"`""

# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "$d\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden







# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Create an array of arguments
# $argList = @(
#     '-accepteula',
#     '-i',
#     '-d',
#     '-s',
#     "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\ServiceUI.exe",
#     '-process:explorer.exe',
#     "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\Deploy-Application.exe",
#     '-DeploymentType',
#     'Uninstall'
# )

# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FortiClientEMSv1\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden








# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Create a single argument string for ServiceUI.exe and Deploy-Application.exe
# $serviceUIArgs = """$d\Deploy-Application.exe"" -DeploymentType ""Uninstall"""

# # Create an argument list for PsExec64.exe
# $argList = "-accepteula -i -d -s -c `"$d\ServiceUI.exe`" $serviceUIArgs"


# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "$d\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden



# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Create a single argument string for ServiceUI.exe and Deploy-Application.exe
# $serviceUIArgs = """$d\Deploy-Application.exe"" -DeploymentType ""Uninstall"""

# # Create an argument list for PsExec64.exe
# $argList = "-accepteula -i -d -s -c `"$d\ServiceUI.exe`" $serviceUIArgs"

# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "$d\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden




# $d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# # Create a single argument string for ServiceUI.exe and Deploy-Application.exe
# $serviceUIArgs = "-process:explorer.exe `"$d\Deploy-Application.exe`" -DeploymentType `"`"Uninstall`"`""

# # Create an argument list for PsExec64.exe
# $argList = "-accepteula -i -d -s `"$d\ServiceUI.exe`" $serviceUIArgs"

# # Run PsExec64.exe with the defined arguments
# Start-Process -FilePath "$d\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden










