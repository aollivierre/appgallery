To detect and remediate NTLMv1 by creating or modifying a DWORD parameter named LmCompatibilityLevel, you can use PowerShell scripts. Please note that modifying the system registry can have unintended consequences, so always take appropriate backups and test changes in a controlled environment before deploying them in production. Below are the scripts:

Detection Script
This script will check if LmCompatibilityLevel is set to 5 under the registry key HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa.



Remediation Script
This script will set LmCompatibilityLevel to 5, effectively disabling NTLMv1.