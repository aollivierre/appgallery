<#
.Synopsis
Created on:   31/12/2021
Created by:   Ben Whitmore
Filename:     Remove-Printer.ps1

powershell.exe -executionpolicy bypass -file .\Remove-Printer.ps1 -PrinterName "Canon Printer Upstairs"

.Example
.\Remove-Printer.ps1 -PrinterName "Canon Printer Upstairs"
#>

function Remove-PrinterByName {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String]$PrinterName
    )

    # (paste the entire script here, replacing the hard-coded parameter with the passed parameter)

Try {
    #Remove Printer
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExist) {
        Remove-Printer -Name $PrinterName -Confirm:$false
    }
}
Catch {
    Write-Warning "Error removing Printer"
    Write-Warning "$($_.Exception.Message)"
}


}

# Define your parameter
$PrinterName = "LHC - RICOH MP C3504ex PCL 6"

# Call the function with the defined parameter
Remove-PrinterByName -PrinterName $PrinterName
