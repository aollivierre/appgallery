PowerShell Scripts for Windows Update Registry Settings
This repository contains two PowerShell scripts designed to manage specific Windows Update settings in the Windows Registry.

Overview
Detection Script: Checks for the presence and values of specific registry keys related to Windows Update settings.
Remediation Script: Adjusts or removes specific registry keys to meet desired Windows Update settings.
Prerequisites
Windows PowerShell
Administrative privileges to read/write the registry and restart services.
Usage
Detection Script
Run this script to check the current state of registry settings related to Windows Update. This script will either indicate that all settings are correct or that remediation is required.

How to Run
Open PowerShell as an administrator.
Navigate to the directory containing the Detection.ps1 script.
Run the script:
powershell
Copy code
.\Detection.ps1
Exit Codes
0: All registry keys and values are set correctly. No remediation needed.
1: Registry keys and/or values are incorrect. Remediation needed.
2: An error occurred during the operation.


Remediation Script
Run this script to remediate the registry settings if the Detection Script has indicated that it is required (Exit code 1).

How to Run
Open PowerShell as an administrator.
Navigate to the directory containing the Remediation.ps1 script.
Run the script:
powershell
Copy code
.\Remediation.ps1
Exit Codes
0: Remediation completed successfully.
2: An error occurred during the remediation process.
Scripts Explained
Detection Script
The Detection script verifies the following:

The absence of these keys under HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate: WUServer, TargetGroup, WUStatusServer, TargetGroupEnabled.
The correct setting of these keys under HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU: UseWUServer, NoAutoUpdate.
The correct setting of DisableWindowsUpdateAccess under HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate.
Remediation Script
The Remediation script performs the following actions:

Removes the keys: WUServer, TargetGroup, WUStatusServer, TargetGroupEnabled from HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate.
Sets UseWUServer and NoAutoUpdate in HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU to 0.
Sets DisableWindowsUpdateAccess in HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate to 0.
Restarts the Windows Update service (wuauserv).
License
This project is licensed under the MIT License. See the LICENSE file for details.

Feel free to adjust as needed for your specific use-case or to fit the style of your GitHub repository.