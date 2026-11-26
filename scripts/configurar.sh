#!/usr/bin/env bash
export DOCKER_API_VERSION='1.44'
set -euo pipefail
cd "$(dirname "$0")"

echo "Configurando LibreNMS..."

port=18080
mapping=$(docker compose port librenms 8000 2>/dev/null || true)
if [[ $mapping =~ ^127\.0\.0\.1:([0-9]+)$ ]]; then
    port="${BASH_REMATCH[1]}"
fi
url="http://127.0.0.1:$port"

docker compose exec -T librenms sh -c "sed -i '/^INSTALL=/d' /opt/librenms/.env /data/.env 2>/dev/null" || true
docker compose exec -T librenms lnms config:set base_url "$url" >/dev/null 2>&1 || true
docker compose exec -T librenms lnms user:add admin --password="GerenciaLab@2026!" --role=admin >/dev/null 2>&1 || true
docker compose exec -T --user librenms librenms php /opt/librenms/artisan tinker --execute="App\Models\User::where('username', 'admin')->update(['password' => bcrypt('admin')]);" >/dev/null 2>&1 || true
docker compose exec -T --user librenms librenms php /opt/librenms/artisan schedule:run >/dev/null 2>&1 || true

docker compose exec -T librenms lnms device:add firewall --v2c -c laboratorio >/dev/null 2>&1 || true
docker compose exec -T librenms lnms device:add servidor1 --v2c -c laboratorio >/dev/null 2>&1 || true
docker compose exec -T librenms lnms device:add servidor2 --v2c -c laboratorio >/dev/null 2>&1 || true

docker compose exec -T -d --user librenms librenms php /opt/librenms/discovery.php -h all >/dev/null 2>&1 || true

echo "Configuracao concluida com sucesso!"
echo "Acesse: $url (admin / admin)"
