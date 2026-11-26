# Laboratório 06 — Gerenciamento de Contabilização (Accounting Management)

## 1. Contextualização
O gerenciamento de contabilização no modelo FCAPS destina-se a medir a utilização dos recursos por usuários ou departamentos para fins de auditoria, faturamento, rateio de custos e dimensionamento de capacidade (*capacity planning*). Em provedores de tráfego de Internet (ISPs) e datacenters, técnicas como o cálculo do 95º percentil (*95th Percentile*) são amplamente empregadas.

## 2. Objetivos
- Compreender como contadores SNMP de bytes (`ifInOctets` e `ifOutOctets`) são acumulados e transformados em taxas de bits por segundo.
- Explorar o módulo de faturamento (*Billing*) do LibreNMS.
- Calcular o volume total de tráfego transferido entre sub-redes em um intervalo de tempo.
- Compreender a diferença entre medição por volume (Gigabytes) e por percentil (Mbps).

## 3. Conceitos Trabalhados
- Modelo FCAPS — Dimensão Contabilização
- Contadores de 32 bits (`ifInOctets`) vs. 64 bits (`ifHCInOctets`)
- *Counter Wrap* (estouro de contadores em interfaces de alta velocidade)
- Métodos de tarifação: Volume Total vs. Vazão de Pico vs. 95º Percentil

## 4. Infraestrutura Utilizada
- `librenms` (módulo de Billing).
- `firewall` (ponto de medição do tráfego entre LAN e DMZ).
- `servidor1` e `servidor2` (gerador e receptor de volume de dados).

## 5. Procedimentos e Comandos

### Passo 1: Inspecionar os contadores de bytes nas interfaces
No `firewall`, consulte os contadores de bytes de 32 bits e 64 bits da interface `eth1`:
```bash
# Contador de 32 bits
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.254 IF-MIB::ifInOctets.3

# Contador de 64 bits (High Capacity)
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.254 IF-MIB::ifHCInOctets.3
```

### Passo 2: Gerar uma transferência com volume conhecido
Transfira exatamente 50 Megabytes de dados entre `servidor1` e `servidor2` via `iperf3`:
```bash
docker compose exec -T servidor1 iperf3 -c 172.28.2.10 -n 50M
```

### Passo 3: Recalcular a variação dos contadores
Execute novamente o `snmpget`:
```bash
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.254 IF-MIB::ifHCInOctets.3
```
Calcule a diferença ($\Delta$) entre as duas leituras e converta para Megabytes:
$$\text{Volume (MB)} = \frac{\text{Contador Final} - \text{Contador Inicial}}{1024 \times 1024}$$
Verifique a precisão do contador em relação aos 50 MB transmitidos pelo iperf3.

### Passo 4: Explorar o módulo de Billing no LibreNMS
1. No menu do LibreNMS, vá para **Ports -> Traffic Bills** ou configure um novo plano de faturamento.
2. Associe a porta `eth1` do `firewall` a um medidor de tráfego com cota de tráfego ou cálculo de percentil.

## 6. Experimentos Práticos
1. **Problema do Estouro de Contadores (*Counter Wrap*):**
   - Um contador de 32 bits pode armazenar no máximo $2^{32} - 1 = 4.294.967.295$ octetos (aproximadamente 4,29 GB).
   - Em um enlace de 10 Gbps operando em capacidade máxima, em quantos segundos o contador de 32 bits atinge o valor máximo e retorna a zero?
   - Por que o uso de `ifHCInOctets` (64 bits) é obrigatório em redes modernas?

## 7. Questões para Investigação e Reflexão
1. Qual a metodologia matemática por trás do cálculo de cobrança pelo 95º percentil? Por que provedores de trânsito IP descartam os 5% maiores picos de tráfego do cliente no mês?
2. Se um administrador realizar polling a cada 5 minutos em uma interface saturada cujo contador estourou e deu uma volta completa no intervalo, como o NMS calcula o tráfego? Que erro pode ocorrer?
3. De que forma o módulo de faturamento (*Billing*) do LibreNMS pode ser utilizado para controle interno de custos em uma organização privada?
