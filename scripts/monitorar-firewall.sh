#!/usr/bin/env bash
export DOCKER_API_VERSION='1.44'
set -euo pipefail
cd "$(dirname "$0")/.."
echo "===================================================================="
echo " MONITOR DE LOGS DO FIREWALL EM TEMPO REAL (ESTILO pfSense)"
echo "===================================================================="
echo " Escutando todas as tentativas de conexao bloqueadas ou autorizadas..."
echo " (Pressione CTRL+C para fechar a qualquer momento)"
echo "===================================================================="
echo ""
docker compose exec firewall tcpdump -l -nn -i any "tcp dst port 8080"
