# Launch Flutter Mobile from anywhere
$mobileDir = Join-Path $PSScriptRoot "mobile"
Write-Host "Navigating to $mobileDir and starting Flutter Web on Port 4000..." -ForegroundColor Green
Set-Location -Path $mobileDir
flutter run -d chrome --web-port=4000
