<#
.SYNOPSIS
    Menu Interativo do Laboratorio de Gerencia de Redes
#>
Set-Location $PSScriptRoot

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "      Laboratorio de Gerencia de Redes - Menu Interativo        " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Pause-Menu {
    Write-Host ""
    Read-Host "Pressione [ENTER] para voltar ao menu..."
}

do {
    Show-Header
    Write-Host "  GERAL:" -ForegroundColor Yellow
    Write-Host "   1. Iniciar o laboratorio"
    Write-Host "   2. Exibir status dos containers"
    Write-Host "   3. Exibir dispositivos gerenciados no LibreNMS"
    Write-Host "   4. Acessar a interface web do LibreNMS"
    Write-Host ""
    Write-Host "  FALHAS E DISPONIBILIDADE:" -ForegroundColor Yellow
    Write-Host "   5. Desligar um dispositivo (servidor2)"
    Write-Host "   6. Restabelecer um dispositivo (servidor2)"
    Write-Host "   7. Desativar interface de rede (servidor2 / eth0)"
    Write-Host "   8. Restabelecer interface de rede (servidor2 / eth0)"
    Write-Host ""
    Write-Host "  DESEMPENHO E TRAFEGO:" -ForegroundColor Yellow
    Write-Host "   9. Gerar trafego de rede (servidor1 -> servidor2 via firewall)"
    Write-Host "  10. Simular sobrecarga de CPU (servidor1)"
    Write-Host "  11. Simular sobrecarga de memoria (servidor1)"
    Write-Host "  12. Simular latencia de rede (no firewall: +120ms)"
    Write-Host "  13. Simular perda de pacotes (no firewall: 20% perda)"
    Write-Host ""
    Write-Host "  SEGURANCA E REGISTROS:" -ForegroundColor Yellow
    Write-Host "  14. Simular bloqueio no firewall (DROP HTTP porta 8080)"
    Write-Host "  15. Gerar eventos de seguranca (port scan)"
    Write-Host "  16. Consultar registros (logs do sistema e syslog)"
    Write-Host ""
    Write-Host "  MANUTENCAO:" -ForegroundColor Yellow
    Write-Host "  17. Restabelecer todas as condicoes normais"
    Write-Host "  18. Parar o laboratorio (preserva dados)"
    Write-Host "  19. Restaurar ambiente ao estado inicial (apaga volumes)"
    Write-Host "   0. Sair"
    Write-Host "================================================================" -ForegroundColor Cyan
    
    $op = Read-Host "Selecione uma opcao"

    switch ($op) {
        "1" {
            & "$PSScriptRoot\iniciar.ps1"
            Pause-Menu
        }
        "2" {
            Write-Host "`n[Status dos Containers]" -ForegroundColor Cyan
            docker compose ps
            Pause-Menu
        }
        "3" {
            Write-Host "`n[Dispositivos Gerenciados]" -ForegroundColor Cyan
            docker compose exec -T librenms lnms device:list
            Pause-Menu
        }
        "4" {
            $mapping = docker compose port librenms 8000 2>$null
            if ($LASTEXITCODE -eq 0 -and "$mapping" -match '127\.0\.0\.1:(\d+)$') {
                $url = "http://127.0.0.1:$($Matches[1])"
                Write-Host "Abrindo $url ..." -ForegroundColor Green
                Start-Process $url
            } else {
                Write-Host "O LibreNMS nao esta em execucao. Use a opcao 1 para iniciar." -ForegroundColor Red
            }
            Start-Sleep -Seconds 2
        }
        "5" {
            Write-Host "`nDesligando container servidor2..." -ForegroundColor Yellow
            docker compose stop servidor2
            Write-Host "servidor2 foi desligado com sucesso. Observe a mudanca de estado no LibreNMS." -ForegroundColor Green
            Pause-Menu
        }
        "6" {
            Write-Host "`nIniciando container servidor2..." -ForegroundColor Yellow
            docker compose start servidor2
            Write-Host "servidor2 iniciado com sucesso." -ForegroundColor Green
            Pause-Menu
        }
        "7" {
            Write-Host "`nDesativando interface eth0 em servidor2..." -ForegroundColor Yellow
            docker compose exec -T servidor2 ip link set eth0 down
            Write-Host "Interface eth0 desativada em servidor2." -ForegroundColor Green
            Pause-Menu
        }
        "8" {
            Write-Host "`nRestabelecendo interface eth0 em servidor2..." -ForegroundColor Yellow
            docker compose exec -T servidor2 ip link set eth0 up
            Write-Host "Interface eth0 reativada em servidor2." -ForegroundColor Green
            Pause-Menu
        }
        "9" {
            Write-Host "`nIniciando geracao de trafego iperf3 de servidor1 para servidor2 atraves do firewall..." -ForegroundColor Yellow
            docker compose exec -T -d servidor1 iperf3 -c 172.28.2.10 -t 180 -b 15M
            Write-Host "Trafego de 15 Mbps em geracao por 3 minutos. Acompanhe os graficos de trafego das portas no LibreNMS." -ForegroundColor Green
            Pause-Menu
        }
        "10" {
            Write-Host "`nIniciando stress-ng de CPU em servidor1..." -ForegroundColor Yellow
            docker compose exec -T -d servidor1 stress-ng --cpu 2 --timeout 180s
            Write-Host "Sobrecarga de CPU aplicada por 3 minutos. Acompanhe o grafico de processamento no LibreNMS." -ForegroundColor Green
            Pause-Menu
        }
        "11" {
            Write-Host "`nIniciando stress-ng de memoria em servidor1..." -ForegroundColor Yellow
            docker compose exec -T -d servidor1 stress-ng --vm 1 --vm-bytes 180M --timeout 180s
            Write-Host "Sobrecarga de memoria aplicada por 3 minutos. Acompanhe o consumo de memoria no LibreNMS." -ForegroundColor Green
            Pause-Menu
        }
        "12" {
            Write-Host "`nInjetando latencia de 120ms (+-15ms) no firewall (interface eth1)..." -ForegroundColor Yellow
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem delay 120ms 15ms
            Write-Host "Latencia injetada. Verifique com ping de servidor1 para servidor2 ou pelo LibreNMS." -ForegroundColor Green
            Pause-Menu
        }
        "13" {
            Write-Host "`nInjetando 20% de perda de pacotes no firewall (interface eth1)..." -ForegroundColor Yellow
            docker compose exec -T firewall tc qdisc replace dev eth1 root netem loss 20%
            Write-Host "Perda de pacotes injetada no firewall." -ForegroundColor Green
            Pause-Menu
        }
        "14" {
            Write-Host "`nAplicando regra de firewall para bloquear HTTP (porta 8080)..." -ForegroundColor Yellow
            docker compose exec -T firewall iptables -I FORWARD -p tcp --dport 8080 -j DROP
            Write-Host "Regra aplicada: conexoes HTTP (8080) destinadas a DMZ estao sendo descartadas." -ForegroundColor Green
            Pause-Menu
        }
        "15" {
            Write-Host "`nGerando eventos de seguranca (tentativas de conexao em portas fechadas)..." -ForegroundColor Yellow
            docker compose exec -T servidor1 bash -c "for p in 21 22 23 25 3306 8000; do nc -z -w 1 172.28.2.10 `$p 2>/dev/null || true; done"
            Write-Host "Varredura executada. Verifique os alertas e logs gerados." -ForegroundColor Green
            Pause-Menu
        }
        "16" {
            Write-Host "`n[Ultimos registros de logs do sistema]" -ForegroundColor Cyan
            docker compose logs --tail=30 syslog librenms
            Pause-Menu
        }
        "17" {
            Write-Host "`nRestabelecendo condicoes normais em todos os dispositivos..." -ForegroundColor Yellow
            # Limpa stress-ng
            docker compose exec -T servidor1 pkill stress-ng 2>$null
            docker compose exec -T servidor2 pkill stress-ng 2>$null
            # Limpa regras iptables no firewall
            docker compose exec -T firewall iptables -F FORWARD 2>$null
            docker compose exec -T firewall iptables -P FORWARD ACCEPT 2>$null
            # Remove qdisc netem
            docker compose exec -T firewall tc qdisc del dev eth0 root 2>$null
            docker compose exec -T firewall tc qdisc del dev eth1 root 2>$null
            docker compose exec -T firewall tc qdisc del dev eth2 root 2>$null
            docker compose exec -T servidor2 tc qdisc del dev eth0 root 2>$null
            # Sobe interfaces
            docker compose exec -T servidor1 ip link set eth0 up 2>$null
            docker compose exec -T servidor2 ip link set eth0 up 2>$null
            Write-Host "Todas as condicoes normais foram restabelecidas com sucesso!" -ForegroundColor Green
            Pause-Menu
        }
        "18" {
            Write-Host "`nParando containers do laboratorio..." -ForegroundColor Yellow
            docker compose stop
            Write-Host "Containers parados. Seus dados e configuracoes foram preservados." -ForegroundColor Green
            Pause-Menu
        }
        "19" {
            Write-Host "`n[ATENCAO] Esta operacao removera todos os containers e volumes persistentes!" -ForegroundColor Red
            $conf = Read-Host "Deseja realmente restaurar o ambiente ao estado inicial? (s/N)"
            if ($conf -match '^[sS]') {
                Write-Host "Destruindo ambiente e volumes..." -ForegroundColor Yellow
                docker compose down -v
                Write-Host "Ambiente restaurado ao estado inicial." -ForegroundColor Green
            } else {
                Write-Host "Operacao cancelada." -ForegroundColor Gray
            }
            Pause-Menu
        }
    }
} while ($op -ne "0")
