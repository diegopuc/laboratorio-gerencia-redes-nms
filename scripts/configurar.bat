@echo off
set DOCKER_API_VERSION=1.44
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar.ps1"
pause
