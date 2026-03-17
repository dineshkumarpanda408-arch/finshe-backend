@echo off
echo ============================================
echo FinShe - Open Firewall for Phone Connection
echo ============================================
echo.
echo Right-click this file and choose "Run as administrator"
echo to allow your phone to connect to the server.
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0allow_server_firewall.ps1"
echo.
pause
