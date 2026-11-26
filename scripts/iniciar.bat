@echo off
setlocal
cd /d "%~dp0"
title Laboratorio de Gerencia de Redes - LibreNMS
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1"
set "rc=%errorlevel%"
if %rc% neq 0 (
    echo.
    echo Ocorreu um erro durante a inicializacao.
    pause
)
exit /b %rc%
