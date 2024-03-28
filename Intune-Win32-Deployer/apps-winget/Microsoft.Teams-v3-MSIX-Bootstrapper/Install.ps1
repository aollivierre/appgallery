# .\teamsbootstrapper.exe -p -o "MSTeams-x64.msix"


$msixPath = Join-Path -Path $PSScriptRoot -ChildPath "MSTeams-x64.msix"
Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-p -o `"$msixPath`"" -Wait -WindowStyle Hidden
