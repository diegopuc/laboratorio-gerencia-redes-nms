# Laboratório 03 — Monitoramento Ativo e Passivo

## 1. Contextualização
O monitoramento de infraestrutura pode ser categorizado em duas abordagens fundamentais:
- **Monitoramento Ativo (Polling):** O gerente periodicamente envia requisições (como ICMP Ping ou SNMP GET) para verificar a disponibilidade e coletar métricas.
- **Monitoramento Passivo (Traps / Syslog):** O próprio dispositivo gerenciado notifica o gerente de forma imediata e assíncrona quando ocorre um evento relevante (ex: queda de link, reinicialização ou falha de login).

## 2. Objetivos
- Compreender a diferença prática entre monitoramento ativo e passivo.
- Observar os ciclos de polling (*intervalo de coleta*) e seu impacto no tempo de detecção de eventos.
- Gerar eventos assíncronos (SNMP Traps e Syslog) e capturá-los no NMS.
- Analisar a relação entre consumo de largura de banda e frequência de polling.

## 3. Conceitos Trabalhados
- Polling (Sondagem periódica)
- ICMP Echo Request / Reply (Fast Ping)
- SNMP Traps e SNMP Inform (Porta 162/udp)
- Syslog (RFC 5424 / Porta 514/udp)
- Latência de detecção de falhas

## 4. Infraestrutura Utilizada
- `librenms` (Serviço Web e Poller).
- `syslog` (Sidecar Syslog-ng integrado ao LibreNMS na porta 514).
- Dispositivos simulados (`servidor1`, `servidor2`, `firewall`).

## 5. Procedimentos e Comandos

### Passo 1: Analisar o ciclo de polling ativo
No LibreNMS, o ciclo padrão de polling de métricas completas é de 300 segundos (5 minutos), enquanto o teste de disponibilidade por Ping ocorre a cada 60 segundos.
Para forçar um ciclo imediato de polling ativo e inspecionar a troca de mensagens:
```bash
docker compose exec -T --user librenms librenms php /opt/librenms/poller.php -h servidor1 -d
```
Observe a saída em modo debug (`-d`): cada OID consultado, o tempo de resposta e o armazenamento dos dados em arquivos RRD.

### Passo 2: Envio de mensagem Syslog (Monitoramento Passivo)
Vamos simular o envio de um registro de log direto de `servidor1` para o coletor central de syslog do LibreNMS:
```bash
docker compose exec -T servidor1 logger -n 172.28.0.5 -P 514 -t SEC_ALERT "Falha de autenticacao: multiplas tentativas invalidas para o usuario root"
```

### Passo 3: Envio manual de SNMP Trap (Monitoramento Passivo)
Dispare uma notificação assíncrona (Trap) do `servidor2` para o LibreNMS notificando uma alteração no estado de uma interface:
```bash
docker compose exec -T servidor2 snmptrap -v2c -c laboratorio 172.28.0.10:162 "" IF-MIB::linkDown IF-MIB::ifIndex.1 i 1 IF-MIB::ifAdminStatus.1 i 2 IF-MIB::ifOperStatus.1 i 2
```

## 6. Experimentos Práticos
1. **Verificação no LibreNMS:**
   - Acesse a interface web do LibreNMS.
   - Navegue até **Overview -> Eventlog** e **Alerts -> Syslog**.
   - Localize a mensagem enviada pelo comando `logger`.
   - Observe como a informação chegou instantaneamente, sem necessidade de aguardar o ciclo de polling do NMS.
2. **Comparação de Carga de Rede:**
   - Calcule quantos pacotes uma estação NMS geraria para monitorar 1.000 interfaces a cada 60 segundos usando polling ativo versus aguardar notificações passivas (traps).

## 7. Questões para Investigação e Reflexão
1. Quais são as principais vantagens e desvantagens do monitoramento ativo em comparação ao monitoramento passivo?
2. Em um cenário onde a conexão entre o dispositivo e o NMS for interrompida, o que acontece com as mensagens de SNMP Trap enviadas pelo protocolo UDP? Como contornar esse problema?
3. Como o LibreNMS combina o monitoramento ativo e passivo para oferecer alta confiabilidade operacional?
