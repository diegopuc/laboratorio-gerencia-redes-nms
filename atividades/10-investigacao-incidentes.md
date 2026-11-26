# Laboratório 10 — Investigação de Incidentes de Rede (Troubleshooting)

## 1. Contextualização
No cotidiano dos profissionais de infraestrutura e operações de rede (NOC / SRE), problemas complexos raramente vêm acompanhados de uma explicação simples. Falhas intermitentes, lentidão percebida pelos usuários e degradação de serviços exigem raciocínio investigativo, correlação de evidências e aplicação de método científico de resolução de problemas (*Troubleshooting*).

## 2. Objetivos
- Desenvolver habilidades práticas de diagnóstico e isolamento de problemas de rede.
- Interpretar sintomas e indicadores fornecidos pela interface do LibreNMS.
- Investigar múltiplos incidentes simulados:
  1. Incidente 1: Queda silenciosa de serviço web em nó operacional.
  2. Incidente 2: Degradação severa de desempenho por perda de pacotes e latência induzida.
  3. Incidente 3: Bloqueio indevido por política de segurança de firewall.
- Elaborar um relatório sintético de análise de causa raiz (*Root Cause Analysis* — RCA).

## 3. Conceitos Trabalhados
- Metodologia de Troubleshooting baseada no Modelo OSI (Bottom-up, Top-down, Divide-and-Conquer)
- Análise de Causa Raiz (*Root Cause Analysis* — RCA)
- Correlação de Indicadores (Métricas RRD, Eventlogs, Syslog)
- Ferramentas de diagnóstico: `ping`, `traceroute`, `curl`, `tcpdump`, `netstat`, `iptables`, `tc`

## 4. Infraestrutura Utilizada
- Toda a topologia do laboratório: `librenms`, `firewall`, `servidor1`, `servidor2`.

## 5. Roteiro dos Incidentes de Investigação

---

### Incidente 1: "O site interno está fora do ar, mas o servidor responde ao ping!"
**Cenário Injetado:**
No terminal, execute:
```bash
docker compose exec -T servidor2 pkill nginx
```
**Missão do Aluno:**
1. A partir de `servidor1`, execute `curl http://172.28.2.10:8080`. O que ocorre?
2. Execute `ping 172.28.2.10`. O que você observa?
3. No LibreNMS, abra a página de `servidor2`:
   - O dispositivo é considerado UP ou DOWN pelo NMS? Por quê?
   - Como um administrador pode configurar o LibreNMS para detectar falhas no processo Nginx ou na porta 8080 através do módulo **Services**?
4. **Resolução:** Reative o Nginx em `servidor2`:
   ```bash
   docker compose exec -T servidor2 nginx
   ```

---

### Incidente 2: "Chamadas de API e transferências de arquivos estão extremamente lentas!"
**Cenário Injetado:**
No terminal, aplique degradação combinada no firewall:
```bash
docker compose exec -T firewall tc qdisc replace dev eth1 root netem delay 150ms loss 15%
```
**Missão do Aluno:**
1. Tente realizar um teste de vazão de `servidor1` para `servidor2`:
   ```bash
   docker compose exec -T servidor1 iperf3 -c 172.28.2.10 -t 10
   ```
2. Realize um teste de ICMP:
   ```bash
   docker compose exec -T servidor1 ping -c 10 172.28.2.10
   ```
   Calcule a perda percentual e o RTT médio obtido.
3. No LibreNMS, abra o gráfico de latência (*Ping Response*) do `firewall` e de `servidor2`. O que os gráficos revelam?
4. **Resolução:** Normalize a interface do firewall:
   ```bash
   docker compose exec -T firewall tc qdisc del dev eth1 root
   ```

---

### Incidente 3: "Após uma manutenção, os alunos da LAN não conseguem mais acessar a DMZ!"
**Cenário Injetado:**
No terminal, aplique:
```bash
docker compose exec -T firewall iptables -I FORWARD -s 172.28.1.10 -d 172.28.2.10 -j DROP
```
**Missão do Aluno:**
1. Execute `traceroute` e `curl` de `servidor1` para `servidor2`. Em qual salto a comunicação é interrompida?
2. Inspecione as regras de firewall no roteador central:
   ```bash
   docker compose exec -T firewall iptables -L FORWARD -n -v --line-numbers
   ```
3. Identifique o número da linha da regra incorreta e remova-a:
   ```bash
   docker compose exec -T firewall iptables -D FORWARD 1
   ```
4. Confirme o restabelecimento da conectividade.

---

## 6. Modelo de Relatório de Análise de Causa Raiz (RCA)
Para cada um dos três incidentes investigados, documente no seu relatório individual:
1. **Descrição do Sintoma:** O que o usuário relatou?
2. **Evidências Coletadas:** Quais saídas de comandos e gráficos do LibreNMS comprovaram o problema?
3. **Causa Raiz Identificada:** Qual foi a origem técnica exata da falha?
4. **Ação Corretiva Implementada:** Qual comando solucionou a falha?
5. **Recomendação Preventiva:** Como evitar que esse problema ocorra novamente em ambiente de produção?

## 7. Questões Finais de Integração
1. Por que monitorar apenas a disponibilidade por Ping (Camada 3) é insuficiente para garantir a qualidade de entrega de aplicações aos usuários?
2. Como uma equipe de operações de redes pode usar os dados históricos do LibreNMS para prever esgotamento de capacidade antes que ele ocorra?
