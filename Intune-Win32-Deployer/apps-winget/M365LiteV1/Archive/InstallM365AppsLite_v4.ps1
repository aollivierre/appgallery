$XMLUrl = 'https://deploymentconfigstorage.blob.core.windows.net/deploymentconfig/9bf01198-4a80-42b2-b334-5587c6861658/0334c2b5-4d23-4dc9-9264-c42b7c68d160.xml?sv=2018-11-09&sr=b&sig=IuToeiHMiBrEnbM7GUcdrrjJerELWuvBWTfv3sU5S00%3D&st=2023-05-16T22%3A40%3A11Z&se=2025-05-15T22%3A45%3A11Z&sp=r'
$SetupFolder = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

#Download latest Office (ODT) setup.exe
$SetupEverGreenURL = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
Start-BitsTransfer -Source $SetupEverGreenURL -Destination "$SetupFolder\setup.exe"

#Start install preparations
$SetupFilePath = Join-Path -Path $SetupFolder -ChildPath "setup.exe"

#Prepare Office Installation
[System.Diagnostics.FileVersionInfo]::GetVersionInfo("$($SetupFolder)\setup.exe").FileVersion 

#Attempt to download file from External Source
Start-BitsTransfer -Source $XMLURL -Destination "$SetupFolder\configuration.xml"

#Starting Office setup with configuration file               
Start-Process $SetupFilePath -ArgumentList "/configure $($SetupFolder)\configuration.xml" -Wait -PassThru