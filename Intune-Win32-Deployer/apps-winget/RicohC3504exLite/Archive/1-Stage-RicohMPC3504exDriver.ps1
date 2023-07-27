<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.


This function checks if the specified INF file exists, and if it does, it stages the Ricoh RICOH MP C3504ex PCL 6 print driver using the pnputil.exe tool. If the INF file is not found, it displays an error message.

.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines



Staging Ricoh RICOH MP C3504ex PCL 6 driver...
Microsoft PnP Utility  Adding driver package:  oemsetup.inf Driver package added successfully. Published Name:         oem8.inf  Total driver packages:  1 Added driver packages:  1
Driver staging complete.
#>



function Stage-RicohMPC3504exDriver {
    $InfFilePath = "C:\temp\z97499L16\disk1\oemsetup.inf"
    
    if (Test-Path $InfFilePath) {
        Write-Host "Staging Ricoh RICOH MP C3504ex PCL 6 driver..."
        $result = & pnputil.exe /add-driver $InfFilePath
        Write-Host $result
        Write-Host "Driver staging complete."
    }
    else {
        Write-Host "Error: INF file not found at the specified location."
    }
}

# Call the function to stage the driver
Stage-RicohMPC3504exDriver
