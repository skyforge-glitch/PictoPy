Write-Host "Starting PictoPy services..." -ForegroundColor Cyan
$root = $PSScriptRoot

# Store the directory where you started the script
$OriginalDir = Get-Location

# ---------- Backend ----------
$backend = Start-Process powershell `
  -PassThru `
  -ArgumentList "-NoExit", "-Command",
  "cd '$root\backend'; .\.env\Scripts\Activate.ps1; uvicorn main:app --host 127.0.0.1 --port 52123"

Start-Sleep 3
Write-Host "Backend started (Window PID $($backend.Id))" -ForegroundColor Gray

# ---------- Sync Microservice ----------
$sync = Start-Process powershell `
  -PassThru `
  -ArgumentList "-NoExit", "-Command",
  "cd '$root\sync-microservice'; .\.sync-env\Scripts\Activate.ps1; uvicorn main:app --host 127.0.0.1 --port 52124"

Start-Sleep 3
Write-Host "Sync service started (Window PID $($sync.Id))" -ForegroundColor Gray

# ---------- Start Tauri ----------
Write-Host "Launching PictoPy..." -ForegroundColor Green
cd "$root\frontend"
npm run tauri dev

# ---------- CLEANUP ----------
Write-Host "`nPictoPy closed. Forcefully stopping all background services..." -ForegroundColor Red

function Stop-ProcessTree ($ParentId) {
    if ($ParentId) {
        Get-CimInstance Win32_Process |
        Where-Object { $_.ParentProcessId -eq $ParentId } |
        ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Stop-Process -Id $ParentId -Force -ErrorAction SilentlyContinue
    }
}

Stop-ProcessTree -ParentId $backend.Id
Stop-ProcessTree -ParentId $sync.Id

# Return to where you started
Set-Location $OriginalDir

Write-Host "All services stopped. Returned to root directory." -ForegroundColor Green
