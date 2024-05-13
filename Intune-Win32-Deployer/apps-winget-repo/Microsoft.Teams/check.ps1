#Unique Tracking ID: 44d72517-317f-444c-a8ca-51c024882466, Timestamp: 2024-02-21 16:39:38
$ProgramName = "Microsoft.Teams"

# resolve winget_exe
$winget_exe = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe\winget.exe"
if ($winget_exe.count -gt 1){
        $winget_exe = $winget_exe[-1].Path
}

if (!$winget_exe){
    Write-Error "Winget not installed"
}else{
    $wingetPrg_Existing = & $winget_exe list --id $ProgramName --exact --accept-source-agreements
        if ($wingetPrg_Existing -like "*$ProgramName*"){
        Write-Host "Found it!"
    }
}
