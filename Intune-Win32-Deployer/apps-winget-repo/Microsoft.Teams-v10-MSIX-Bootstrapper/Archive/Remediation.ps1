function Write-Log {
    param (
        [string]$Message
    )
    Write-Host $Message
}

function Write-ErrorAndExit {
    param (
        [string]$Message
    )
    Write-Error $Message
    exit 1
}



function Invoke-WithMaxAttempts {
    param (
        [ScriptBlock]$Operation,
        [int]$MaxAttempts = 10
    )

    $attempt = 0
    $success = $false

    while ($attempt -lt $MaxAttempts -and -not $success) {
        try {
            # Invoke the operation script block
            . $Operation
            $success = $true
            Write-Log "Operation succeeded on attempt #$($attempt + 1)"
        } catch {
            Write-Log "Attempt #$($attempt + 1) failed. Error: $_"
            Start-Sleep -Seconds 2 # Wait before retrying
        }

        $attempt++
    }

    if (-not $success) {
        Write-Log "Operation failed after $MaxAttempts attempts."
        exit 1
    }
}


function KillTeamsProcesses {
    $teamsProcesses = Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue
    if ($teamsProcesses) {
        Write-Log "Attempting to kill Microsoft Teams processes."
        $teamsProcesses | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Log "No Microsoft Teams processes found."
        # Indicate success to prevent unnecessary retries
        return $true
    }
}


Invoke-WithMaxAttempts -Operation {
    KillTeamsProcesses
}