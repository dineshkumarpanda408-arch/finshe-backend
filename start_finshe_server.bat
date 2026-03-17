@echo off
title Start FinShe Backend Server

:: -------------------------------
:: 1. Detect laptop IPv4
:: -------------------------------
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R /C:"IPv4 Address"') do (
    set ip=%%a
)
:: Remove spaces
set ip=%ip: =%
echo Detected IPv4: %ip%

:: -------------------------------
:: 2. Open firewall if not already
:: -------------------------------
powershell -Command "if (-Not (Get-NetFirewallRule -DisplayName 'FinShe Node Server')) { New-NetFirewallRule -DisplayName 'FinShe Node Server' -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow } else { Write-Host 'Firewall rule exists.' }"

:: -------------------------------
:: 3. Start server
:: -------------------------------
echo Starting FinShe backend...
node server.js

:: -------------------------------
:: 4. Display phone URL
:: -------------------------------
echo.
echo FinShe backend is running! 
echo You can access it from your phone at:
echo http://%ip%:3000
pause