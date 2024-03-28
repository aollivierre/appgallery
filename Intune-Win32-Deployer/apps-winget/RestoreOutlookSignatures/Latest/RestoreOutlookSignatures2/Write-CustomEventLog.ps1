$LogName = $null

# The error you're encountering is because the first eight characters of the log names are the same, even though you're using the date and time format. Windows event log names have an eight-character limitation for uniqueness, meaning that only the first eight characters are considered for uniqueness.

# To resolve this issue, you can change the log naming format to use a shorter prefix and place the date and time after the prefix. This will ensure the first eight characters are unique.

# Here's an updated version of your Write-CustomEventLog function with a shorter prefix for the log name and event source:





# function Write-CustomEventLog {
#     param (
#         [string]$LogName = (Get-Date -Format "HHmmss") + "_RestoreOutlookSignatures",
#         [string]$EventSource = (Get-Date -Format "HHmmss") + "_RestoreOutlookSignatures",
#         [int]$EventID = 1000,
#         [string]$EventMessage,
#         [string]$Level = 'INFO'
#     )

#     # Map the Level to the corresponding EntryType
#     switch ($Level) {
#         'DEBUG'   { $EntryType = 'Information' }
#         'INFO'    { $EntryType = 'Information' }
#         'WARNING' { $EntryType = 'Warning' }
#         'ERROR'   { $EntryType = 'Error' }
#         default   { $EntryType = 'Information' }
#     }

#     # Check if the event log exists, and if not, create it
#     if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
#         try {
#             New-EventLog -LogName $LogName -Source $EventSource
#             Start-Sleep 5
#         } catch [System.InvalidOperationException] {
#             Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
#         }
#     } elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
#         # Get the existing log name for the event source
#         $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName

#         # If the existing log name is different from the desired log name, unregister the source and register it with the correct log name
#         if ($existingLogName -ne $LogName) {
#             Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
#             try {
#                 New-EventLog -LogName $LogName -Source $EventSource
#             } catch [System.InvalidOperationException] {
#                 # If the source still exists in the system, wait for the registry to refresh and try again
#                 Start-Sleep -Seconds 1
#                 New-EventLog -LogName $LogName -Source $EventSource
#             }
#         }
#     }

#     # Write the event to the custom event log
#     try {
#         Write-EventLog -LogName $LogName -Source $EventSource -EventID $EventID -Message $EventMessage -EntryType $EntryType
#     } catch [System.InvalidOperationException] {
#         Write-Warning "Error writing to the event log. Make sure you run PowerShell as an Administrator."
#     }
# }






function Create-EventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )

    # Check if the event log exists, and if not, create it
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        try {
            New-EventLog -LogName $LogName -Source $EventSource
        } catch [System.InvalidOperationException] {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    } elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Get the existing log name for the event source
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName

        # If the existing log name is different from the desired log name, unregister the source and register it with the correct log name
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
            try {
                New-EventLog -LogName $LogName -Source $EventSource
            } catch [System.InvalidOperationException] {
                New-EventLog -LogName $LogName -Source $EventSource
            }
        }
    }
}

function Write-CustomEventLog {
    param (
        [string]$LogName,
        [string]$EventSource,
        [int]$EventID = 1000,
        [string]$EventMessage,
        [string]$Level = 'INFO'
    )

    # Map the Level to the corresponding EntryType
    switch ($Level) {
        'DEBUG'   { $EntryType = 'Information' }
        'INFO'    { $EntryType = 'Information' }
        'WARNING' { $EntryType = 'Warning' }
        'ERROR'   { $EntryType = 'Error' }
        default   { $EntryType = 'Information' }
    }

    # Write the event to the custom event log
    try {
        Write-EventLog -LogName $LogName -Source $EventSource -EventID $EventID -Message $EventMessage -EntryType $EntryType
    } catch [System.InvalidOperationException] {
        Write-Warning "Error writing to the event log. Make sure you run PowerShell as an Administrator."
    }
}

$LogName = (Get-Date -Format "HHmmss") + "_RestoreOutlookSignatures"
$EventSource = (Get-Date -Format "HHmmss") + "_RestoreOutlookSignatures"

# Call the Create-EventSourceAndLog function
Create-EventSourceAndLog -LogName $LogName -EventSource $EventSource

# Call the Write-CustomEventLog function with custom parameters and level
Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'














# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -EventMessage "Outlook Signature Restore started." -Level 'INFO'

# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'

# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -EventMessage "Outlook Signature Restore failed." -EventID 1002 -Level 'ERROR'

