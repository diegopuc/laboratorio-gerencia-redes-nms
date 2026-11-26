$env:DOCKER_API_VERSION = '1.44'
<#
.SYNOPSIS
    Painel de Controle e Simulacoes do Laboratorio de Gerencia de Redes
#>
$RepoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $RepoRoot

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   LABORATORIO DE GERENCIA DE REDES - CONTROLE E DASHBOARD      " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Pause-Menu {
    Write-Host ""
    Read-Host "Pressione [ENTER] para voltar ao menu..."
}

function Execute-SqlSync {
    param([string]$Sql)
    $Sql | docker compose exec -T db mariadb -u librenms -plab-db-local librenms 2>$null
    docker compose exec -T redis redis-cli FLUSHALL 2>$null | Out-Null
}

function Log-LabEvent {
    param(
        [string]$Message,
        [string]$Device = "servidor1",
        [int]$Severity = 2
    )
    $sql = "INSERT INTO eventlog (device_id, datetime, message, type, severity) SELECT device_id, NOW(), '$Message', 'menu-lab', $Severity FROM devices WHERE hostname = '$Device' LIMIT 1;"
    Execute-SqlSync -Sql $sql
}

do {
    Show-Header
    Write-Host "  GERENCIAMENTO E INICIALIZACAO DO AMBIENTE:" -ForegroundColor Yellow
    Write-Host "   1. Iniciar / Configurar o Laboratorio (Zerar do zero, escolher porta e subir)"
    Write-Host "   2. Acessar a Interface Web do LibreNMS no Navegador (Dashboard NOC)"
    Write-Host "   3. Exibir status dos containers Docker (docker compose ps)"
    Write-Host "   4. Parar containers do laboratorio (Preserva dados)"
    Write-Host "   5. Restaurar ambiente ao estado inicial virgem (Apaga volumes do zero)"
    Write-Host ""
    Write-Host "  SIMULAÇÕES NOC (DASHBOARD EM TEMPO REAL):" -ForegroundColor Cyan
    Write-Host "   6. [AVAILABILITY MAP] Desligar servidor2 (Bloco 'servidor2' fica VERMELHO no mapa)"
    Write-Host "   7. [AVAILABILITY MAP] Ligar servidor2 (Bloco 'servidor2' volta para VERDE no mapa)"
    Write-Host "   8. [PORT SUMMARY] Desativar placa eth1 do servidor2 (Aumenta 'Down' em Ports)"
    Write-Host "   9. [PORT SUMMARY] Reativar placa eth1 do servidor2 (Zera 'Down' em Ports)"
    Write-Host "  10. [ALERTA CPU] Provocar pico de 100% de CPU em servidor1 (Acende alerta no quadro)"
    Write-Host "  11. [NORMALIZAR CPU] Parar estresse de CPU (Remove alerta do quadro)"
    Write-Host "  12. [ALERTA LINK] Injetar 25% de perda de pacotes (Acende alerta de latencia/perda)"
    Write-Host "  13. [NORMALIZAR LINK] Remover perda de pacotes do link (Remove alerta do quadro)"
    Write-Host "  14. [EVENTLOG] Enviar mensagem personalizada de operador para a Dashboard"
    Write-Host "  15. [RESET GERAL] Restaurar tudo para 100% Normal e Saudavel (Tudo Verde / Sem Alertas)"
    Write-Host "   0. Sair"
    Write-Host "================================================================" -ForegroundColor Cyan
    
    $op = Read-Host "Selecione uma opcao"

    switch ($op) {
        "1" {
            & "$PSScriptRoot\iniciar.ps1"
            Pause-Menu
        }
        "2" {
            $mapping = docker compose port librenms 8000 2>$null
            if ($mapping -match ':(\d+)$') {
                $port = $matches[1]
                $url = "http://127.0.0.1:$port/overview"
                Write-Host "Abrindo Dashboard NOC em: $url" -ForegroundColor Green
                Start-Process $url
            } else {
                Write-Host "O LibreNMS nao esta rodando. Use a opcao 1 para iniciar." -ForegroundColor Red
            }
            Start-Sleep -Seconds 1
        }
        "3" {
            Write-Host "`n[Status dos Containers Docker]" -ForegroundColor Cyan
            docker compose ps
            Pause-Menu
        }
        "4" {
            Write-Host "`nParando containers do laboratorio..." -ForegroundColor Yellow
            docker compose stop
            Write-Host "Laboratorio pausado. Seus dados e historicos foram preservados." -ForegroundColor Green
            Pause-Menu
        }
        "5" {
            Write-Host "`n[ATENCAO] Esta operacao removera todos os containers e volumes persistentes do zero!" -ForegroundColor Red
            $conf = Read-Host "Deseja realmente apagar tudo e recomecar do zero virgem? (s/N)"
            if ($conf -match '^[sS]') {
                Write-Host "Destruindo ambiente e volumes..." -ForegroundColor Yellow
                docker compose down -v --rmi local 2>$null
                Remove-Item (Join-Path $RepoRoot '.env') -Force -ErrorAction SilentlyContinue
                Write-Host "Ambiente restaurado ao estado inicial virgem. Use a opcao 1 para subir novamente." -ForegroundColor Green
            } else {
                Write-Host "Operacao cancelada." -ForegroundColor Gray
            }
            Pause-Menu
        }
        "6" {
            Write-Host "`n[AÇÃO] Desligando servidor2..." -ForegroundColor Yellow
            docker compose stop servidor2
            
            $sql = @"
UPDATE devices SET status = 0, status_reason = 'icmp,snmp' WHERE hostname = 'servidor2';
DELETE FROM alert_faults WHERE rule_id = 1 AND device_id = 3;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (1, 3, 'device', 3, '3', 1, 1, 1, 'critical', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 1 AND device_id = 3;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "FALHA: Host servidor2 desligado manualmente (Mudou para DOWN no Availability Map)" -Device "servidor2" -Severity 5
            Write-Host "[OK] servidor2 desligado!" -ForegroundColor Green
            Write-Host " -> Availability Map: bloco 'servidor2' fica VERMELHO." -ForegroundColor Red
            Write-Host " -> Alerts: alerta crítico 'Dispositivo Inacessivel / Fora do Ar' registrado." -ForegroundColor Red
            Pause-Menu
        }
        "7" {
            Write-Host "`n[AÇÃO] Ligando servidor2..." -ForegroundColor Yellow
            docker compose start servidor2
            
            $sql = @"
UPDATE devices SET status = 1, status_reason = '' WHERE hostname = 'servidor2';
DELETE FROM alert_faults WHERE rule_id = 1 AND device_id = 3;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 1 AND device_id = 3;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "RECUPERACAO: Host servidor2 religado (Mudou para UP no Availability Map)" -Device "servidor2" -Severity 1
            Write-Host "[OK] servidor2 restabelecido!" -ForegroundColor Green
            Write-Host " -> Availability Map: bloco 'servidor2' volta para VERDE." -ForegroundColor Green
            Write-Host " -> Alerts: alerta resolvido e removido do quadro." -ForegroundColor Green
            Pause-Menu
        }
        "8" {
            Write-Host "`n[AÇÃO] Desativando interface eth1 de servidor2..." -ForegroundColor Yellow
            docker compose exec -T servidor2 ip link set eth1 down 2>$null
            
            $sql = @"
UPDATE ports SET ifOperStatus = 'down' WHERE device_id = 3 AND ifName = 'eth1';
DELETE FROM alert_faults WHERE rule_id = 2 AND device_id = 3;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (2, 3, 'port', 3, '3', 1, 1, 1, 'critical', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 2 AND device_id = 3;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "INCIDENTE: Interface eth1 de servidor2 derrubada (ifOperStatus DOWN)" -Device "servidor2" -Severity 5
            Write-Host "[OK] Interface eth1 desativada!" -ForegroundColor Green
            Write-Host " -> Device Summary: contador 'Down' em Ports sobe para 1." -ForegroundColor Yellow
            Write-Host " -> Alerts: alerta de porta derrubada ativado." -ForegroundColor Yellow
            Pause-Menu
        }
        "9" {
            Write-Host "`n[AÇÃO] Reativando interface eth1 de servidor2..." -ForegroundColor Yellow
            docker compose exec -T servidor2 ip link set eth1 up 2>$null
            
            $sql = @"
UPDATE ports SET ifOperStatus = 'up' WHERE device_id = 3 AND ifName = 'eth1';
DELETE FROM alert_faults WHERE rule_id = 2 AND device_id = 3;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 2 AND device_id = 3;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "RECUPERACAO: Interface eth1 de servidor2 restabelecida (ifOperStatus UP)" -Device "servidor2" -Severity 1
            Write-Host "[OK] Interface eth1 reativada!" -ForegroundColor Green
            Write-Host " -> Device Summary: contador 'Down' em Ports volta para 0." -ForegroundColor Green
            Write-Host " -> Alerts: alerta de porta removido." -ForegroundColor Green
            Pause-Menu
        }
        "10" {
            Write-Host "`n[AÇÃO] Injetando estresse maximo de CPU em servidor1 (100%)..." -ForegroundColor Red
            docker compose exec -T -d servidor1 stress-ng --cpu 2 --timeout 300s
            
            $sql = @"
DELETE FROM alert_faults WHERE rule_id = 3 AND device_id = 2;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (3, 2, 'processor', 2, '2', 1, 1, 1, 'warning', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 3 AND device_id = 2;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "INCIDENTE: Sobrecarga critica de CPU detectada em servidor1 (100%)" -Device "servidor1" -Severity 4
            Write-Host "[OK] Sobrecarga ativa!" -ForegroundColor Green
            Write-Host " -> Alerts: alerta de 'Sobrecarga de CPU (> 80%)' acende no quadro em servidor1." -ForegroundColor Yellow
            Pause-Menu
        }
        "11" {
            Write-Host "`n[AÇÃO] Interrompendo estresse de CPU em servidor1..." -ForegroundColor Green
            docker compose exec -T servidor1 pkill stress-ng 2>$null
            
            $sql = @"
DELETE FROM alert_faults WHERE rule_id = 3 AND device_id = 2;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 3 AND device_id = 2;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "NORMALIZACAO: Processos de sobrecarga cancelados em servidor1 (CPU Normal)" -Device "servidor1" -Severity 1
            Write-Host "[OK] CPU normalizada!" -ForegroundColor Green
            Write-Host " -> Alerts: alerta de sobrecarga removido imediatamente do quadro." -ForegroundColor Green
            Pause-Menu
        }
        "12" {
            Write-Host "`n[AÇÃO] Injetando 25% de perda de pacotes no link do firewall..." -ForegroundColor Red
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem loss 25% 2>$null
            
            $sql = @"
DELETE FROM alert_faults WHERE rule_id = 4 AND device_id = 1;
INSERT INTO alert_faults (rule_id, device_id, entity_type, entity_id, entity_key, state, alerted, open, severity, timestamp)
VALUES (4, 1, 'device', 1, '1', 1, 1, 1, 'warning', NOW());
UPDATE alerts SET state = 1, open = 1, alerted = 1, timestamp = NOW() WHERE rule_id = 4 AND device_id = 1;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "DEGRADACAO: Injetada perda severa de 25% de pacotes no link do firewall" -Device "firewall" -Severity 4
            Write-Host "[OK] Perda de pacotes ativa no link!" -ForegroundColor Green
            Write-Host " -> Alerts: alerta de 'Latencia de Rede Alta / Perda de Pacotes' registrado." -ForegroundColor Yellow
            Pause-Menu
        }
        "13" {
            Write-Host "`n[AÇÃO] Removendo perda de pacotes do link do firewall..." -ForegroundColor Green
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>$null
            
            $sql = @"
DELETE FROM alert_faults WHERE rule_id = 4 AND device_id = 1;
UPDATE alerts SET state = 0, open = 0, alerted = 0 WHERE rule_id = 4 AND device_id = 1;
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "NORMALIZACAO: Qualidade do link do firewall restabelecida (0% perda)" -Device "firewall" -Severity 1
            Write-Host "[OK] Link normalizado sem perdas de pacotes!" -ForegroundColor Green
            Write-Host " -> Alerts: alerta de latencia/perda removido do quadro." -ForegroundColor Green
            Pause-Menu
        }
        "14" {
            $msg = Read-Host "Digite a mensagem para registrar no painel NOC"
            if ($msg) {
                Log-LabEvent -Message "MENSAGEM DE OPERADOR: $msg" -Device "firewall" -Severity 2
                Write-Host "[OK] Mensagem enviada para o widget 'EventLog' na Dashboard!" -ForegroundColor Green
            }
            Pause-Menu
        }
        "15" {
            Write-Host "`n[AÇÃO] Restaurando 100% das condicoes normais (Tudo Verde)..." -ForegroundColor Green
            docker compose start servidor2 2>$null
            docker compose exec -T servidor1 pkill stress-ng 2>$null
            docker compose exec -T servidor1 pkill iperf3 2>$null
            docker compose exec -T servidor2 pkill stress-ng 2>$null
            docker compose exec -T firewall iptables -F FORWARD 2>$null
            docker compose exec -T firewall iptables -P FORWARD ACCEPT 2>$null
            docker compose exec -T firewall tc qdisc del dev eth0 root 2>$null
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>$null
            docker compose exec -T firewall tc qdisc del dev eth2 root 2>$null
            docker compose exec -T servidor2 ip link set eth0 up 2>$null
            docker compose exec -T servidor2 ip link set eth1 up 2>$null
            
            $sql = @"
DELETE FROM alert_faults;
UPDATE alerts SET state = 0, open = 0, alerted = 0;
UPDATE devices SET status = 1, status_reason = '';
UPDATE ports SET ifOperStatus = 'up';
"@
            Execute-SqlSync -Sql $sql
            Log-LabEvent -Message "RESET GERAL: Todo o parque de maquinas esta 100% operacional e saudavel (Tudo Verde)" -Device "firewall" -Severity 1
            Write-Host "[OK] Ambiente 100% normalizado!" -ForegroundColor Green
            Write-Host " -> Todos os blocos do mapa estao VERDES." -ForegroundColor Green
            Write-Host " -> Todos os alertas foram limpos (0 alertas ativos)." -ForegroundColor Green
            Write-Host " -> EventLog registra a normalizacao completa do ambiente." -ForegroundColor Green
            Pause-Menu
        }
    }
} while ($op -ne "0")
