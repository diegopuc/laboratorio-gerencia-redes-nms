@echo off
title Monitor de Logs do Firewall em Tempo Real (Estilo pfSense Status/Logs)
color 0A
cls
echo ====================================================================
echo  MONITOR DE LOGS DO FIREWALL EM TEMPO REAL (ESTILO pfSense)
echo ====================================================================
echo  Escutando todas as tentativas de conexao bloqueadas ou autorizadas...
echo  (Pressione CTRL+C para fechar esta janela a qualquer momento)
echo ====================================================================
echo.

cd /d "%~dp0"
docker compose exec firewall tcpdump -l -nn -i any "tcp dst port 8080"
pause
