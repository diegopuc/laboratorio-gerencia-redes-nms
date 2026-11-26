# Laboratório 05 — Gerenciamento de Desempenho (Performance Management)

## 1. Contextualização
O gerenciamento de desempenho visa quantificar, monitorar e otimizar o comportamento dos recursos de rede e dos sistemas operacionais (CPU, memória, tráfego de interface, latência, perda de pacotes e descarte de quadros). O objetivo é garantir que o desempenho atenda aos acordos de nível de serviço (SLA) contratados.

## 2. Objetivos
- Coletar e interpretar métricas de vazão (*throughput*), utilização de CPU e memória.
- Gerar tráfego artificial saturando enlaces de rede com a ferramenta `iperf3`.
- Injetar estresse computacional com `stress-ng` e analisar o reflexo nos gráficos RRD.
- Medir a degradação de desempenho por latência e perda de pacotes com `tc netem`.

## 3. Conceitos Trabalhados
- Modelo FCAPS — Dimensão Desempenho
- Taxa de transferência (*Throughput*) e largura de banda
- Utilização de CPU e saturação de memória RAM
- Atraso (*Delay* / Latência) e Jitter
- Ferramentas de benchmarking e estresse: `iperf3`, `stress-ng`, `netem`

## 4. Infraestrutura Utilizada
- `servidor1`: Origem do tráfego de teste e gerador de estresse.
- `firewall`: Ponto intermediário de roteamento e injeção de atraso/perda.
- `servidor2`: Destino do tráfego (`iperf3 -s`).
- `librenms`: Coletor e renderizador de gráficos RRD.

## 5. Procedimentos e Comandos

### Passo 1: Simular sobrecarga de processamento (CPU)
No `servidor1`, execute o `stress-ng` para consumir 100% dos núcleos de CPU por 3 minutos:
```bash
docker compose exec -T -d servidor1 stress-ng --cpu 2 --timeout 180s
```
Acompanhe via terminal a carga no próprio host ou consulte via SNMP:
```bash
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.11 .1.3.6.1.4.1.2021.10.1.3
```
No LibreNMS, abra a página de `servidor1` -> aba **Health -> Processors** e visualize a curva ascendente no gráfico.

### Passo 2: Gerar tráfego de rede saturado (15 Mbps contínuos)
Dispare uma sessão de geração de tráfego UDP de `servidor1` para `servidor2`:
```bash
docker compose exec -T -d servidor1 iperf3 -c 172.28.2.10 -u -b 15M -t 180
```
- Observe que este tráfego atravessa o container `firewall`.
- Abra o LibreNMS no dispositivo `firewall` -> aba **Ports**.
- Localize as interfaces `eth1` (rede LAN) e `eth2` (rede DMZ): veja que o gráfico de saída de uma corresponde exatamente ao gráfico de entrada da outra!

### Passo 3: Injeção de Latência com Traffic Control (tc netem)
No `firewall`, injete um atraso de 120ms na interface conectada à LAN:
```bash
docker compose exec -T firewall tc qdisc replace dev eth1 root netem delay 120ms 15ms
```
Teste o ping entre `servidor1` e `servidor2`:
```bash
docker compose exec -T servidor1 ping -c 4 172.28.2.10
```
*(Observe o tempo de resposta passando de <1ms para ~120ms)*.

### Passo 4: Normalização
Remova as emulações de rede:
```bash
docker compose exec -T firewall tc qdisc del dev eth1 root 2>/dev/null || true
docker compose exec -T servidor1 pkill stress-ng 2>/dev/null || true
```

## 6. Experimentos Práticos
1. **Impacto na Vazão TCP:**
   Com a latência de 120ms ativa, execute um teste de vazão TCP com `iperf3 -c 172.28.2.10 -t 10`. Compare o resultado obtido com o teste sem latência e explique por que a latência afeta o throughput do protocolo TCP (janela deslizante / BDP).
2. **Injeção de Perda de Pacotes:**
   Aplique 20% de perda com `tc qdisc replace dev eth1 root netem loss 20%` e observe o comportamento de uma requisição HTTP (`curl http://172.28.2.10:8080`).

## 7. Questões para Investigação e Reflexão
1. O que é RRD (*Round Robin Database*) e por que sistemas NMS como o LibreNMS utilizam esse formato de banco de dados para armazenar métricas de desempenho em vez de bancos relacionais comuns?
2. Como a taxa de amostragem (frequência de polling) afeta a precisão da detecção de picos de tráfego (*microbursts*) na rede?
3. O que é o produto banda-retardo (*Bandwidth-Delay Product* — BDP) e como ele influencia a vazão de redes de alta latência?
