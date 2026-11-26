# Laboratório de Gerência de Redes com LibreNMS e Docker

Ambiente didático completo, automatizado e reproduzível para o ensino prático de **Gerência e Monitoramento de Redes** em cursos de Ciência da Computação, Engenharia de Computação e Sistemas de Informação.

O laboratório utiliza ferramentas reais amplamente adotadas no mercado de trabalho — centradas no **LibreNMS** — executadas inteiramente sobre containers Docker, funcionando de forma transparente e idêntica tanto no **Windows** quanto no **Linux**.

---

## 1. Visão Geral e Topologia

O ambiente simula uma infraestrutura corporativa completa e isolada da rede física, segmentada em três redes virtuais distintas interconectadas por um roteador/firewall Linux com suporte a filtragem `iptables`, controle de tráfego com `tc netem`, geração de vazão com `iperf3` e estresse com `stress-ng`:

```
                           +---------------------------------------------+
                           |           REDE-GERENCIA (172.28.0.0/24)      |
                           +--+---------------+----------------+---------+
                              |               |                |
                     +--------+------+ +------+-------+ +------+-------+
                     | LibreNMS Web  | |  Dispatcher  | |   Syslog-NG  |
                     |  172.28.0.10  | |  172.28.0.4  | |  172.28.0.5  |
                     +--------+------+ +--------------+ +--------------+
                              |
             +----------------+----------------+
             |                                 |
             v                                 v
+------------------------+        +------------------------+
|  servidor1 (LAN)       |        |  servidor2 (DMZ - Web) |
|  - Gerência: .0.11     |        |  - Gerência: .0.12     |
|  - LAN:      .1.10     |        |  - DMZ:      .2.10     |
+------------+-----------+        +------------+-----------+
             |                                 |
             | REDE-LAN                        | REDE-DMZ
             | (172.28.1.0/24)                 | (172.28.2.0/24)
             |                                 |
             +------------->+---------------+<-+
                            |   firewall    |
                            |   (Roteador)  |
                            | - Ger.: .0.254|
                            | - LAN:  .1.254|
                            | - DMZ:  .2.254|
                            +---------------+
```

- **Roteamento Real sem Desvios:** O tráfego entre a rede interna (LAN) e a DMZ obrigatoriamente atravessa as interfaces do `firewall`, permitindo exercitar cenários reais de latência, perda de pacotes, bloqueio seletivo de portas e contabilização de tráfego.
- **Rede Out-of-Band (OOB):** O LibreNMS realiza polling SNMP e monitoramento dos dispositivos através de uma sub-rede exclusiva de gerência (`172.28.0.0/24`), seguindo as melhores práticas de arquitetura corporativa.

---

## 2. Requisitos de Sistema

- **Processador:** Intel Core i5 ou equivalente.
- **Memória RAM:** 8 GB recomendados (mínimo de 4 GB livres).
- **Armazenamento:** 5 GB de espaço livre em disco.
- **Software:**
  - **Windows 10/11:** Docker Desktop com backend WSL2 ou Hyper-V ativo.
  - **Linux (Ubuntu, Debian, Fedora, Arch):** Docker Engine e plugin Docker Compose (`docker compose`).

---

## 3. Como Iniciar (Instalação "Zero-Touch / Um Clique")

O laboratório foi projetado para eliminar qualquer atrito de instalação. O aluno apenas executa um script e todo o provisionamento é realizado de forma automática.

### No Windows:
1. Dê um duplo clique no arquivo **`iniciar.bat`** (ou execute via terminal PowerShell / CMD).
2. O script verificará o Docker, buscará portas TCP livres (ex: `18080`), sugerirá a porta e aguardará confirmação:
   - Pressione **[ENTER]** para aceitar a porta recomendada (`18080`) ou digite outra porta de sua preferência.
3. Os containers serão construídos e inicializados automaticamente.
4. O script aguardará a inicialização do banco de dados e do LibreNMS, criará o usuário administrador, cadastrará os dispositivos e **abrirá o navegador automaticamente**.

### No Linux:
Abra o terminal na pasta do projeto e execute:
```bash
bash iniciar.sh
```
Pressione **[ENTER]** para confirmar a porta sugerida e aguarde a abertura automática do navegador.

---

## 4. Dados de Acesso

- **URL da Interface Web:** `http://127.0.0.1:<PORTA>` (padrão: `http://127.0.0.1:18080`)
- **Usuário Administrador:** `admin`
- **Senha:** `GerenciaLab@2026!`
- **Comunidade SNMP:** `laboratorio` (SNMP v2c)
- **Dispositivos Cadastrados:**
  - `firewall` (`172.28.0.254`) — Roteador e Firewall
  - `servidor1` (`172.28.0.11`) — Servidor Linux / Gerador de Carga
  - `servidor2` (`172.28.0.12`) — Servidor Linux / Servidor Web Nginx na porta 8080

---

## 5. Menu Interativo de Simulações

Para facilitar as práticas pedagógicas e os testes dos alunos sem exigir digitação de comandos complexos do Docker, o projeto inclui um menu interativo completo no terminal:

- **No Windows:** Execute `menu.bat`
- **No Linux:** Execute `bash menu.sh`

### Funcionalidades Disponíveis no Menu:
1. **Iniciar o laboratório**
2. **Exibir status dos containers** (`docker compose ps`)
3. **Exibir dispositivos gerenciados no LibreNMS**
4. **Acessar a interface web do LibreNMS** (abre no navegador)
5. **Desligar um dispositivo** (`servidor2`) — Simula queda de servidor
6. **Restabelecer um dispositivo** (`servidor2`)
7. **Desativar interface de rede** (`eth0` em `servidor2`) — Simula falha de link
8. **Restabelecer interface de rede**
9. **Gerar tráfego de rede** (15 Mbps contínuos via `iperf3` entre LAN e DMZ através do firewall)
10. **Simular sobrecarga de CPU** (estresse computacional com `stress-ng` por 3 min)
11. **Simular sobrecarga de memória** (alocação de memória com `stress-ng`)
12. **Simular latência de rede** (injeta 120ms de atraso no firewall com `tc netem`)
13. **Simular perda de pacotes** (injeta 20% de perda no firewall com `tc netem`)
14. **Simular bloqueio no firewall** (regra `iptables` de DROP na porta HTTP 8080)
15. **Gerar eventos de segurança** (varredura de portas com `nc`)
16. **Consultar registros** (logs do sistema e syslog central)
17. **Restabelecer todas as condições normais** (limpa regras de firewall, estresse e latências)
18. **Parar o laboratório** (preserva todos os dados e histórico)
19. **Restaurar ambiente ao estado inicial** (mediante confirmação explícita, recria volumes do zero)
0. **Sair**

---

## 6. Roteiro Pedagógico — 10 Atividades Práticas

As atividades práticas estão organizadas progressivamente na pasta [`atividades/`](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades):

1. [**Laboratório 01 — NMS e Dispositivos Gerenciados**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/01-nms-dispositivos.md): Arquitetura Gerente-Agente, navegação no LibreNMS e inventário.
2. [**Laboratório 02 — SNMP, MIB e OID**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/02-snmp-mib-oid.md): Consultas manuais com `snmpget`, `snmpwalk`, tradução de MIBs e OIDs da RFC 1213.
3. [**Laboratório 03 — Monitoramento Ativo e Passivo**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/03-monitoramento-ativo-passivo.md): Polling vs. SNMP Traps e recepção de mensagens no Syslog central.
4. [**Laboratório 04 — Gerenciamento de Falhas (Fault Management)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/04-gerenciamento-falhas.md): Simulação de queda de nós (*Device Down*) e interfaces (*Port Down*).
5. [**Laboratório 05 — Gerenciamento de Desempenho (Performance Management)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/05-gerenciamento-desempenho.md): Saturação de vazão (`iperf3`), carga de CPU/memória (`stress-ng`) e degradação com `tc netem`.
6. [**Laboratório 06 — Gerenciamento de Contabilização (Accounting Management)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/06-gerenciamento-contabilizacao.md): Contadores de 32 vs 64 bits, estouro de contadores (*counter wrap*) e tarifação por 95º percentil.
7. [**Laboratório 07 — Gerenciamento de Configuração (Configuration Management)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/07-gerenciamento-configuracao.md): Rastreamento de inventário, alterações de parâmetros e auditoria de rotas.
8. [**Laboratório 08 — Gerenciamento de Segurança (Security Management)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/08-gerenciamento-seguranca.md): Fragilidades do SNMP v2c (captura com `tcpdump`), SNMP v3 e varreduras de portas.
9. [**Laboratório 09 — Firewall, NAT e Roteamento**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/09-firewall-nat-roteamento.md): Filtragem com `iptables`, regras FORWARD, descarte silencioso (*DROP*) vs. rejeição (*REJECT*).
10. [**Laboratório 10 — Investigação de Incidentes de Rede (Troubleshooting)**](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/10-investigacao-incidentes.md): Resolução de incidentes reais complexos com elaboração de relatório de Análise de Causa Raiz (RCA).

---

## 7. Procedimentos de Manutenção e Recuperação

- **Parar o Laboratório:** Execute `parar.bat` (Windows) ou `bash parar.sh` (Linux). Seus dados e históricos nos gráficos serão preservados.
- **Reabrir a Interface:** Execute `abrir.bat` ou utilize a opção 4 do `menu.bat`.
- **Reconfigurar / Reprovisionar:** Caso deseje forçar a sincronização de usuários e dispositivos, execute `configurar.bat` ou `bash configurar.sh`.
- **Restaurar ao Estado Inicial (Limpeza Completa):**
  Para recomeçar do zero, utilize a opção 19 do `menu.bat` ou execute:
  ```bash
  docker compose down -v
  ```

---

## 8. Licença

Este projeto é disponibilizado sob a licença de código aberto **GNU General Public License v3.0 (GPL-3.0)**. Consulte o arquivo [LICENSE](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/LICENSE) para mais detalhes.
