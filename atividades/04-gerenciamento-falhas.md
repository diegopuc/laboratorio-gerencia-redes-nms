# Laboratório 04 — Gerenciamento de Falhas (Fault Management)

## 1. Contextualização
O gerenciamento de falhas é a primeira área funcional do modelo FCAPS (*Fault, Configuration, Accounting, Performance, Security*). Seu objetivo é detectar, isolar, notificar e corrigir anomalias na infraestrutura antes que causem impacto severo aos usuários finais. Neste laboratório, simularemos cenários reais de queda de enlace e paradas completas de servidores.

## 2. Objetivos
- Configurar e compreender regras de alerta de disponibilidade no LibreNMS.
- Simular a queda total de um nó da rede (*Device Down*).
- Simular a perda de conectividade de uma interface específica (*Port Down*).
- Avaliar a correlação de eventos e o tempo de recuperação (*Mean Time to Recovery* — MTTR).

## 3. Conceitos Trabalhados
- Modelo FCAPS — Dimensão Falhas
- Detecção de indisponibilidade (ICMP Echo e SNMP Poller)
- Estados de portas: `AdminStatus` vs. `OperStatus`
- Regras de alerta, severidade e notificações
- Resolução e mitigação de incidentes

## 4. Infraestrutura Utilizada
- Container `librenms` (motor de alertas e painel de controle).
- Container `servidor2` (servidor de aplicação e alvo das simulações).

## 5. Procedimentos e Comandos

### Passo 1: Verificar o estado inicial de servidor2
Na interface web do LibreNMS (**Devices -> All Devices**), certifique-se de que `servidor2` está verde (Up).

### Passo 2: Simular queda total do dispositivo (Device Down)
No terminal ou através da opção 5 do menu interativo:
```bash
docker compose stop servidor2
```

Aguarde o ciclo de verificação ou force a verificação via terminal:
```bash
docker compose exec -T --user librenms librenms php /opt/librenms/poller.php -h servidor2
```
Acesse a interface web:
- Observe a mudança de cor do dispositivo para vermelho.
- Acesse **Alerts -> Notifications** ou o painel principal (*Dashboard*) e veja o alerta de dispositivo inacessível.

### Passo 3: Restabelecer o dispositivo
```bash
docker compose start servidor2
docker compose exec -T --user librenms librenms php /opt/librenms/poller.php -h servidor2
```
Verifique a normalização do status no painel do LibreNMS.

### Passo 4: Simular queda parcial — Interface de Rede (Port Down)
Muitas vezes o servidor continua ligado, mas um cabo é desconectado ou uma interface falha:
```bash
# Derruba a interface eth0 do servidor2 (rede de dados)
docker compose exec -T servidor2 ip link set eth0 down
```
Consulte o status via SNMP:
```bash
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.12 IF-MIB::ifOperStatus.2
```
*(Valor 1 indica UP; valor 2 indica DOWN)*.

### Passo 5: Recuperar a interface de rede
```bash
docker compose exec -T servidor2 ip link set eth0 up
```

## 6. Experimentos Práticos
1. **Impacto na Aplicação Web:**
   Enquanto a interface `eth0` de `servidor2` estiver desativada, tente acessar a aplicação web hospedada a partir de `servidor1`:
   ```bash
   docker compose exec -T servidor1 curl -s -m 2 http://172.28.2.10:8080 || echo "Conexao falhou conforme esperado."
   ```
2. **Inspeção de EventLog:**
   Acesse **Overview -> Eventlog** no LibreNMS e analise o registro cronológico das transições de estado de `servidor2`.

## 7. Questões para Investigação e Reflexão
1. Qual a diferença entre `ifAdminStatus` e `ifOperStatus` em uma interface de rede? O que significa quando `ifAdminStatus` está UP e `ifOperStatus` está DOWN?
2. Em um ambiente de produção com 500 roteadores, como o NMS pode evitar a "tempestade de alertas" (*alert storm*) quando um roteador central cai e torna todos os dispositivos atrás dele inacessíveis?
3. Como o LibreNMS diferencia uma falha do agente SNMP de uma queda física do equipamento?
