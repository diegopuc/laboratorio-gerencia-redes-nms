# Laboratório 02 — SNMP, MIB e OID

## 1. Contextualização
O protocolo SNMP (*Simple Network Management Protocol*) é o padrão da indústria para comunicação entre estações de gerenciamento e equipamentos de rede. Para que o gerente compreenda os dados fornecidos pelo agente, utiliza-se uma estrutura hierárquica padronizada chamada MIB (*Management Information Base*), na qual cada dado possui um identificador unívoco: o OID (*Object Identifier*).

## 2. Objetivos
- Compreender a operação e sintaxe do protocolo SNMP (v2c).
- Executar comandos manuais `snmpget`, `snmpwalk` e `snmptranslate`.
- Identificar OIDs canônicos da árvore MIB (RFC 1213 / MIB-II).
- Compreender a relação entre a consulta SNMP pura e os gráficos gerados pelo LibreNMS.

## 3. Conceitos Trabalhados
- Protocolo SNMP v1, v2c e v3
- Comunidades SNMP (*Community Strings*)
- Árvore MIB e identificadores OID
- Operações SNMP: GET, GETNEXT, WALK
- Variáveis escalares e tabulares

## 4. Infraestrutura Utilizada
- Container `librenms` (atuando como cliente SNMP / console de consulta).
- Containers `servidor1`, `servidor2` e `firewall` executando agente Net-SNMP (porta 161/udp).
- Comunidade configurada: `laboratorio`.

## 5. Procedimentos e Comandos

### Passo 1: Executar consulta SNMP GET pontual
A partir do container `librenms`, consulte o nome do sistema (`sysName.0`) e a descrição (`sysDescr.0`) do `servidor1`:
```bash
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.11 sysName.0
docker compose exec -T librenms snmpget -v2c -c laboratorio 172.28.0.11 sysDescr.0
```

### Passo 2: Traduzir nomes textuais para OIDs numéricos
O SNMP trafega OIDs numéricos na rede. O comando `snmptranslate` permite converter entre formatos:
```bash
docker compose exec -T librenms snmptranslate -On SNMPv2-MIB::sysDescr.0
docker compose exec -T librenms snmptranslate -On RFC1213-MIB::ifDescr
```

### Passo 3: Consultar variáveis tabulares com SNMP WALK
A tabela de interfaces de rede (`ifTable`) armazena informações sobre todas as interfaces de um dispositivo. Vamos varrer a tabela no `firewall`:
```bash
# Nomes das interfaces
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.254 ifDescr

# Status operacional (1 = Up, 2 = Down)
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.254 ifOperStatus

# Contadores de bytes de entrada (inOctets)
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.254 ifInOctets
```

### Passo 4: Consultar métricas de CPU e Memória
```bash
# Carga de CPU (UCD-SNMP-MIB)
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.11 1.3.6.1.4.1.2021.10.1.3

# Memória total e disponível
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.11 1.3.6.1.4.1.2021.4
```

## 6. Experimentos Práticos
1. **Teste de Comunidade Incorreta:**
   Execute uma consulta com uma comunidade inexistente (ex: `errada`):
   ```bash
   docker compose exec -T librenms snmpget -v2c -c errada 172.28.0.11 sysName.0
   ```
   Observe o comportamento do comando (Timeout) e explique a ausência de mensagem explícita de "senha incorreta" no protocolo SNMP v2c.
2. **Comparação com o LibreNMS:**
   Abra a interface web do LibreNMS, vá até `servidor1` -> **Ports** e compare o valor de tráfego exibido com o contador `ifInOctets` e `ifOutOctets` consultado manualmente via CLI.

## 7. Questões para Investigação e Reflexão
1. Por que o SNMP utiliza o protocolo de transporte UDP (porta 161) em vez do TCP? Quais os impactos dessa escolha no desempenho do gerenciamento em redes congestionadas?
2. O que representa o OID `.1.3.6.1.2.1` na hierarquia da MIB?
3. Qual é a vulnerabilidade inerente ao uso do SNMP v2c com comunidades em texto claro e como o SNMP v3 resolve essa deficiência?
