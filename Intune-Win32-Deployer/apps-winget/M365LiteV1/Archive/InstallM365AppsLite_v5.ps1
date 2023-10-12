$SetupFolder = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

Start-BitsTransfer -Source "https://officecdn.microsoft.com/pr/wsus/setup.exe" -Destination "$SetupFolder\setup.exe"

Start-BitsTransfer -Source 'https://deploymentconfigstorage.blob.core.windows.net/deploymentconfig/9bf01198-4a80-42b2-b334-5587c6861658/0334c2b5-4d23-4dc9-9264-c42b7c68d160.xml?sv=2018-11-09&sr=b&sig=IuToeiHMiBrEnbM7GUcdrrjJerELWuvBWTfv3sU5S00%3D&st=2023-05-16T22%3A40%3A11Z&se=2025-05-15T22%3A45%3A11Z&sp=r' -Destination "$SetupFolder\configuration.xml"

Start-Process "$SetupFolder\setup.exe" -ArgumentList "/configure $SetupFolder\configuration.xml" -Wait -PassThru