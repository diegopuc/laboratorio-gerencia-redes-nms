@echo off
cd /d "%~dp0"
:menu
 echo 1 Iniciar  2 Status  3 Falha  4 Recuperar  5 Trafego
 echo 6 CPU  7 Perda  8 Normalizar  9 Abrir NMS  10 Parar  0 Sair
set /p op=Opcao: 
if "%op%"=="1" call iniciar.bat
if "%op%"=="2" docker compose ps
if "%op%"=="3" docker compose stop servidor2
if "%op%"=="4" docker compose start servidor2
if "%op%"=="5" docker compose exec -T -d servidor1 iperf3 -c servidor2 -t 360 -b 10M
if "%op%"=="6" docker compose exec -T -d servidor1 stress-ng --cpu 1 --timeout 360s
if "%op%"=="7" docker compose exec -T servidor2 tc qdisc replace dev eth0 root netem loss 10%%
if "%op%"=="8" docker compose exec -T servidor2 tc qdisc del dev eth0 root
if "%op%"=="9" start "" http://localhost:8000
if "%op%"=="10" docker compose down
if "%op%"=="0" exit /b
 goto menu
