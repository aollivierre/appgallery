# Check if Adobe Acrobat/Reader is set as the default PDF viewer, considering UserChoice overrides
try {
    $userChoicePath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice"
    $userChoice = Get-ItemProperty -Path $userChoicePath -Name ProgId -ErrorAction Stop | Select-Object -ExpandProperty ProgId

    if ($userChoice -like '*Acrobat.Document*' -or $userChoice -like '*AcroExch.Document*') {
        Write-Host "Adobe Acrobat or Adobe Reader is set as the default PDF viewer."
        exit 1 # Exit code 0 for success
    } elseif ($userChoice -like '*Edge*') {
        Write-Host "Microsoft Edge is set as the default PDF viewer."
        exit 1 # Exit code 1 for Edge being the default
    } else {
        Write-Host "Another program is set as the default PDF viewer."
        exit 1 # Exit code 1 for another program being the default
    }
} catch {
    Write-Host "Unable to determine the default PDF viewer. Please check file associations manually."
    exit 2 # Exit code 2 for error
}