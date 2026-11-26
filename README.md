# Laboratório de Gerência de Redes com LibreNMS e Docker

> ### 📖 Sobre a Construção do Projeto e Créditos
> Este projeto foi desenvolvido e estruturado a partir de:
> - **Referências nos conteúdos e ensinamentos do saudoso Professor Claudio Correa**, grande referência na área de redes e infraestrutura;
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

### Comandos Rápidos

| Ação | Windows | Linux |
| :--- | :--- | :--- |
| **Iniciar o laboratório** | Duplo clique em `iniciar.bat` | `bash iniciar.sh` |
| **Menu interativo de simulações** | Duplo clique em `menu.bat` | `bash menu.sh` |
| **Parar containers** | Duplo clique em `parar.bat` | `bash parar.sh` |
| **Reprovisionar / Recriar admin** | Duplo clique em `configurar.bat` | `bash configurar.sh` |

---

### Atividades e Práticas de Laboratório
- **Prática Avaliada Oficial (5,0 Pontos):** [atividades/pratica-avaliada-5-pontos.md](file:///c:/Users/Diego/Documents/ProjetosGIT/laboratorio-gerencia-redes-nms/atividades/pratica-avaliada-5-pontos.md)
  *(Roteiro direto com 5 questões de execução e anotação, com gabarito rápido para correção).*
- **Roteiros Guiados de Estudo:** Pasta `atividades/` (10 roteiros cobrindo o modelo FCAPS).
