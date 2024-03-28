#Unique Tracking ID: 40b55e68-84ef-4105-bb22-255dd14e51f8, Timestamp: 2024-02-29 09:26:28
# .\teamsbootstrapper.exe -p -o "MSTeams-x64.msix"


$msixPath = Join-Path -Path $PSScriptRoot -ChildPath "MSTeams-x64.msix"
Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-p -o `"$msixPath`"" -Wait -WindowStyle Hidden
