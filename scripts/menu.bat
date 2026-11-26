@echo off
setlocal
cd /d "%~dp0"
title Laboratorio de Gerencia de Redes - Menu
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0menu.ps1"
