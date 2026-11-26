# Laboratório 08 — Gerenciamento de Segurança (Security Management)

## 1. Contextualização
A dimensão de segurança do modelo FCAPS trata do controle de acesso aos recursos de rede, proteção das comunicações de gerenciamento, geração e análise de registros de segurança (Syslog) e detecção de atividades anômalas ou não autorizadas na rede.

## 2. Objetivos
- Identificar as fraquezas de segurança do SNMP v1 e v2c.
- Compreender os mecanismos de proteção do SNMP v3 (autenticação criptográfica e privacidade).
- Simular varreduras de portas e tentativas de conexão suspeitas.
- Analisar os alertas de segurança gerados e correlacionar eventos no Syslog do LibreNMS.

## 3. Conceitos Trabalhados
- Modelo FCAPS — Dimensão Segurança
- Protocolo SNMP v3 (USM — *User-based Security Model*: noAuthNoPriv, authNoPriv, authPriv)
- Algoritmos criptográficos: SHA-256 (Autenticação) e AES-128 (Privacidade/Cifra)
- Coleta e análise de Syslog de segurança
- Detecção de varreduras de portas (*Port Scanning*)

## 4. Infraestrutura Utilizada
- `librenms` com coletor Syslog central.
- `servidor1` (simulando origem de tráfego de varredura).
- `firewall` e `servidor2` (alvos de monitoramento e alvos de segurança).

## 5. Procedimentos e Comandos

### Passo 1: Capturar pacotes SNMP em trânsito
Para demonstrar a fragilidade do SNMP v2c, vamos inspecionar uma consulta SNMP trafegando na rede de gerência usando `tcpdump` no container `librenms`:
Em um terminal (ou executando via exec):
```bash
docker compose exec -T librenms tcpdump -i eth0 -n -c 4 -X port 161 &
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.11 sysName.0
```
Observe na saída em hexadecimal/ASCII que a comunidade `laboratorio` trafega em **texto claro** (*plaintext*), permitindo que qualquer atacante capture a senha com um analisador de pacotes.

### Passo 2: Simular uma varredura de portas (Port Scan)
A partir de `servidor1`, execute uma varredura simulada de portas TCP no `servidor2`:
```bash
docker compose exec -T servidor1 bash -c "for p in 21 22 23 25 80 443 8080 3306; do nc -z -w 1 172.28.2.10 \$p 2>/dev/null && echo \"Porta \$p: ABERTA\" || echo \"Porta \$p: FECHADA\"; done"
```

### Passo 3: Envio de eventos de auditoria de segurança para o Syslog
Simule o registro de múltiplos acessos negados por firewall enviados para o LibreNMS:
```bash
docker compose exec -T firewall logger -n 172.28.0.5 -P 514 -p auth.alert -t IPTABLES "DROP: Tentativa de conexao na porta 23 (Telnet) originada de 172.28.1.10"
```

### Passo 4: Verificar no painel de alertas do LibreNMS
1. No navegador, acesse **Alerts -> Syslog**.
2. Filtre pelas mensagens de severidade `Alert` ou busque pelo programa `IPTABLES`.
3. Verifique a associação da mensagem ao nó `firewall`.

## 6. Experimentos Práticos
1. **Configuração de SNMP v3 (Teoria e Prática):**
   - No SNMP v3, usuários são definidos com credenciais individuais.
   - Analise os três níveis de segurança:
     1. `noAuthNoPriv`: Sem autenticação, sem criptografia (apenas validação por username).
     2. `authNoPriv`: Autenticação via hash (MD5 ou SHA), dados trafegam em claro.
     3. `authPriv`: Autenticação (SHA) e criptografia simétrica do payload (AES ou DES).
2. **Restrição por Endereço IP de Origem:**
   - Inspecione o arquivo `/etc/snmp/snmpd.conf` nos dispositivos e avalie como restringir para que apenas o IP `172.28.0.10` (LibreNMS) possa realizar consultas SNMP.

## 7. Questões para Investigação e Reflexão
1. Se um invasor conseguir adivinhar ou capturar a comunidade de leitura (`rocommunity`) de um equipamento de rede, que tipos de informações sensíveis ele pode obter?
2. Por que o envio de logs via Syslog em texto puro e UDP na porta 514 não é adequado para conformidade de segurança (ex: PCI-DSS, ISO 27001)? Quais são os protocolos seguros recomendados (ex: TLS / RFC 5425)?
3. Como o NMS pode ser utilizado de forma integrada a um SIEM (*Security Information and Event Management*)?
