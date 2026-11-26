@echo off
set DOCKER_API_VERSION=1.44
setlocal
cd /d "%~dp0"
title Laboratorio de Gerencia de Redes - Menu
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0menu.ps1"
