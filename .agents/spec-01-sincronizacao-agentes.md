# Projeto: Laboratório de Gerência de Redes com LibreNMS e Docker

## 1. Contextualização

Sou professor universitário da disciplina de Gerência de Redes do curso de Ciência da Computação. Pretendo desenvolver um laboratório prático que permita aos alunos estudar gerenciamento e monitoramento de redes utilizando ferramentas reais, adotadas no mercado de trabalho.

Os computadores do laboratório possuem a seguinte configuração:

- Processador Intel Core i5;
- 16 GB de memória RAM;
- 150 GB de armazenamento.

Não é possível utilizar máquinas virtuais dedicadas. Toda a infraestrutura deverá ser executada utilizando Docker e Docker Compose.

O projeto deverá funcionar tanto no Windows quanto no Linux.

## 2. Objetivo

Desenvolver um laboratório completo de gerenciamento de redes utilizando LibreNMS, permitindo que os alunos estudem, configurem, monitorem e investiguem problemas em uma infraestrutura de rede simulada por containers.

A ferramenta deverá ser gratuita, de código aberto e não possuir limitações comerciais relacionadas à quantidade de dispositivos monitorados.

O projeto será disponibilizado em um repositório público no GitHub e deverá possuir instalação simples, automatizada e reproduzível.

## 3. Requisitos do ambiente

Utilizar, preferencialmente:

- LibreNMS;
- MariaDB;
- Redis;
- LibreNMS Dispatcher;
- Syslog;
- SNMP Trap;
- Net-SNMP;
- Docker Compose;
- Linux;
- iptables;
- iperf3;
- stress-ng;
- iproute2;
- tc netem;
- Nginx;
- Ferramentas de diagnóstico de redes.

Avaliar a necessidade de cada componente, evitando serviços desnecessários e consumo excessivo de recursos.

Utilizar imagens oficiais sempre que possível.

## 4. Infraestrutura simulada

Criar uma infraestrutura contendo:

- Sistema central de gerenciamento LibreNMS;
- Servidores Linux;
- Servidor web;
- Roteador Linux;
- Firewall;
- Agentes SNMP;
- Redes virtuais;
- Dispositivos capazes de gerar e receber tráfego.

Quando houver múltiplas sub-redes, garantir que o tráfego efetivamente atravesse os roteadores e firewalls simulados, sem utilizar caminhos alternativos criados automaticamente pelo Docker.

Todos os experimentos deverão ocorrer dentro do ambiente virtual, sem interferir na infraestrutura física da instituição.

## 5. Automatização da instalação

O objetivo é que os alunos precisem apenas baixar ou clonar o repositório e executar um script.

Disponibilizar scripts compatíveis com Windows e Linux:

- iniciar.bat;
- iniciar.ps1, se necessário;
- iniciar.sh;
- parar.bat;
- parar.sh;
- menu.bat;
- menu.sh;
- configurar.bat;
- configurar.sh.

Os scripts deverão:

1. Verificar se o Docker está instalado e em execução.
2. Verificar a disponibilidade do Docker Compose.
3. Identificar portas TCP disponíveis no computador.
4. Apresentar uma lista de portas livres no terminal.
5. Solicitar que o usuário digite a porta desejada.
6. Validar a disponibilidade da porta escolhida.
7. Solicitar outra porta caso esteja ocupada ou seja inválida.
8. Criar ou atualizar automaticamente o arquivo .env, caso necessário.
9. Baixar as imagens Docker.
10. Construir as imagens dos dispositivos simulados.
11. Criar redes e volumes.
12. Inicializar os containers.
13. Aguardar a inicialização efetiva dos serviços.
14. Configurar o LibreNMS.
15. Criar o usuário administrador, preferencialmente de forma automatizada.
16. Cadastrar os dispositivos gerenciados.
17. Configurar os agentes SNMP.
18. Configurar a base_url conforme a porta escolhida.
19. Confirmar a porta efetivamente publicada pelo Docker.
20. Abrir o navegador somente após confirmar que o LibreNMS está disponível.

Não utilizar endereços fixos nos scripts de abertura do navegador.

A porta interna do LibreNMS deverá permanecer 8000. A porta externa deverá ser selecionada pelo usuário.

Restringir a publicação da interface web ao endereço 127.0.0.1, por padrão.

## 6. Menu interativo

Disponibilizar um menu no terminal que permita:

- Iniciar o laboratório;
- Exibir o status dos containers;
- Exibir os dispositivos gerenciados;
- Desligar um dispositivo;
- Restabelecer um dispositivo;
- Desativar uma interface de rede;
- Restabelecer uma interface;
- Gerar tráfego de rede;
- Simular sobrecarga de CPU;
- Simular sobrecarga de memória;
- Simular latência;
- Simular perda de pacotes;
- Simular bloqueios de comunicação;
- Gerar eventos de segurança;
- Consultar registros;
- Restabelecer as condições normais;
- Acessar a interface web do LibreNMS;
- Parar o laboratório;
- Restaurar o ambiente ao estado inicial, mediante confirmação.

As simulações deverão ser reais, executadas nos containers, e não apenas mensagens apresentadas no terminal.

Também deverá ser possível realizar todos os experimentos manualmente por meio de comandos Docker e Linux.

## 7. Conteúdos pedagógicos

O laboratório deverá permitir trabalhar os seguintes conteúdos:

### Fundamentos de gerenciamento de redes

- Network Management System (NMS);
- Gerenciadores;
- Agentes;
- Dispositivos gerenciados;
- Arquitetura de gerenciamento;
- Inventário de dispositivos;
- Descoberta de dispositivos;
- Topologia de rede.

### SNMP

- SNMP v1, v2c e v3;
- MIB;
- OID;
- Polling;
- SNMP GET;
- SNMP WALK;
- SNMP Trap;
- Monitoramento de interfaces;
- Monitoramento ativo e passivo.

### Modelo FCAPS

- Fault Management — gerenciamento de falhas;
- Configuration Management — gerenciamento de configuração;
- Accounting Management — gerenciamento de contabilização;
- Performance Management — gerenciamento de desempenho;
- Security Management — gerenciamento de segurança.

Identificar quais funcionalidades são atendidas diretamente pelo LibreNMS e quais necessitam de ferramentas complementares. Não atribuir ao LibreNMS funcionalidades que ele não possui.

### Redes e segurança

- IPv4 e IPv6;
- Interfaces de rede;
- Roteamento;
- ICMP;
- TCP e UDP;
- Firewall;
- iptables;
- NAT;
- SNAT;
- DNAT;
- MASQUERADE;
- Syslog;
- Disponibilidade;
- Latência;
- Throughput;
- Perda de pacotes;
- Alertas e eventos.

## 8. Atividades práticas

Criar atividades práticas em arquivos Markdown, organizadas progressivamente.

Sugestão:

- Laboratório 01 — NMS e dispositivos gerenciados;
- Laboratório 02 — SNMP, MIB e OID;
- Laboratório 03 — Monitoramento ativo e passivo;
- Laboratório 04 — Gerenciamento de falhas;
- Laboratório 05 — Gerenciamento de desempenho;
- Laboratório 06 — Gerenciamento de contabilização;
- Laboratório 07 — Gerenciamento de configuração;
- Laboratório 08 — Gerenciamento de segurança;
- Laboratório 09 — Firewall e NAT;
- Laboratório 10 — Investigação de incidentes de rede.

Cada atividade deverá apresentar:

- Contextualização;
- Objetivos;
- Conceitos trabalhados;
- Infraestrutura utilizada;
- Procedimentos;
- Comandos necessários;
- Experimentos;
- Questões para investigação e reflexão.

As atividades não deverão se limitar à execução mecânica de comandos. O aluno deverá interpretar os indicadores, investigar problemas, relacionar evidências e propor soluções.

## 9. Problemas identificados na implementação atual

Já existe uma versão do projeto, que deverá ser analisada e corrigida.

### Problema 1 — Conflito de portas

A porta 8000 estava ocupada por outro serviço.

Erro apresentado:

```
Error response from daemon:
Bind for 0.0.0.0:8000 failed:
port is already allocated
```

Além disso, mesmo após alterar o mapeamento de portas, um dos scripts abriu o navegador na porta 8000, direcionando o usuário para outra aplicação.

Foi proposta a seguinte configuração:

```yaml
librenms:
  <<: *nms
  hostname: librenms
  ports: ["127.0.0.1:${LIBRENMS_PORT:-18080}:8000"]
```

Revisar todos os scripts para garantir que o endereço aberto corresponda à porta efetivamente publicada pelo Docker.

### Problema 2 — Senha administrativa

A senha inicialmente definida foi rejeitada pelo LibreNMS.

Mensagem:

```
The given password has appeared in a data leak.
Please choose a different password.
```

Implementar uma solução adequada para criação do usuário administrador, preferencialmente solicitando uma senha ao usuário ou gerando uma senha forte durante a instalação.

Não utilizar senhas administrativas fracas ou credenciais reais no repositório público.

### Problema 3 — Dependências Python

A ferramenta de validação do LibreNMS apresenta:

```
Python
FAIL: Python3 module issue found: ''
Fix:
pip3 install -r /opt/librenms/requirements.txt
```

Investigar a causa real do problema considerando a imagem Docker oficial.

Não aplicar correções destinadas a instalações convencionais diretamente no sistema operacional hospedeiro.

Caso seja necessária uma imagem personalizada, implementar a correção de forma persistente em um Dockerfile.

### Problema 4 — Scheduler

A ferramenta de validação apresenta:

```
Scheduler
FAIL: Scheduler is not running
Fix:
sudo cp /opt/librenms/dist/librenms-scheduler.cron /etc/cron.d/
```

O projeto já possui um container Dispatcher, mas é necessário verificar se está configurado corretamente e se o agendador exigido pelo LibreNMS está em execução.

Investigar a diferença entre Dispatcher, polling e Laravel Scheduler.

Não assumir que a existência do Dispatcher resolve automaticamente o problema.

### Problema 5 — Atualizações

A ferramenta de validação apresenta:

```
Updates
WARN: Non-git install, updates are manual or from package
```

Verificar se esse aviso é esperado na instalação oficial por Docker.

Documentar o procedimento correto de atualização das imagens.

Não tentar eliminar avisos que sejam normais para instalações em containers.

### Problema 6 — Base URL

A ferramenta de validação apresenta:

```
Web Server
WARN: base_url could be more specific
Fix:
lnms config:set base_url http://127.0.0.1:18080
```

Automatizar a configuração da base_url conforme a porta escolhida pelo usuário.

### Problema 7 — Versionamento das imagens

A implementação atual utiliza imagens como:

- librenms/librenms:latest;
- mariadb:12;
- redis:7.2-alpine.

Verificar a compatibilidade entre as versões utilizadas.

Preferir versões estáveis e explicitamente identificadas, evitando alterações inesperadas durante o semestre.

## 10. Qualidade da implementação

O projeto deverá possuir:

- Organização adequada dos arquivos;
- Scripts legíveis;
- Tratamento de erros;
- Validação dos serviços;
- Healthchecks quando aplicáveis;
- Persistência de dados;
- Idempotência dos scripts de configuração;
- Compatibilidade com Windows e Linux;
- Baixo consumo de recursos;
- Documentação em português do Brasil;
- Arquivo .gitignore;
- Arquivo .gitattributes;
- README.md;
- Licença de código aberto adequada;
- Procedimentos de atualização;
- Procedimentos de recuperação;
- Procedimentos de remoção;
- Orientações para resolução de problemas.

Garantir que executar novamente o script de inicialização não provoque duplicação de usuários, dispositivos ou configurações.

Não excluir volumes ou dados persistidos sem autorização explícita do usuário.

## 11. Validação técnica

Antes de entregar o projeto:

- Consultar a documentação oficial atualizada do LibreNMS.
- Consultar o repositório Docker oficial.
- Verificar as configurações oficiais dos serviços auxiliares.
- Verificar a compatibilidade entre as imagens.
- Validar a sintaxe YAML.
- Validar os scripts Bash.
- Validar os scripts PowerShell.
- Validar os scripts Batch.
- Verificar os comandos de administração do LibreNMS.
- Verificar a comunicação SNMP.
- Verificar o funcionamento do Dispatcher.
- Verificar o funcionamento do Scheduler.
- Verificar a disponibilidade da interface web.
- Verificar a persistência dos dados.
- Verificar a seleção dinâmica de portas.
- Verificar a integridade do projeto.

Caso seja possível executar Docker no ambiente de desenvolvimento, realizar testes reais de inicialização e funcionamento.

Caso não seja possível, informar explicitamente quais testes foram realizados e quais ainda precisam ser executados.

Não afirmar que uma funcionalidade foi testada quando apenas foi implementada ou analisada estaticamente.

## 12. Entrega

Analisar o projeto ZIP anexado e aproveitar os componentes que estiverem corretos.

Corrigir os problemas existentes, completar as funcionalidades necessárias e entregar uma nova versão integral do projeto em um único arquivo ZIP, pronta para publicação no GitHub.

Não entregar apenas trechos de código, exemplos de configuração ou sugestões de implementação.

Entregar todos os arquivos necessários para a execução do laboratório.

Priorizar simplicidade, estabilidade, facilidade de utilização e aplicabilidade pedagógica.

O objetivo final é que o aluno execute um único script, escolha uma porta disponível e tenha acesso a um ambiente funcional de gerenciamento de redes, sem precisar corrigir manualmente dependências, serviços ou configurações do LibreNMS durante a aula.