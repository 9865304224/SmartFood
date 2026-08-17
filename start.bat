@echo off
title SmartFood Launcher - Fixed Ports
echo ======================================================
echo        SMARTFOOD AI FOOD DELIVERY PLATFORM
echo ======================================================

echo [0/3] Clearing stale processes on ports 8080, 3000, 4000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":4000" ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

echo [1/3] Launching Spring Boot Backend on FIXED port 8080...
start "SmartFood Backend (8080)" cmd /k "cd backend && mvn spring-boot:run"

echo [2/3] Launching Admin Web Console on FIXED port 3000...
start "SmartFood Admin Web (3000)" cmd /k "cd admin-web && npm run dev"

echo.
echo ======================================================
echo   SmartFood Services are Locked & Running!
echo   - Backend:    http://localhost:8080/api
echo   - Admin Web:  http://localhost:3000
echo.
echo   To launch Flutter Mobile on FIXED port 4000:
echo   cd mobile && flutter run -d chrome --web-port=4000
echo ======================================================
