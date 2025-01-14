$Certificate = @'
-----BEGIN CERTIFICATE-----
MIIDqTCCApGgAwIBAgIJAJXGlweg9NNUMA0GCSqGSIb3DQEBCwUAMGsxCzAJBgNV
BAYTAlVTMQswCQYDVQQIDAJDQTERMA8GA1UEBwwIU2FuIEpvc2UxFzAVBgNVBAoM
DlNvbmljV0FMTCBJbmMuMSMwIQYDVQQDDBpTb25pY1dBTEwgRmlyZXdhbGwgRFBJ
LVNTTDAeFw0xNjAxMTgwNzA0MDhaFw0yNjAxMTUwNzA0MDhaMGsxCzAJBgNVBAYT
AlVTMQswCQYDVQQIDAJDQTERMA8GA1UEBwwIU2FuIEpvc2UxFzAVBgNVBAoMDlNv
bmljV0FMTCBJbmMuMSMwIQYDVQQDDBpTb25pY1dBTEwgRmlyZXdhbGwgRFBJLVNT
TDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPKvBUoJEBMtyUc8kTyA
O70wlyGnDN9wTRMH4N5NLjONBXfRnidpcWbYkmxEzzXk97J36z9voNjd9n12gtrZ
fKDKqOyx00WOFekG+6A/X78UiGPP3S+enrFHrDEc489+Jujv6bZDNagbDr43CO1+
ociwyUsKd649yUrM5nRkBSPBvTF5P9reKvTy2FqeIyRRsk7G2mhSU0bcY1wuqUF/
WbT8Saq4zSTuf9T0Tgi7bnZtTUMvYOBPxlSyofjoFN67hJN5pLxSPFIF0T0bBz5t
+qI6vAA/r5vddORx9pVmtWc0Iy0kG25TrJ+eZ25Lk6AF/e4wkxGJBG4++3ujrmm2
ctkCAwEAAaNQME4wHQYDVR0OBBYEFJwPDSLy0xy/hwSRhtszlZaSGiyyMB8GA1Ud
IwQYMBaAFJwPDSLy0xy/hwSRhtszlZaSGiyyMAwGA1UdEwQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAMLHKTe+AR23P0sMbfbepaZnkBOcJNn+PM4zQDVnX+9OI8J0
FQCYUXhT9eNVoqNjZk+5iI9YHavJ3IFHYsIslbl7BSowx6wP1iRaTDDDQ0AMHShz
siMAuVlC/CtRLLdMXGwuxzm7zuYT4KpiLv1JKYU3swOqR/UEWVuWXuc49DALKl13
RoqsZG9PTLq8hg1QTrHCAXbnqSUhR/MS6QRSyjRRQsJrKaDArsyoHxBMKVdnBHar
vVFth+pEd0AYSvTRTpg6PLwjKC2hK+kJ5/kD4+YXvCScpWNRIvCUECLqy5hD6dh3
RdhoY3fGmUUN4jb5egO1DjgUrrMT45vYgLeKdr8=
-----END CERTIFICATE-----
'@
# $Store = 'TrustedPublisher'
# $Filename = (New-Guid).Guid
$Filename = "SonicWALL_Firewall_DPI-SSL"
# $Certificate | Out-File -FilePath "$env:TEMP\$Filename.cer"
$Certificate | Out-File -FilePath "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget\Bellwoods-SonicWALL-SSL-Cert\$Filename.cer"
# Import-Certificate -FilePath "$env:TEMP\$Filename.cer" -CertStoreLocation "Cert:\LocalMachine\$Store" | Out-Null
# Remove-Item -Path "$env:TEMP\$Filename.cer" -Force