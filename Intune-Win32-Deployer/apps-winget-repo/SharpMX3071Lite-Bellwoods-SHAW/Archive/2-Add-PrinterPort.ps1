<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines







Add-PrinterPort
As a reader of this post, my assumption is that you will be rolling out new Network Printers which means you need to create the Printer Port using the Add-PrinterPort cmdlet before running the Add-Printer cmdlet

The Add-Printer cmdlet requires both the DriverName and PortName parameters are passed. This means the Printer Port needs to exist or be created before printer installation is attempted

An example to add a new Printer Port would be:-

Add-PrinterPort -Name "IP_10.10.1.1" -PrinterHostAddress "10.1.1.1"
#>



Add-PrinterPort -Name "IP_10.0.0.47" -PrinterHostAddress "10.0.0.47"
printmanagement.msc