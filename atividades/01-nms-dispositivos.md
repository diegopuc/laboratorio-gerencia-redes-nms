# Laboratório 01 — NMS e Dispositivos Gerenciados

## 1. Contextualização
Um Sistema de Gerenciamento de Rede (*Network Management System* — NMS) é a peça central para a visibilidade, governança e manutenção da infraestrutura de TI corporativa. Em redes modernas, administradores monitoram centenas ou milhares de nós de forma centralizada. Neste laboratório, exploraremos a arquitetura do LibreNMS, compreendendo o papel do gerente, dos agentes e dos dispositivos gerenciados.

## 2. Objetivos
- Compreender a arquitetura de gerenciamento de redes centralizada (Gerente vs. Agente).
- Navegar na interface web do LibreNMS e reconhecer os dispositivos descobertos.
- Investigar o inventário de hardware, sistema operacional e interfaces de rede.
- Entender como o NMS organiza os dados e descobre a topologia simulada.

## 3. Conceitos Trabalhados
- NMS (*Network Management System*)
- Entidade Gerente e Entidade Agente
- Base de Informações de Gerenciamento (MIB / Inventário)
- Descoberta (*Discovery*) e Mapeamento de Topologia
- Modelo Cliente-Servidor no Gerenciamento

## 4. Infraestrutura Utilizada
- **LibreNMS (Gerente):** Container central executando serviço web, poller e dispatcher (`172.28.0.10`).
- **Dispositivos Gerenciados (Agentes):**
  - `firewall`: Roteador e firewall de borda (`172.28.0.254`, `172.28.1.254`, `172.28.2.254`).
  - `servidor1`: Servidor Linux da sub-rede LAN (`172.28.0.11`, `172.28.1.10`).
  - `servidor2`: Servidor Linux Web na sub-rede DMZ (`172.28.0.12`, `172.28.2.10`).
- **Redes Virtuais:** `rede-gerencia` (172.28.0.0/24), `rede-lan` (172.28.1.0/24), `rede-dmz` (172.28.2.0/24).

## 5. Procedimentos e Comandos

### Passo 1: Verificar status dos nós gerenciados via terminal
No terminal do computador hospedeiro:
```bash
docker compose ps
docker compose exec -T librenms lnms device:list
```

### Passo 2: Acessar a interface web
Abra o navegador no endereço exibido pelo script de inicialização (`http://127.0.0.1:<PORTA>`).
- **Usuário:** `admin`
- **Senha:** `GerenciaLab@2026!`

### Passo 3: Explorar o menu Dispositivos (Devices)
1. Navegue até o menu superior: **Devices -> All Devices**.
2. Observe a lista contendo `firewall`, `servidor1` e `servidor2`.
3. Clique em `servidor2`:
   - Verifique a versão do Sistema Operacional (Alpine Linux).
   - Verifique o tempo de atividade (*Uptime*).
   - Inspecione a aba **Ports** para visualizar as interfaces de rede identificadas (`eth0`, `eth1`, etc.).
   - Inspecione a aba **Health** (Processador e Memória).

## 6. Experimentos Práticos
1. **Verificação de Out-of-Band (OOB) Management:**
   - Observe os endereços IP associados a cada dispositivo na aba de visão geral.
   - Note que o LibreNMS comunica-se com todos os dispositivos através da `rede-gerencia` (172.28.0.0/24).
2. **Consulta direta via CLI ao inventário do NMS:**
   Execute no terminal para consultar a tabela de dispositivos cadastrados no banco de dados do LibreNMS:
   ```bash
   docker compose exec -T librenms mariadb -h db -u librenms -plab-db-local librenms -e "SELECT device_id, hostname, sysName, os, version, uptime FROM devices;"
   ```

## 7. Questões para Investigação e Reflexão
1. Qual a diferença fundamental entre uma rede de gerenciamento *In-Band* e uma rede *Out-of-Band* (OOB)? Qual arquitetura foi adotada neste laboratório e quais as vantagens de segurança e confiabilidade dessa abordagem?
2. Ao inspecionar o dispositivo `firewall`, quantas interfaces de rede foram identificadas pelo LibreNMS? Qual o papel de cada uma delas na topologia?
3. Se um novo servidor for adicionado à rede, quais são os requisitos necessários para que o LibreNMS possa monitorá-lo com sucesso?
