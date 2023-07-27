$printername = "LHC - RICOH MP C3504ex PCL 6"

$printerRegKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$printername"

function DetectPrinter {
    # Check if the printer registry key exists
    if (Test-Path $printerRegKeyPath) {
        # Get the "Name" registry value
        $printerRegValueName = "Name"
        $printerRegValueData = (Get-ItemProperty -Path $printerRegKeyPath -Name $printerRegValueName -ErrorAction SilentlyContinue).$printerRegValueName

        # Check if the registry value data matches the printer name
        if ($printerRegValueData -eq $printername) {
            Write-Output "Printer '$printername' detected."
            exit 0
        } else {
            # Write-Output "Printer '$printername' not detected."
            exit 1
        }
    } else {
        # Write-Output "Printer '$printername' not detected."
        exit 1
    }
}

# Call the function
DetectPrinter
