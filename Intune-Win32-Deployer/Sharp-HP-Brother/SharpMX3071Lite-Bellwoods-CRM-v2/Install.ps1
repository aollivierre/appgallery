﻿$pName="SHARP CRM";$pIP="192.168.53.155";$dName="Sharp MX-3071 PCL6";$infPath=Join-Path -Path $PSScriptRoot -ChildPath "Driver\su2emenu.inf";$portName="IP_192.168.53.155";$drvExist=Get-PrinterDriver -Name $dName -EA SilentlyContinue;if(!$drvExist){pnputil /add-driver $infPath;Add-PrinterDriver -Name $dName};$portExist=Get-PrinterPort -Name $portName -EA SilentlyContinue;if(!$portExist){Add-PrinterPort -Name $portName -PrinterHostAddress $pIP};$prtExist=Get-Printer -Name $pName -EA SilentlyContinue;if(!$prtExist){Add-Printer -Name $pName -DriverName $dName -PortName $portName}else{Remove-Printer -Name $pName;Add-Printer -Name $pName -DriverName $dName -PortName $portName}