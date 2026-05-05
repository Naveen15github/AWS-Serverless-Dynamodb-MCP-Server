# ================================================================================
# sync-time-and-retry.ps1 - Sync system time and retry deployment
# ================================================================================

Write-Host "==================================================================="
Write-Host "  Syncing System Time"
Write-Host "==================================================================="
Write-Host ""

# Sync Windows time with time server
Write-Host "Stopping Windows Time service..."
Stop-Service w32time -ErrorAction SilentlyContinue

Write-Host "Starting Windows Time service..."
Start-Service w32time

Write-Host "Syncing time with time.windows.com..."
w32tm /resync /force

Write-Host ""
Write-Host "Current system time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Wait a moment for time to stabilize
Start-Sleep -Seconds 2

Write-Host "==================================================================="
Write-Host "  Retrying Terraform Apply"
Write-Host "==================================================================="
Write-Host ""

Push-Location 01-lambdas
try {
    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Terraform apply failed. Please check the errors above." -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "==================================================================="
Write-Host "  Terraform apply completed successfully!"
Write-Host "==================================================================="
Write-Host ""
