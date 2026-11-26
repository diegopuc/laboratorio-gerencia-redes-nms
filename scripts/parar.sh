#!/usr/bin/env bash
export DOCKER_API_VERSION='1.44'
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Parando containers do Laboratorio de Gerencia de Redes..."
docker compose stop
echo "Containers parados com sucesso. Seus dados e configuracoes foram preservados."
