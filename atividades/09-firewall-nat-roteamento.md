# Laboratório 09 — Firewall, NAT e Roteamento

## 1. Contextualização
Roteadores e Firewalls são os elementos responsáveis por segmentar o tráfego de rede, aplicar políticas de controle de acesso (ACLs) e realizar tradução de endereços de rede (NAT). Em arquiteturas de rede segmentadas, servidores públicos ficam isolados em uma zona desmilitarizada (DMZ), enquanto computadores de usuários residem na rede interna (LAN). Todo o tráfego entre essas redes deve obrigatoriamente inspecionado pelo firewall.

## 2. Objetivos
- Compreender a operação de roteamento estático entre sub-redes distintas.
- Aplicar regras de filtragem de pacotes utilizando `iptables` no container de firewall.
- Simular políticas de bloqueio de serviços específicos (ex: HTTP) e observar a perda de comunicação.
- Monitorar no LibreNMS os contadores de descarte e tráfego decorrentes da atuação do firewall.

## 3. Conceitos Trabalhados
- Segmentação de Redes: LAN, DMZ e Rede de Gerência
- Tabela de Roteamento IPv4 e Encaminhamento (`ip_forward`)
- Mecanismo do Netfilter/iptables: Tabelas `filter` e `nat`, chains `INPUT`, `FORWARD`, `OUTPUT`, `PREROUTING`, `POSTROUTING`
- Filtros com estado (*Stateful Inspection* — conntrack)
- Descarte de pacotes (*DROP* vs. *REJECT*)

## 4. Infraestrutura Utilizada
- `firewall`: Equipamento de borda com interfaces em todas as sub-redes:
  - `eth0` -> `rede-gerencia` (172.28.0.254)
  - `eth1` -> `rede-lan` (172.28.1.254)
  - `eth2` -> `rede-dmz` (172.28.2.254)
- `servidor1`: Cliente na LAN (172.28.1.10), apontando gateway para 172.28.1.254.
- `servidor2`: Servidor Web Nginx na DMZ (172.28.2.10, porta 8080), apontando gateway para 172.28.2.254.

## 5. Procedimentos e Comandos

### Passo 1: Verificar a conectividade e o caminho dos pacotes
A partir de `servidor1`, faça um traceroute para `servidor2`:
```bash
docker compose exec -T servidor1 traceroute -n 172.28.2.10
```
Observe o primeiro salto passando obrigatoriamente pelo endereço `172.28.1.254` (firewall).

Teste o acesso web ao servidor na DMZ:
```bash
docker compose exec -T servidor1 curl -I http://172.28.2.10:8080
```
*(Deve retornar HTTP/1.1 200 OK)*.

### Passo 2: Inspecionar as regras atuais do firewall
No container `firewall`:
```bash
docker compose exec -T firewall iptables -L -n -v
```

### Passo 3: Aplicar regra de bloqueio seletivo (DROP HTTP)
Bloqueie qualquer comunicação TCP direcionada à porta 8080 que atravesse o firewall:
```bash
docker compose exec -T firewall iptables -I FORWARD -p tcp --dport 8080 -j DROP
```

### Passo 4: Testar o efeito do bloqueio
A partir de `servidor1`:
```bash
# O teste de ping continua funcionando?
docker compose exec -T servidor1 ping -c 2 172.28.2.10

# O acesso web na porta 8080 funciona?
docker compose exec -T servidor1 curl -s -m 3 http://172.28.2.10:8080 || echo "Conexao bloqueada pelo firewall com sucesso!"
```
Observe que o ICMP (ping) passa livremente, enquanto o tráfego HTTP é descartado silenciosamente.

Inspecione os contadores de pacotes descartados no firewall:
```bash
docker compose exec -T firewall iptables -L FORWARD -n -v
```

### Passo 5: Restabelecer as regras normais
```bash
docker compose exec -T firewall iptables -F FORWARD
docker compose exec -T firewall iptables -P FORWARD ACCEPT
```

## 6. Experimentos Práticos
1. **Diferença entre DROP e REJECT:**
   - No `firewall`, substitua a regra por `iptables -I FORWARD -p tcp --dport 8080 -j REJECT --reject-with tcp-reset`.
   - Teste novamente com `curl http://172.28.2.10:8080` a partir de `servidor1`.
   - Observe a diferença no tempo de resposta da aplicação cliente (timeout vs. recusa imediata de conexão).
2. **NAT / Masquerade:**
   - Discuta o papel do `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` em conexões que necessitam acessar a Internet.

## 7. Questões para Investigação e Reflexão
1. Por que em políticas corporativas de segurança é recomendada a postura padrão de "tudo que não é expressamente permitido é proibido" (*Default DROP*)?
2. Em termos de segurança de infraestrutura e prevenção de reconhecimento (*reconnaissance*), qual é a vantagem de utilizar `DROP` em vez de `REJECT` para portas não autorizadas?
3. Como o LibreNMS pode ser utilizado para monitorar o volume de tráfego aceito vs. descartado em um firewall de borda?
