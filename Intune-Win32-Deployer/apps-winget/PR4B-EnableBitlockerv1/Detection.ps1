

# Check BitLocker status on the system drive
$bitLockerStatus = Get-BitLockerVolume -MountPoint "C:"

# Determine if BitLocker is enabled based on the ProtectionStatus property
# ProtectionStatus -eq 1 means BitLocker is enabled; -eq 0 means BitLocker is not enabled.
if ($bitLockerStatus.ProtectionStatus -eq 1) {
    Write-Host "BitLocker is enabled on the system drive."
    exit 0
} else {
    # BitLocker is not enabled on the system drive.
    # Note: No Write-Host or Write-Output here as per the requirement to only comment.
    # Uncomment the line below if you want to log this condition silently (to a file or logging mechanism).
    # Write-Output "BitLocker is not enabled on the system drive."
    exit 1
}
