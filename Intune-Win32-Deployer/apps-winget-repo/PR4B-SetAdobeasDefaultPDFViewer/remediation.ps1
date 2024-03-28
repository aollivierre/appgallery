# Define the path to the executable
$exePath = "C:\Program Files\_MEM\Data\PR_PR4B-SetAdobeReaderPDFDefault\SetUserFTA.exe"

# Define the arguments
$arguments = ".pdf Acrobat.Document.DC"

# Run the executable with arguments
Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait