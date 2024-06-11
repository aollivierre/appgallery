function Install-Modules {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Modules
    )
    
    foreach ($module in $Modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Install-Module -Name $module -Force -Scope AllUsers
            Write-EnhancedLog -Message "Module '$module' installed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        else {
            Write-EnhancedLog -Message "Module '$module' is already installed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
}