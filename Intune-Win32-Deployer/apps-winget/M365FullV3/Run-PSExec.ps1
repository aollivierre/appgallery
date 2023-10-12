# $argList = '-accepteula -i -d -s C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1'
# Start-Process -FilePath ".\PsExec64.exe" -ArgumentList $argList

# .\PsExec64.exe -accepteula -i -d -s powershell.exe
# .\PsExec64.exe -accepteula -i -d -s C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass


# $argList = '%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1'
# Start-Process -FilePath ".\ServiceUI.exe" -ArgumentList $argList -Wait -WindowStyle Hidden


# .\PsExec64.exe -accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -WindowStyle Hidden -NoProfile -Executionpolicy bypass -file C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\install.ps1


# Define the complex argument list as a single string
# $argList = '-accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -NoProfile -Executionpolicy bypass -file C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\install.ps1"'
# $argList = '-accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"'
$argList = '-accepteula -i -d -s C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\ServiceUI.exe -process:explorer.exe "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\M365FullV3\Deploy-Application.exe"'

# Run PsExec64.exe with the defined arguments
Start-Process -FilePath ".\PsExec64.exe" -ArgumentList $argList -Wait -WindowStyle Hidden
