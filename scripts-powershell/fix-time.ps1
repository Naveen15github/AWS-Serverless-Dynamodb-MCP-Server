# ================================================================================
# fix-time.ps1 - Fix Windows time synchronization issue
# ================================================================================

Write-Host "==================================================================="
Write-Host "  Fixing Time Synchronization Issue"
Write-Host "==================================================================="
Write-Host ""

Write-Host "Current system time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

Write-Host "Attempting to sync time (requires Administrator privileges)..."
Write-Host ""

try {
    # Try to sync time
    $result = w32tm /resync 2>&1
    Write-Host $result
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Time sync successful!" -ForegroundColor Green
        Write-Host "New system time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    } else {
        Write-Host ""
        Write-Host "Time sync failed. You may need to run PowerShell as Administrator." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Manual steps to fix:" -ForegroundColor Cyan
        Write-Host "1. Right-click the clock in your taskbar"
        Write-Host "2. Select 'Adjust date/time'"
        Write-Host "3. Click 'Sync now' under 'Synchronize your clock'"
        Write-Host "4. Or run this script as Administrator (right-click PowerShell -> Run as Administrator)"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==================================================================="
Write-Host ""
