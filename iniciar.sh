#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
docker info >/dev/null
command -v ss >/dev/null || { echo 'Instale iproute2 (comando ss).'; exit 1; }
command -v curl >/dev/null || { echo 'Instale curl.'; exit 1; }
current=$(docker compose port librenms 8000 2>/dev/null || true)
if [[ $current =~ ^127\.0\.0\.1:([0-9]+)$ ]]; then
  echo "LibreNMS ja publicado em http://$current. Pare o laboratorio para trocar a porta."
  exit 0
fi
free_port() {
  local listeners
  listeners=$(ss -H -ltn "sport = :$1") || return 1
  [[ -z $listeners ]] || return 1
  ! (echo >/dev/tcp/127.0.0.1/"$1") 2>/dev/null
}
echo 'Portas livres sugeridas:'
count=0
for ((p=18080;p<=18180 && count<10;p++)); do
  if free_port "$p"; then printf '%s ' "$p"; count=$((count+1)); fi
done
printf '\n'
while true; do
  read -r -p 'Digite a porta desejada (1024-65535): ' raw || exit 1
  if [[ $raw =~ ^[0-9]{1,5}$ ]]; then
    port=$((10#$raw))
    if ((port>=1024 && port<=65535)) && free_port "$port"; then break; fi
  fi
  echo 'Porta invalida ou ocupada. Escolha outra.'
done
tmp=$(mktemp .env.XXXXXX)
if [[ -f .env ]]; then awk '!/^[[:space:]]*(export[[:space:]]+)?LIBRENMS_PORT[[:space:]]*=/' .env > "$tmp"; fi
printf 'LIBRENMS_PORT=%s\n' "$port" >> "$tmp"
mv "$tmp" .env
export LIBRENMS_PORT=$port
if ! docker compose up -d --build; then echo 'Falha ao iniciar. Execute novamente e escolha outra porta se houver conflito.'; exit 1; fi
actual=$(docker compose port librenms 8000)
[[ $actual == "127.0.0.1:$port" ]] || { echo 'Mapeamento inesperado.'; exit 1; }
url="http://$actual"
echo "Aguardando LibreNMS em $url ..."
for ((i=0;i<60;i++)); do
  if curl -fsL --max-time 3 -o /dev/null "$url"; then
    echo "Acesse $url. Se necessario, finalize o instalador e execute bash configurar.sh."
    if command -v xdg-open >/dev/null; then xdg-open "$url" >/dev/null 2>&1 || true; fi
    exit 0
  fi
  sleep 3
done
echo "O servico ainda nao respondeu. Consulte docker compose logs librenms. Endereco: $url"
exit 1
