#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
docker info >/dev/null
docker compose up -d --build
echo 'Aguardando LibreNMS...'
for ((i=0;i<90;i++)); do
  if docker compose exec -T librenms lnms user:add --help >/dev/null 2>&1 && docker compose exec -T librenms lnms config:get --help >/dev/null 2>&1; then break; fi
  sleep 5
done
echo 'Acesse http://localhost:8000. Se solicitado, finalize o instalador web.'
echo 'Para cadastrar os dispositivos automaticamente, execute bash configurar.sh apos concluir a instalacao.'
