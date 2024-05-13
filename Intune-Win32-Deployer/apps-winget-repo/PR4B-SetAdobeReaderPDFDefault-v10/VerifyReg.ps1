#Unique Tracking ID: cacd55af-e4ed-4f27-af39-d1643565b7a6, Timestamp: 2024-02-28 13:53:29
# Get the ProgID for the default PDF handler
$defaultProgId = Get-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\.pdf | Select-Object -ExpandProperty '(Default)'

# Output the default handler for PDF files
Write-Host "Default Program ID for PDF: $defaultProgId"

# Check if the ProgID exists in the registry
if (Test-Path "Registry::HKEY_CLASSES_ROOT\$defaultProgId") {
    # Navigate to the command used by the default PDF handler
    $commandPath = "Registry::HKEY_CLASSES_ROOT\$defaultProgId\shell\open\command"
    
    # Check if the command path exists
    if (Test-Path $commandPath) {
        # Retrieve the default command used to open PDFs
        $defaultCommand = Get-ItemProperty -Path $commandPath | Select-Object -ExpandProperty '(Default)'
        
        # Output the command used to open PDF files
        Write-Host "Command used to open PDF files: $defaultCommand"
    } else {
        Write-Host "Command path for '$defaultProgId' does not exist."
    }
} else {
    Write-Host "Program ID '$defaultProgId' does not exist in the registry."
}
