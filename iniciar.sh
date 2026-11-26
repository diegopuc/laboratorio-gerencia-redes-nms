#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "================================================================"
echo "    Laboratorio de Gerencia de Redes - LibreNMS e Docker        "
echo "================================================================"

# 1. Verifica se o Docker esta em execucao
echo "[1/6] Verificando Docker e Docker Compose..."
if ! docker info >/dev/null 2>&1; then
    echo "[ERRO] O Docker nao esta em execucao ou nao esta instalado!"
    echo "Inicie o daemon do Docker (ex: sudo systemctl start docker) e tente novamente."
    exit 1
fi

# Funcao para testar se a porta TCP esta livre
free_port() {
    local port="$1"
    if command -v ss >/dev/null 2>&1; then
        local listeners
        listeners=$(ss -H -ltn "sport = :$port" 2>/dev/null || true)
        [[ -z "$listeners" ]] || return 1
    fi
    ! (echo >/dev/tcp/127.0.0.1/"$port") 2>/dev/null
}

# 2. Verifica se o laboratorio ja esta rodando
current=$(docker compose port librenms 8000 2>/dev/null || true)
if [[ $current =~ ^127\.0\.0\.1:([0-9]+)$ ]]; then
    url="http://$current"
    echo -e "\n[INFO] O LibreNMS ja esta em execucao em $url"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 || true
    fi
    exit 0
fi

# 3. Deteccao de portas livres
echo "[2/6] Verificando portas TCP disponiveis..."
free_ports=()
for ((p=18080; p<=18180 && ${#free_ports[@]}<10; p++)); do
    if free_port "$p"; then
        free_ports+=("$p")
    fi
done

if [ ${#free_ports[@]} -eq 0 ]; then
    echo "[ERRO] Nao foi possivel encontrar portas livres na faixa 18080-18180."
    exit 1
fi

default_port="${free_ports[0]}"
echo "Portas livres sugeridas: ${free_ports[*]}"
echo "Porta recomendada: $default_port"

while true; do
    read -r -p "Digite a porta desejada [Pressione ENTER para usar $default_port]: " raw || exit 1
    if [ -z "$raw" ]; then
        port="$default_port"
        break
    elif [[ "$raw" =~ ^[0-9]+$ ]] && [ "$raw" -ge 1024 ] && [ "$raw" -le 65535 ]; then
        if free_port "$raw"; then
            port="$raw"
            break
        else
            echo "A porta $raw ja esta ocupada por outro servico. Escolha outra."
        fi
    else
        echo "Porta invalida. Digite um numero entre 1024 e 65535."
    fi
done

echo "Porta selecionada: $port"

# 4. Atualiza o arquivo .env
tmp=$(mktemp .env.XXXXXX 2>/dev/null || mktemp)
if [ -f .env ]; then
    grep -v -E '^[[:space:]]*(export[[:space:]]+)?LIBRENMS_PORT[[:space:]]*=' .env > "$tmp" || true
fi
echo "LIBRENMS_PORT=$port" >> "$tmp"
mv "$tmp" .env
export LIBRENMS_PORT="$port"

# 5. Inicia os containers
echo -e "\n[3/6] Construindo e iniciando containers Docker..."
docker compose up -d --build

url="http://127.0.0.1:$port"
echo -e "\n[4/6] Aguardando inicializacao do LibreNMS em $url ..."
ready=0
for ((i=0; i<40; i++)); do
    if curl -fsL --max-time 3 -o /dev/null "$url" 2>/dev/null; then
        ready=1
        break
    fi
    printf "."
    sleep 3
done
echo ""

# 6. Configuracao automatizada do LibreNMS ("magica" zero-touch)
echo -e "\n[5/6] Aplicando configuracoes automaticas no LibreNMS..."

# Remove flag de instalador web para abrir direto no login
docker compose exec -T librenms sh -c "sed -i '/^INSTALL=/d' /opt/librenms/.env /data/.env 2>/dev/null" || true

# Configura base_url
docker compose exec -T librenms lnms config:set base_url "$url" >/dev/null 2>&1 || true

# Cria usuario administrador (idempotente)
docker compose exec -T librenms lnms user:add admin --password="GerenciaLab@2026!" --role=admin >/dev/null 2>&1 || true

# Prime o scheduler cache
docker compose exec -T --user librenms librenms php /opt/librenms/artisan schedule:run >/dev/null 2>&1 || true

# Cadastra dispositivos do laboratorio
docker compose exec -T librenms lnms device:add firewall --v2c -c laboratorio >/dev/null 2>&1 || true
docker compose exec -T librenms lnms device:add servidor1 --v2c -c laboratorio >/dev/null 2>&1 || true
docker compose exec -T librenms lnms device:add servidor2 --v2c -c laboratorio >/dev/null 2>&1 || true

# Dispara descoberta inicial em segundo plano
docker compose exec -T -d --user librenms librenms php /opt/librenms/discovery.php -h all >/dev/null 2>&1 || true

echo -e "\n[6/6] Finalizado com sucesso!"
echo "================================================================"
echo "  LABORATORIO DE GERENCIA DE REDES PRONTO!"
echo "================================================================"
echo "  URL de Acesso:   $url"
echo "  Usuario Admin:   admin"
echo "  Senha Admin:     GerenciaLab@2026!"
echo "  Comunidade SNMP: laboratorio (v2c)"
echo "  Dispositivos:    firewall (172.28.0.254), servidor1 (172.28.0.11), servidor2 (172.28.0.12)"
echo "================================================================"
echo "Abrindo o navegador..."

if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
elif command -v sensible-browser >/dev/null 2>&1; then
    sensible-browser "$url" >/dev/null 2>&1 || true
fi
