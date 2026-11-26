# Laboratório 07 — Gerenciamento de Configuração (Configuration Management)

## 1. Contextualização
O gerenciamento de configuração é responsável por inicializar, rastrear, alterar e manter o inventário e os parâmetros operacionais dos dispositivos de rede. Mudanças não documentadas ou configurações incorretas são causas primárias de falhas e brechas de segurança em ambientes corporativos.

## 2. Objetivos
- Avaliar os parâmetros de configuração registrados pelo LibreNMS.
- Investigar como alterações de software e serviços em execução são refletidas no NMS.
- Entender a relação entre controle de configuração, gerência de versões e inventário dinâmico.
- Mapear a topologia e as portas físicas/lógicas ativas nos equipamentos.

## 3. Conceitos Trabalhados
- Modelo FCAPS — Dimensão Configuração
- Linhas de base (*Configuration Baselines*)
- Gerência de Mudanças e Auditoria de Configuração
- Mapeamento de portas e serviços abertos via SNMP
- Descoberta automática de módulos e software

## 4. Infraestrutura Utilizada
- `librenms` (NMS).
- `servidor1` e `servidor2` (servidores com serviços dinâmicos).
- `firewall` (roteador e controle de rotas).

## 5. Procedimentos e Comandos

### Passo 1: Inspecionar o inventário de pacotes e sistema
No LibreNMS, abra o `servidor2` e inspecione:
- **System:** Versão do kernel, hostname, localização física configurada no SNMP (`sysLocation`).
- **Software / Packages:** Lista de pacotes e aplicações detectadas pelo LibreNMS.

### Passo 2: Alterar a configuração SNMP do dispositivo
No `servidor2`, modifique o arquivo de configuração do agente SNMP `/etc/snmp/snmpd.conf`:
```bash
docker compose exec -T servidor2 sed -i 's/sysLocation .*/sysLocation Datacenter 01 - Rack 04/' /etc/snmp/snmpd.conf
# Reinicia o snmpd para aplicar a nova configuração
docker compose exec -T servidor2 pkill -HUP snmpd
```

### Passo 3: Forçar nova descoberta no LibreNMS
Execute o script de descoberta para que o LibreNMS colete as novas propriedades do dispositivo:
```bash
docker compose exec -T --user librenms librenms php /opt/librenms/discovery.php -h servidor2
```
Atualize a página no navegador e confirme a alteração de localização para `Datacenter 01 - Rack 04`.

### Passo 4: Mapear serviços TCP em escuta
Consulte a tabela de conexões TCP via MIB no `servidor2`:
```bash
docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.12 TCP-MIB::tcpListenerLocalPort
```
Identifique as portas em escuta (ex: 8080 para Nginx, 5201 para iperf3).

## 6. Experimentos Práticos
1. **Auditoria de Rotas no Roteador/Firewall:**
   Consulte a tabela de roteamento IP do `firewall` através da MIB:
   ```bash
   docker compose exec -T librenms snmpwalk -v2c -c laboratorio 172.28.0.254 IP-FORWARD-MIB::inetCidrRouteDest
   ```
   Compare os prefixos retornados com a configuração real das sub-redes (`172.28.0.0/24`, `172.28.1.0/24`, `172.28.2.0/24`).

## 7. Questões para Investigação e Reflexão
1. Quais os riscos de segurança de manter a comunidade SNMP de leitura/escrita (`rwcommunity`) ativa em dispositivos de produção?
2. Como uma ferramenta de gerenciamento de configuração automatizada (como Ansible ou Oxidized integrado ao LibreNMS) complementa o monitoramento SNMP?
3. Se um administrador alterar uma rota ou regra de firewall no container sem atualizar o script ou Dockerfile, o que acontecerá quando o container for recriado? O que é o conceito de infraestrutura como código (IaC)?
