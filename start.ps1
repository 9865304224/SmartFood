# SmartFood Full-Stack Startup Script with Fixed Ports
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "       SMARTFOOD AI FOOD DELIVERY PLATFORM           " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

# Function to kill existing processes on specific ports to ensure fixed ports
function Free-Port([int]$port) {
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connections) {
        foreach ($conn in $connections) {
            try {
                $processId = $conn.OwningProcess
                if ($processId -gt 0) {
                    Write-Host "  -> Freeing occupied port $port (PID: $processId)..." -ForegroundColor Yellow
                    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    }
}

Write-Host "`n[0/3] Clearing stale processes on fixed ports (8080, 3000, 4000)..." -ForegroundColor Gray
Free-Port 8080
Free-Port 3000
Free-Port 4000
Start-Sleep -Seconds 1

# 1. Start Spring Boot Backend on Fixed Port 8080
Write-Host "`n[1/3] Starting Spring Boot 3 Backend on FIXED Port 8080..." -ForegroundColor Yellow
Start-Process -FilePath "mvn" -ArgumentList "spring-boot:run" -WorkingDirectory "$PSScriptRoot\backend"

# 2. Start Admin Web Dashboard on Fixed Port 3000
Write-Host "[2/3] Starting Admin Web Console on FIXED Port 3000..." -ForegroundColor Yellow
Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run dev" -WorkingDirectory "$PSScriptRoot\admin-web"

Start-Sleep -Seconds 3

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "  SmartFood Services are Locked & Running!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  -> Backend REST & WS:   http://localhost:8080/api" -ForegroundColor White
Write-Host "  -> Admin Web Console:   http://localhost:3000" -ForegroundColor White
Write-Host "  -> Database:            MongoDB Atlas (smartfood_db)" -ForegroundColor White
Write-Host "  -> Cloud Storage:       Cloudinary (m61xswna)" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Green
Write-Host "`n  To launch Flutter Mobile App on FIXED Port 4000:" -ForegroundColor Cyan
Write-Host "     .\run_mobile.ps1" -ForegroundColor Yellow
Write-Host "  (or: cd mobile; flutter run -d chrome --web-port=4000)`n" -ForegroundColor Gray
