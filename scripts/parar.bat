@echo off
set DOCKER_API_VERSION=1.44
setlocal
cd /d "%~dp0\.."
echo Parando containers do Laboratorio de Gerencia de Redes...
docker compose stop
echo.
echo Containers parados com sucesso. Seus dados e configuracoes foram preservados.
pause
