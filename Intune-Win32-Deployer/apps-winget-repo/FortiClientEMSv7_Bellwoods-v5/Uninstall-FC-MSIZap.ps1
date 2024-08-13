# [07-12 3:25 p.m.] Hicham Elmahfoudi
# ---------------------------------------------------------------------------
# -1- to run the MSIZAP.exe
# ---------------------------------------------------------------------------
#    MsiZap.exe tw! {ForticlientGUID}    // it will scrap everything related to Forticlient 
 
# NOTE : after the reboot you will still see the forticlient icon in the Taskbar tray ( still you will be able to install the VPN only Version And Overwrite everything ) 
# The New Version will take also the configuration left ( but to be safe we will still deploy the configuration from the XML File ( Wont do any harm if already there ) 
 
# Options :
# t     Removes all information for the specified product code
# w     Removes Windows Installer information for all users.
# ---------------------------------------------------------------------------\
# To get GUID for the Forticlient : Run the code in FIND GUID :
# ---------------------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Retrieve the IdentifyingNumber for software with "forti" in the name

$identifyingNumber = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*forti*" } | Select-Object -ExpandProperty IdentifyingNumber
 
 
# [07-12 3:26 p.m.] Hicham Elmahfoudi
# This following is the full Script that need to be Deployed On the GPO ( we still need to upload the MSIZAP.EXE to Sysvol Tho _) 
# \\ott.nova-networks.com\SYSVOL\ott.nova-networks.com\scripts\
 
# [07-12 3:26 p.m.] Hicham Elmahfoudi
# Version 3 12-07-2024

#Skip Digit Signature issue 

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
 
#Define the Current User in The Session 

$usr = Get-WmiObject Win32_Process -Filter "Name='explorer.exe'" | ForEach-Object { $_.GetOwner() } | Select-Object -Unique -Expand User
 
# Define the path to the SMB share and the file to be downloaded

#*****************************************************************

#*****************************************************************

$smbSharePath1 = "\\ott.nova-networks.com\SYSVOL\ott.nova-networks.com\scripts\postreboot.ps1" # this is not necessary anymore but as a precaution it is good to Configure the profile for endusers  

$smbSharePath2 = "\\ott.nova-networks.com\SYSVOL\ott.nova-networks.com\scripts\MsiZap.Exe"

$smbSharePath3 = "\\ott.nova-networks.com\SYSVOL\ott.nova-networks.com\scripts\FortiClient.msi" 

$smbSharePath4 = "\\ott.nova-networks.com\SYSVOL\ott.nova-networks.com\scripts\NOVA-VPN-Policy.xml"

# Define the destination path on the local machine

#*****************************************************************

#*****************************************************************

$destinationPath = "C:\Users\$usr\AppData\Local"

# Copy the files from the SMB share to the local destination

Write-Output "Copying files from SMB share to local path..."

# Copy each file and verify if it exists in the destination path

$file1 = Copy-Item -Path $smbSharePath1 -Destination $destinationPath -Force -PassThru

$file2 = Copy-Item -Path $smbSharePath2 -Destination $destinationPath -Force -PassThru

$file3 = Copy-Item -Path $smbSharePath3 -Destination $destinationPath -Force -PassThru

$file4 = Copy-Item -Path $smbSharePath4 -Destination $destinationPath -Force -PassThru

# Verify if all files were copied successfully

$allFilesCopied = $file1, $file2, $file3, $file4 | ForEach-Object { Test-Path $_.FullName }

if ($allFilesCopied -contains $false) {

    Write-Output "Not all files were copied successfully."

    exit 1  # Exit PowerShell script with error code 1

}
else {

    Write-Output "All files copied successfully."

}

 
# Define the path to the MSI file

$msiPath = "C:\Users\$usr\AppData\Local\FortiClient.msi"
 
# Define the path to the post-reboot script

$postRebootScriptPath = "C:\Users\$usr\AppData\Local\postreboot.ps1"
 
 
#*****************************************************************************

#********************Uninstall Forticlient / Scrapping it ********************

#*****************************************************************************

# Retrieve the IdentifyingNumber for software with "forti" in the name

$identifyingNumber = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*forti*" } | Select-Object -ExpandProperty IdentifyingNumber

# Execute MsiZap.Exe with the retrieved GUID &&  YOU CAN SPECIFY THE PATH FOR THE MSIZAP HERE AFTER DEPLOYED TO LOCAL COMPUTER OF ENDUSERS

if ($identifyingNumber) {

    Start-Process -FilePath "C:\Users\$usr\AppData\Local\MsiZap.Exe" -ArgumentList "TW! $identifyingNumber" -Verb RunAs -Wait

}
else {

    Write-Host "No matching software found."

}
 
 
#*****************************************************************************

#********************Install  Forticlient VPN Only  ********************

#*****************************************************************************

Write-Output "Installing MSI package..."

Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -NoNewWindow -Wait
 
 
#*****************************************************************************

#********************POST REBOOT PROFILE CONFIG TASK FOR  Forticlient  ********************

#*****************************************************************************
 
# Schedule post-reboot script to run after the computer restarts With Hight Run Level 

Write-Output "Scheduling post-reboot script..."

$taskName = "RunPostRebootScript"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $postRebootScriptPath "

$trigger = New-ScheduledTaskTrigger -AtLogOn

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal
 
# Reboot the computer

Write-Output "Rebooting the computer..."

Restart-Computer -Force