function Split-FileIntoChunks {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFilePath,

        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeInMB = 55
    )

    $chunkSize = $ChunkSizeInMB * 1024 * 1024
    $fileInfo = Get-Item $InputFilePath
    $outputDirectory = $fileInfo.DirectoryName
    $fileBaseName = $fileInfo.BaseName
    $fileExtension = $fileInfo.Extension
    $totalChunks = [math]::Ceiling($fileInfo.Length / $chunkSize)
    $buffer = New-Object byte[] $chunkSize

    try {
        $fileStream = [System.IO.File]::OpenRead($InputFilePath)

        for ($i = 0; $i -lt $totalChunks; $i++) {
            $bytesRead = $fileStream.Read($buffer, 0, $chunkSize)
            $outputFilePath = "{0}\{1}_part{2:D4}{3}" -f $outputDirectory, $fileBaseName, ($i + 1), $fileExtension
            [System.IO.File]::WriteAllBytes($outputFilePath, $buffer[0..($bytesRead - 1)])
            Write-Output "Created chunk: $outputFilePath"
        }
    }
    finally {
        if ($null -ne $fileStream) {
            $fileStream.Dispose()
        }
    }
}

# Example usage:
# $largeFilePath = "C:\path\to\your\large_file.zip"
$largeFilePath = "C:\Intune\Win32\cylr\cylr_archive.zip"
Split-FileIntoChunks -InputFilePath $largeFilePath
