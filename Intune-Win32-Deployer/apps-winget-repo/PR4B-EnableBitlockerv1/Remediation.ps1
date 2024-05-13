# Assuming the C: drive is the target
$mountPoint = "C:"
$encryptionMethod = "XtsAes128" # Based on your configuration for operating system drives

# Enforce drive encryption type on operating system drives: Full encryption
# Note: PowerShell's Enable-BitLocker does not directly specify full encryption vs. used space only, but full encryption is the default behavior

# Require additional authentication at startup: Require TPM
# This setting is implied when enabling BitLocker without specifying additional protectors like PIN or startup key

# Attempt to enable BitLocker with the specified configurations
try {
    Enable-BitLocker -MountPoint $mountPoint -EncryptionMethod $encryptionMethod -TpmProtector -UsedSpaceOnly:$false
    Write-Host "BitLocker enabled on $mountPoint with $encryptionMethod."
} catch {
    Write-Error "Failed to enable BitLocker on $mountPoint. Error: $_"
}