#Unique Tracking ID: df12a7ad-9937-4dcf-9133-e135501f9516, Timestamp: 2024-02-28 13:18:01
# .\teamsbootstrapper.exe -p -o "MSTeams-x64.msix"


$msixPath = Join-Path -Path $PSScriptRoot -ChildPath "MSTeams-x64.msix"
Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-p -o `"$msixPath`"" -Wait -WindowStyle Hidden
