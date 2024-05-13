function Export-TrustedPublisherCerts {
    param(
        [string]$ExportDirName = "certs"
    )

    $ExportPath = Join-Path -Path $PSScriptRoot -ChildPath $ExportDirName

    # Check if the export directory exists, if not, create it
    if (-not (Test-Path -Path $ExportPath)) {
        New-Item -ItemType Directory -Path $ExportPath | Out-Null
    }

    try {
        # Get all certificates from the Trusted Publisher store
        $certs = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher

        foreach ($cert in $certs) {
            # Define export file path for each certificate
            $certExportPath = Join-Path -Path $ExportPath -ChildPath "$($cert.Thumbprint).cer"

            # Export the certificate
            [byte[]]$certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            [System.IO.File]::WriteAllBytes($certExportPath, $certBytes)

            Write-Host "Certificate with thumbprint $($cert.Thumbprint) exported successfully to '$certExportPath'"
        }

        if ($certs.Count -eq 0) {
            Write-Host "No certificates found in the Trusted Publisher store."
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage:
Export-TrustedPublisherCerts
