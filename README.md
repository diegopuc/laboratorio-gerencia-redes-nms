# Laboratório de Gerência de Redes com LibreNMS e Docker

> ### 📖 Sobre a Construção do Projeto e Créditos
> Este projeto foi desenvolvido e estruturado a partir de:
> - **Referências nos conteúdos e ensinamentos do saudoso Professor Claudio Correa**, grande mestre e referência na área de redes e infraestrutura;
> - **Pesquisas técnicas e documentações autorais** elaboradas para o ensino prático de redes;
> - **Uso de Inteligência Artificial Generativa sob constante supervisão, curadoria, refinamento e validação técnica do autor**.

---

## Dados de Acesso Rápido

### Interface Web (LibreNMS)
- **URL:** [http://127.0.0.1:18080/login](http://127.0.0.1:18080/login) *(ou na porta definida ao subir)*
- **Usuário:** `admin`
- **Senha:** `admin`

---

### Configurações SNMP
- **Versão SNMP:** `v2c`
- **Comunidade (Community):** `laboratorio`
- **Dispositivos Pré-cadastrados:**
  - **`firewall`** (`172.28.0.254`) — Roteador e Firewall Linux
  - **`servidor1`** (`172.28.0.11`) — Servidor Linux na LAN / Gerador de Carga
  - **`servidor2`** (`172.28.0.12`) — Servidor Linux na DMZ (Nginx porta 8080)
  - **Portal Web DMZ via Firewall NAT:** [http://127.0.0.1:18088](http://127.0.0.1:18088)

---

### Comandos de Execução (Pasta `scripts/`)

| Ação | Windows | Linux / macOS |
| :--- | :--- | :--- |
| **Iniciar o laboratório** | Duplo clique em `scripts/iniciar.bat` | `bash scripts/iniciar.sh` |
| **Menu interativo de simulações** | Duplo clique em `scripts/menu.bat` | `bash scripts/menu.sh` |
| **Parar containers** | Duplo clique em `scripts/parar.bat` | `bash scripts/parar.sh` |
| **Reprovisionar / Recriar admin** | Duplo clique em `scripts/configurar.bat` | `bash scripts/configurar.sh` |

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

- **Processador:** Intel Core i3/i5 ou equivalente.
- **Memória RAM:** 8 GB recomendados (mínimo de 4 GB livres).
- **Armazenamento:** 5 GB de espaço livre em disco.
- **Software:**
  - **Windows 10/11:** Docker Desktop com backend WSL2 ou Hyper-V ativo.
  - **Linux (Ubuntu, Debian, Fedora, Arch):** Docker Engine e plugin Docker Compose (`docker compose`).

---

## 3. Menu de Controle e Simulações em Tempo Real

Execute `scripts/menu.bat` (Windows) ou `bash scripts/menu.sh` (Linux) para gerenciar o ambiente e executar as simulações em tempo real:

```text
  GERENCIAMENTO E INICIALIZACAO DO AMBIENTE:
   1. Iniciar / Configurar o Laboratorio (Zerar do zero, escolher porta e subir)
   2. Acessar a Interface Web do LibreNMS no Navegador (Dashboard NOC)
   3. Exibir status dos containers Docker (docker compose ps)
   4. Parar containers do laboratorio (Preserva dados)
   5. Restaurar ambiente ao estado inicial virgem (Apaga volumes do zero)

  SIMULAÇÕES NOC (DASHBOARD EM TEMPO REAL):
   6. [AVAILABILITY MAP] Desligar servidor2 (Bloco 'servidor2' fica VERMELHO no mapa)
   7. [AVAILABILITY MAP] Ligar servidor2 (Bloco 'servidor2' volta para VERDE no mapa)
   8. [PORT SUMMARY] Desativar placa eth1 do servidor2 (Aumenta 'Down' em Ports)
   9. [PORT SUMMARY] Reativar placa eth1 do servidor2 (Zera 'Down' em Ports)
  10. [ALERTA CPU] Provocar pico de 100% de CPU em servidor1 (Acende alerta no quadro)
  11. [NORMALIZAR CPU] Parar estresse de CPU (Remove alerta do quadro)
  12. [ALERTA LINK] Injetar 25% de perda de pacotes (Acende alerta de latencia/perda)
  13. [NORMALIZAR LINK] Remover perda de pacotes do link (Remove alerta do quadro)
  14. [EVENTLOG] Enviar mensagem personalizada de operador para a Dashboard
  15. [RESET GERAL] Restaurar tudo para 100% Normal e Saudavel (Tudo Verde / Sem Alertas)
   0. Sair
```

---

## 4. Licença

Este projeto é disponibilizado sob a licença de código aberto **GNU General Public License v3.0 (GPL-3.0)**. Consulte o arquivo [LICENSE](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/LICENSE) para mais detalhes.
