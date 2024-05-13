#Unique Tracking ID: cacd55af-e4ed-4f27-af39-d1643565b7a6, Timestamp: 2024-02-28 13:53:29
# Define the path to the executable
$exePath = "C:\Program Files\_MEM\Data\PR_PR4B-SetAdobeReaderPDFDefault\SetUserFTA.exe"

# Define the arguments
$arguments = ".pdf Acrobat.Document.DC"

# Run the executable with arguments
Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
