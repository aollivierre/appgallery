#Unique Tracking ID: b198e008-7184-43d9-ab6d-7143432ca508, Timestamp: 2024-02-28 14:02:26
# Define the path to the executable
$exePath = "C:\Program Files\_MEM\Data\PR_PR4B-SetAdobeReaderPDFDefault\SetUserFTA.exe"

# Define the arguments
$arguments = ".pdf Acrobat.Document.DC"

# Run the executable with arguments
Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
