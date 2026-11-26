#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

pause_menu() {
    echo ""
    read -r -p "Pressione [ENTER] para voltar ao menu..." || true
}

while true; do
    clear
    echo "================================================================"
    echo "      Laboratorio de Gerencia de Redes - Menu Interativo        "
    echo "================================================================"
    echo "  GERAL:"
    echo "   1. Iniciar o laboratorio"
    echo "   2. Exibir status dos containers"
    echo "   3. Exibir dispositivos gerenciados no LibreNMS"
    echo "   4. Acessar a interface web do LibreNMS"
    echo ""
    echo "  FALHAS E DISPONIBILIDADE:"
    echo "   5. Desligar um dispositivo (servidor2)"
    echo "   6. Restabelecer um dispositivo (servidor2)"
    echo "   7. Desativar interface de rede (servidor2 / eth0)"
    echo "   8. Restabelecer interface de rede (servidor2 / eth0)"
    echo ""
    echo "  DESEMPENHO E TRAFEGO:"
    echo "   9. Gerar trafego de rede (servidor1 -> servidor2 via firewall)"
    echo "  10. Simular sobrecarga de CPU (servidor1)"
    echo "  11. Simular sobrecarga de memoria (servidor1)"
    echo "  12. Simular latencia de rede (no firewall: +120ms)"
    echo "  13. Simular perda de pacotes (no firewall: 20% perda)"
    echo ""
    echo "  SEGURANCA E REGISTROS:"
    echo "  14. Simular bloqueio no firewall (DROP HTTP porta 8080)"
    echo "  15. Gerar eventos de seguranca (port scan)"
    echo "  16. Consultar registros (logs do sistema e syslog)"
    echo ""
    echo "  MANUTENCAO:"
    echo "  17. Restabelecer todas as condicoes normais"
    echo "  18. Parar o laboratorio (preserva dados)"
    echo "  19. Restaurar ambiente ao estado inicial (apaga volumes)"
    echo "   0. Sair"
    echo "================================================================"
    read -r -p "Selecione uma opcao: " op || exit 0

    case "$op" in
        1)
            bash iniciar.sh
            pause_menu
            ;;
        2)
            echo -e "\n[Status dos Containers]"
            docker compose ps
            pause_menu
            ;;
        3)
            echo -e "\n[Dispositivos Gerenciados]"
            docker compose exec -T librenms lnms device:list || true
            pause_menu
            ;;
        4)
            mapping=$(docker compose port librenms 8000 2>/dev/null || true)
            if [[ $mapping =~ ^127\.0\.0\.1:([0-9]+)$ ]]; then
                url="http://$mapping"
                echo "Abrindo $url ..."
                if command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$url" >/dev/null 2>&1 || true
                elif command -v sensible-browser >/dev/null 2>&1; then
                    sensible-browser "$url" >/dev/null 2>&1 || true
                fi
            else
                echo "O LibreNMS nao esta em execucao. Use a opcao 1 para iniciar."
            fi
            sleep 2
            ;;
        5)
            echo -e "\nDesligando container servidor2..."
            docker compose stop servidor2
            echo "servidor2 foi desligado com sucesso."
            pause_menu
            ;;
        6)
            echo -e "\nIniciando container servidor2..."
            docker compose start servidor2
            echo "servidor2 iniciado com sucesso."
            pause_menu
            ;;
        7)
            echo -e "\nDesativando interface eth0 em servidor2..."
            docker compose exec -T servidor2 ip link set eth0 down || true
            echo "Interface eth0 desativada em servidor2."
            pause_menu
            ;;
        8)
            echo -e "\nRestabelecendo interface eth0 em servidor2..."
            docker compose exec -T servidor2 ip link set eth0 up || true
            echo "Interface eth0 reativada em servidor2."
            pause_menu
            ;;
        9)
            echo -e "\nIniciando geracao de trafego iperf3 de servidor1 para servidor2 atraves do firewall..."
            docker compose exec -T -d servidor1 iperf3 -c 172.28.2.10 -t 180 -b 15M || true
            echo "Trafego de 15 Mbps em geracao por 3 minutos."
            pause_menu
            ;;
        10)
            echo -e "\nIniciando stress-ng de CPU em servidor1..."
            docker compose exec -T -d servidor1 stress-ng --cpu 2 --timeout 180s || true
            echo "Sobrecarga de CPU aplicada por 3 minutos."
            pause_menu
            ;;
        11)
            echo -e "\nIniciando stress-ng de memoria em servidor1..."
            docker compose exec -T -d servidor1 stress-ng --vm 1 --vm-bytes 180M --timeout 180s || true
            echo "Sobrecarga de memoria aplicada por 3 minutos."
            pause_menu
            ;;
        12)
            echo -e "\nInjetando latencia de 120ms (+-15ms) no firewall (interface eth1)..."
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem delay 120ms 15ms || true
            echo "Latencia injetada."
            pause_menu
            ;;
        13)
            echo -e "\nInjetando 20% de perda de pacotes no firewall (interface eth1)..."
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem loss 20% || true
            echo "Perda de pacotes injetada."
            pause_menu
            ;;
        14)
            echo -e "\nAplicando regra de firewall para bloquear HTTP (porta 8080)..."
            docker compose exec -T firewall iptables -I FORWARD -p tcp --dport 8080 -j DROP || true
            echo "Regra aplicada: conexoes HTTP (8080) destinadas a DMZ estao sendo descartadas."
            pause_menu
            ;;
        15)
            echo -e "\nGerando eventos de seguranca (tentativas de conexao em portas fechadas)..."
            docker compose exec -T servidor1 bash -c "for p in 21 22 23 25 3306 8000; do nc -z -w 1 172.28.2.10 \$p 2>/dev/null || true; done" || true
            echo "Varredura executada."
            pause_menu
            ;;
        16)
            echo -e "\n[Ultimos registros de logs do sistema]"
            docker compose logs --tail=30 syslog librenms || true
            pause_menu
            ;;
        17)
            echo -e "\nRestabelecendo condicoes normais em todos os dispositivos..."
            docker compose exec -T servidor1 pkill stress-ng 2>/dev/null || true
            docker compose exec -T servidor2 pkill stress-ng 2>/dev/null || true
            docker compose exec -T firewall iptables -F FORWARD 2>/dev/null || true
            docker compose exec -T firewall iptables -P FORWARD ACCEPT 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth0 root 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth2 root 2>/dev/null || true
            docker compose exec -T servidor2 tc qdisc del dev eth0 root 2>/dev/null || true
            docker compose exec -T servidor1 ip link set eth0 up 2>/dev/null || true
            docker compose exec -T servidor2 ip link set eth0 up 2>/dev/null || true
            echo "Todas as condicoes normais foram restabelecidas com sucesso!"
            pause_menu
            ;;
        18)
            echo -e "\nParando containers do laboratorio..."
            docker compose stop
            echo "Containers parados. Seus dados e configuracoes foram preservados."
            pause_menu
            ;;
        19)
            echo -e "\n[ATENCAO] Esta operacao removera todos os containers e volumes persistentes!"
            read -r -p "Deseja realmente restaurar o ambiente ao estado inicial? (s/N): " conf
            if [[ "$conf" =~ ^[sS] ]]; then
                echo "Destruindo ambiente e volumes..."
                docker compose down -v
                echo "Ambiente restaurado ao estado inicial."
            else
                echo "Operacao cancelada."
            fi
            pause_menu
            ;;
        0)
            exit 0
            ;;
    esac
done
