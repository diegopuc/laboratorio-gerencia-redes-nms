@echo off
cd /d "%~dp0"
docker info >nul 2>&1
if errorlevel 1 (echo Inicie o Docker primeiro. & pause & exit /b 1)
docker compose up -d --build
if errorlevel 1 (pause & exit /b 1)
echo Aguarde a inicializacao e acesse http://localhost:8000
 echo Se solicitado, conclua o instalador web. Execute configurar.bat em seguida.
start "" http://localhost:8000
pause
