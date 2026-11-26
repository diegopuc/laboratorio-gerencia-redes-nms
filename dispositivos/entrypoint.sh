#!/bin/bash
set -eu

# Habilita roteamento IPv4 se for o roteador/firewall
if [ -w /proc/sys/net/ipv4/ip_forward ]; then
    sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true
fi

# Se for servidor1, adiciona rota para a rede DMZ (172.28.2.0/24) via firewall (172.28.1.254)
if [ "$(hostname)" = "servidor1" ]; then
    ip route add 172.28.2.0/24 via 172.28.1.254 2>/dev/null || true
fi

# Se for servidor2, adiciona rota para a rede LAN (172.28.1.0/24) via firewall (172.28.2.254)
if [ "$(hostname)" = "servidor2" ]; then
    ip route add 172.28.1.0/24 via 172.28.2.254 2>/dev/null || true
fi

# Prepara diretorio web e pagina de identificacao
mkdir -p /var/www/html /run/nginx
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>$(hostname) - Laboratorio de Gerencia de Redes</title>
    <style>
        body { font-family: sans-serif; margin: 40px; background: #f4f6f9; color: #333; }
        .card { background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.1); }
        h1 { color: #0284c7; }
        code { background: #e2e8f0; padding: 2px 6px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Dispositivo: $(hostname)</h1>
        <p>Laborat&oacute;rio de Ger&ecirc;ncia de Redes com LibreNMS</p>
        <p>Servi&ccedil;os ativos: <code>Nginx (8080)</code>, <code>iperf3 (5201)</code>, <code>SNMPd (161/udp)</code></p>
    </div>
</body>
</html>
EOF

# Configuracao simples do Nginx na porta 8080
cat <<EOF > /etc/nginx/http.d/default.conf
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    root /var/www/html;
    index index.html;
    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Inicia servidor web Nginx
nginx

# Inicia servidor de teste de vazao iperf3 em segundo plano (porta 5201)
iperf3 -s -D

# Inicia agente SNMP Net-SNMP em primeiro plano
exec snmpd -f -Lo -C -c /etc/snmp/snmpd.conf
