#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Parando containers do Laboratorio de Gerencia de Redes..."
docker compose stop
echo "Containers parados com sucesso. Seus dados e configuracoes foram preservados."
