$guid = [Guid]::NewGuid()
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

$uniqueValue = "$guid-$timestamp"

$uniqueValue