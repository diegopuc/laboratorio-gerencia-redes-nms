#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_header() {
    clear
    echo "================================================================"
    echo "   LABORATORIO DE GERENCIA DE REDES - CONTROLE E DASHBOARD      "
    echo "================================================================"
}

pause_menu() {
    echo ""
    read -p "Pressione [ENTER] para voltar ao menu..."
}

execute_sql_sync() {
    local sql="$1"
    echo "$sql" | docker compose exec -T db mariadb -u librenms -plab-db-local librenms >/dev/null 2>&1 || true
    docker compose exec -T redis redis-cli FLUSHALL >/dev/null 2>&1 || true
}

log_lab_event() {
    local msg="$1"
    local device="${2:-servidor1}"
    local severity="${3:-2}"
    local sql="INSERT INTO eventlog (device_id, datetime, message, type, severity) SELECT device_id, NOW(), '$msg', 'menu-lab', $severity FROM devices WHERE hostname = '$device' LIMIT 1;"
    execute_sql_sync "$sql"
}

while true; do
    show_header
    echo -e "  GERENCIAMENTO E INICIALIZACAO DO AMBIENTE:"
    echo "   1. Iniciar / Configurar o Laboratorio (Zerar do zero, escolher porta e subir)"
    echo "   2. Acessar a Interface Web do LibreNMS no Navegador (Dashboard NOC)"
    echo "   3. Exibir status dos containers Docker (docker compose ps)"
    echo "   4. Parar containers do laboratorio (Preserva dados)"
    echo "   5. Restaurar ambiente ao estado inicial virgem (Apaga volumes do zero)"
    echo ""
    echo -e "  SIMULAÇÕES NOC (DASHBOARD EM TEMPO REAL):"
    echo "   6. [AVAILABILITY MAP] Desligar servidor2 (Bloco 'servidor2' fica VERMELHO no mapa)"
    echo "   7. [AVAILABILITY MAP] Ligar servidor2 (Bloco 'servidor2' volta para VERDE no mapa)"
    echo "   8. [PORT SUMMARY] Desativar placa eth1 do servidor2 (Aumenta 'Down' em Ports)"
    echo "   9. [PORT SUMMARY] Reativar placa eth1 do servidor2 (Zera 'Down' em Ports)"
    echo "  10. [ALERTA CPU] Provocar pico de 100% de CPU em servidor1 (Acende alerta no quadro)"
    echo "  11. [NORMALIZAR CPU] Parar estresse de CPU (Remove alerta do quadro)"
    echo "  12. [ALERTA LINK] Injetar 25% de perda de pacotes (Acende alerta de latencia/perda)"
    echo "  13. [NORMALIZAR LINK] Remover perda de pacotes do link (Remove alerta do quadro)"
    echo "  14. [EVENTLOG] Enviar mensagem personalizada de operador para a Dashboard"
    echo "  15. [RESET GERAL] Restaurar tudo para 100% Normal e Saudavel (Tudo Verde / Sem Alertas)"
    echo "   0. Sair"
    echo "================================================================"
    
    read -p "Selecione uma opcao: " op

    case "$op" in
        1)
            bash "$SCRIPT_DIR/iniciar.sh"
            pause_menu
            ;;
        2)
            port=$(docker compose port librenms 8000 2>/dev/null | awk -F: '{print $NF}' || true)
            if [ -n "$port" ]; then
                url="http://127.0.0.1:$port/overview"
                echo "Abrindo Dashboard NOC em: $url"
                if command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$url" || true
                elif command -v sensible-browser >/dev/null 2>&1; then
                    sensible-browser "$url" || true
                fi
            else
                echo "O LibreNMS nao esta em execucao. Use a opcao 1 para iniciar."
            fi
            sleep 1
            ;;
        3)
            echo -e "\n[Status dos Containers Docker]"
            docker compose ps
            pause_menu
            ;;
        4)
            echo -e "\nParando containers do laboratorio..."
            docker compose stop
            echo "Laboratorio pausado. Seus dados e historicos foram preservados."
            pause_menu
            ;;
        5)
            echo -e "\n[ATENCAO] Esta operacao removera todos os containers e volumes persistentes do zero!"
            read -p "Deseja realmente apagar tudo e recomecar do zero virgem? (s/N): " conf || true
            if [[ "$conf" =~ ^[sS] ]]; then
                echo "Destruindo ambiente e volumes..."
                docker compose down -v --rmi local 2>/dev/null || true
                rm -f .env 2>/dev/null || true
                echo "Ambiente restaurado ao estado inicial virgem. Use a opcao 1 para subir novamente."
            else
                echo "Operacao cancelada."
            fi
            pause_menu
            ;;
        6)
            echo -e "\n[AÇÃO] Desligando servidor2..."
            docker compose stop servidor2
            sql="UPDATE devices SET status = 0, status_reason = 'icmp,snmp' WHERE hostname = 'servidor2';
DELETE FROM alert_faults WHERE rule_id = 1 AND device_id = 3;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (1, 3, 'device', 3, '3', 1, 1, 1, 'critical', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 1 AND device_id = 3;"
            execute_sql_sync "$sql"
            log_lab_event "FALHA: Host servidor2 desligado manualmente (Mudou para DOWN no Availability Map)" "servidor2" 5
            echo "[OK] servidor2 desligado!"
            echo " -> Availability Map: bloco 'servidor2' fica VERMELHO."
            echo " -> Alerts: alerta crítico 'Dispositivo Inacessivel / Fora do Ar' registrado."
            pause_menu
            ;;
        7)
            echo -e "\n[AÇÃO] Ligando servidor2..."
            docker compose start servidor2
            sql="UPDATE devices SET status = 1, status_reason = '' WHERE hostname = 'servidor2';
DELETE FROM alert_faults WHERE rule_id = 1 AND device_id = 3;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 1 AND device_id = 3;"
            execute_sql_sync "$sql"
            log_lab_event "RECUPERACAO: Host servidor2 religado (Mudou para UP no Availability Map)" "servidor2" 1
            echo "[OK] servidor2 restabelecido!"
            echo " -> Availability Map: bloco 'servidor2' volta para VERDE."
            echo " -> Alerts: alerta resolvido e removido do quadro."
            pause_menu
            ;;
        8)
            echo -e "\n[AÇÃO] Desativando interface eth1 de servidor2..."
            docker compose exec -T servidor2 ip link set eth1 down 2>/dev/null || true
            sql="UPDATE ports SET ifOperStatus = 'down' WHERE device_id = 3 AND ifName = 'eth1';
DELETE FROM alert_faults WHERE rule_id = 2 AND device_id = 3;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (2, 3, 'port', 3, '3', 1, 1, 1, 'critical', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 2 AND device_id = 3;"
            execute_sql_sync "$sql"
            log_lab_event "INCIDENTE: Interface eth1 de servidor2 derrubada (ifOperStatus DOWN)" "servidor2" 5
            echo "[OK] Interface eth1 desativada!"
            echo " -> Device Summary: contador 'Down' em Ports sobe para 1."
            echo " -> Alerts: alerta de porta derrubada ativado."
            pause_menu
            ;;
        9)
            echo -e "\n[AÇÃO] Reativando interface eth1 de servidor2..."
            docker compose exec -T servidor2 ip link set eth1 up 2>/dev/null || true
            sql="UPDATE ports SET ifOperStatus = 'up' WHERE device_id = 3 AND ifName = 'eth1';
DELETE FROM alert_faults WHERE rule_id = 2 AND device_id = 3;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 2 AND device_id = 3;"
            execute_sql_sync "$sql"
            log_lab_event "RECUPERACAO: Interface eth1 de servidor2 restabelecida (ifOperStatus UP)" "servidor2" 1
            echo "[OK] Interface eth1 reativada!"
            echo " -> Device Summary: contador 'Down' em Ports volta para 0."
            echo " -> Alerts: alerta de porta removido."
            pause_menu
            ;;
        10)
            echo -e "\n[AÇÃO] Injetando estresse maximo de CPU em servidor1 (100%)..."
            docker compose exec -T -d servidor1 stress-ng --cpu 2 --timeout 300s
            sql="DELETE FROM alert_faults WHERE rule_id = 3 AND device_id = 2;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (3, 2, 'processor', 2, '2', 1, 1, 1, 'warning', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 3 AND device_id = 2;"
            execute_sql_sync "$sql"
            log_lab_event "INCIDENTE: Sobrecarga critica de CPU detectada em servidor1 (100%)" "servidor1" 4
            echo "[OK] Sobrecarga ativa!"
            echo " -> Alerts: alerta de 'Sobrecarga de CPU (> 80%)' acende no quadro em servidor1."
            pause_menu
            ;;
        11)
            echo -e "\n[AÇÃO] Interrompendo estresse de CPU em servidor1..."
            docker compose exec -T servidor1 pkill stress-ng 2>/dev/null || true
            sql="DELETE FROM alert_faults WHERE rule_id = 3 AND device_id = 2;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 3 AND device_id = 2;"
            execute_sql_sync "$sql"
            log_lab_event "NORMALIZACAO: Processos de sobrecarga cancelados em servidor1 (CPU Normal)" "servidor1" 1
            echo "[OK] CPU normalizada!"
            echo " -> Alerts: alerta de sobrecarga removido imediatamente do quadro."
            pause_menu
            ;;
        12)
            echo -e "\n[AÇÃO] Injetando 25% de perda de pacotes no link do firewall..."
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem loss 25% 2>/dev/null || true
            sql="DELETE FROM alert_faults WHERE rule_id = 4 AND device_id = 1;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (4, 1, 'device', 1, '1', 1, 1, 1, 'warning', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 4 AND device_id = 1;"
            execute_sql_sync "$sql"
            log_lab_event "DEGRADACAO: Injetada perda severa de 25% de pacotes no link do firewall" "firewall" 4
            echo "[OK] Perda de pacotes ativa no link!"
            echo " -> Alerts: alerta de 'Latencia de Rede Alta / Perda de Pacotes' registrado."
            pause_menu
            ;;
        13)
            echo -e "\n[AÇÃO] Removendo perda de pacotes do link do firewall..."
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>/dev/null || true
            sql="DELETE FROM alert_faults WHERE rule_id = 4 AND device_id = 1;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 4 AND device_id = 1;"
            execute_sql_sync "$sql"
            log_lab_event "NORMALIZACAO: Qualidade do link do firewall restabelecida (0% perda)" "firewall" 1
            echo "[OK] Link normalizado sem perdas de pacotes!"
            echo " -> Alerts: alerta de latencia/perda removido do quadro."
            pause_menu
            ;;
        14)
            read -p "Digite a mensagem para registrar no painel NOC: " msg
            if [ -n "$msg" ]; then
                log_lab_event "MENSAGEM DE OPERADOR: $msg" "firewall" 2
                echo "[OK] Mensagem enviada para o widget 'EventLog' na Dashboard!"
            fi
            pause_menu
            ;;
        15)
            echo -e "\n[AÇÃO] Restaurando 100% das condicoes normais (Tudo Verde)..."
            docker compose start servidor2 2>/dev/null || true
            docker compose exec -T servidor1 pkill stress-ng 2>/dev/null || true
            docker compose exec -T servidor1 pkill iperf3 2>/dev/null || true
            docker compose exec -T servidor2 pkill stress-ng 2>/dev/null || true
            docker compose exec -T firewall iptables -F FORWARD 2>/dev/null || true
            docker compose exec -T firewall iptables -P FORWARD ACCEPT 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth0 root 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>/dev/null || true
            docker compose exec -T firewall tc qdisc del dev eth2 root 2>/dev/null || true
            docker compose exec -T servidor2 ip link set eth0 up 2>/dev/null || true
            docker compose exec -T servidor2 ip link set eth1 up 2>/dev/null || true
            sql="DELETE FROM alert_faults;
UPDATE alerts SET state = 0, open = 0, alerted = 0;
UPDATE devices SET status = 1, status_reason = '';
UPDATE ports SET ifOperStatus = 'up';"
            execute_sql_sync "$sql"
            log_lab_event "RESET GERAL: Todo o parque de maquinas esta 100% operacional e saudavel (Tudo Verde)" "firewall" 1
            echo "[OK] Ambiente 100% normalizado!"
            echo " -> Todos os blocos do mapa estao VERDES."
            echo " -> Todos os alertas foram limpos (0 alertas ativos)."
            echo " -> EventLog registra a normalizacao completa do ambiente."
            pause_menu
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opcao invalida."
            pause_menu
            ;;
    esac
done
