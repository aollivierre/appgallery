#Unique Tracking ID: 3f448b0c-4ffa-4b91-88c9-fd4677851b49, Timestamp: 2024-03-07 15:38:08
# Define the path to the executable
$exePath = "C:\Program Files\_MEM\Data\PR_PR4B-SetAdobeReaderPDFDefault\SetUserFTA.exe"

# Define the arguments
$arguments = ".pdf Acrobat.Document.DC"

# Run the executable with arguments
Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
