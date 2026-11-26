#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
docker compose exec -T librenms lnms user:add admin --password=gerencia123 --role=admin || echo 'Verifique se o usuario ja existe ou use o instalador web.'
for host in servidor1 servidor2 firewall; do
 docker compose exec -T librenms lnms device:add "$host" --v2c -c laboratorio || echo "Verifique $host na interface web."
done
