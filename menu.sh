#!/bin/bash
cd "$(dirname "$0")"
while true; do
 echo '1 Iniciar | 2 Status | 3 Falha | 4 Recuperar | 5 Trafego | 6 CPU | 7 Perda | 8 Normalizar | 9 Abrir NMS | 10 Parar | 0 Sair'
 read -r op || exit
 case "$op" in
 1) bash iniciar.sh;; 2) docker compose ps;; 3) docker compose stop servidor2;; 4) docker compose start servidor2;;
 5) docker compose exec -T -d servidor1 iperf3 -c servidor2 -t 360 -b 10M;;
 6) docker compose exec -T -d servidor1 stress-ng --cpu 1 --timeout 360s;;
 7) docker compose exec -T servidor2 tc qdisc replace dev eth0 root netem loss 10%;;
 8) docker compose exec -T servidor2 tc qdisc del dev eth0 root;;
 9) m=$(docker compose port librenms 8000 2>/dev/null) && [[ $m =~ ^127\.0\.0\.1:[0-9]+$ ]] && { echo "http://$m"; if command -v xdg-open >/dev/null; then xdg-open "http://$m" || true; fi; } || echo "LibreNMS nao esta publicado.";; 10) docker compose down;; 0) exit;; esac
done
