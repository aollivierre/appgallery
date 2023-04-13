$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
function Uninstall-DeployApplication {
        param (
            [string]$ProgramName = "ESET.EndpointAntivirus",
            [string]$Path_local = "$Env:Programfiles\_MEM"
        )
    
        # Define colors for logging
        $infoColor = 'Green'
        $errorColor = 'Red'
    
        # Check if Deploy-Application.exe exists
        
        $deployApplicationPath = Join-Path -Path $scriptPath -ChildPath "Deploy-Application.exe"
    
        if (-not (Test-Path -Path $deployApplicationPath)) {
            Write-Host "Error: Deploy-Application.exe not found at $deployApplicationPath" -ForegroundColor $errorColor
            return
        }
    
        # Create log directory if it doesn't exist
        $logDir = Join-Path -Path $Path_local -ChildPath "Log"
        if (-not (Test-Path -Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir | Out-Null
        }
    
        # Start transcript
        $logFile = Join-Path -Path $logDir -ChildPath "$ProgramName-uninstall.log"
        Start-Transcript -Path $logFile -Force -Append
    
        # Log start time
        $startTime = Get-Date
        Write-Host "[$startTime] Starting Deploy-Application.exe with -DeploymentType 'Uninstall'" -ForegroundColor $infoColor
    
        # Execute Deploy-Application.exe with -DeploymentType "Uninstall"
        try {
            & $deployApplicationPath -DeploymentType "Uninstall"
        }
        catch {
            $endTime = Get-Date
            Write-Host "[$endTime] Error executing Deploy-Application.exe with -DeploymentType 'Uninstall': $_" -ForegroundColor $errorColor
            Stop-Transcript
            return
        }
    
        # Log end time
        $endTime = Get-Date
        Write-Host "[$endTime] Finished Deploy-Application.exe with -DeploymentType 'Uninstall'" -ForegroundColor $infoColor
    
        # Stop transcript
        Stop-Transcript
    }
    
    # Call the function
    Uninstall-DeployApplication
    