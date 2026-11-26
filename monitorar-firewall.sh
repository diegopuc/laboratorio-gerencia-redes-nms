#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

clear
echo "===================================================================="
echo " MONITOR DE LOGS DO FIREWALL EM TEMPO REAL (ESTILO pfSense)"
echo "===================================================================="
echo " Escutando todas as tentativas de conexao bloqueadas ou autorizadas..."
echo " (Pressione CTRL+C para sair)"
echo "===================================================================="
echo ""

docker compose exec firewall tcpdump -l -nn -i any "tcp dst port 8080"
