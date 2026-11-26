# Laboratório de Gerência de Redes — LibreNMS

Ambiente didático local com Docker Compose, LibreNMS, MariaDB, Redis, dispatcher, syslog e três dispositivos Linux com SNMP. Não requer VM dedicada. No Windows, requer Docker com containers Linux e backend suportado; confirme a licença do Docker Desktop ou use Docker Engine em Linux.

## Iniciar

Windows: execute `iniciar.bat`. Linux: `bash iniciar.sh`. A primeira execução requer Internet para baixar imagens e pacotes. O script lista até dez portas TCP livres entre 18080 e 18180 e solicita uma porta (1024–65535). A escolha é validada e salva automaticamente em `.env`. Aguarde a resposta HTTP e acesse o endereço informado pelo script. No Linux, são necessários `ss` (iproute2) e `curl`. Caso apareça o instalador, finalize-o (banco `db`, usuário e banco `librenms`, senha `lab-db-local`). Crie um administrador. Execute `configurar.bat` ou `bash configurar.sh` para tentar cadastrar os dispositivos pela CLI. Se a versão da CLI divergir, use Devices > Add Device, hostname `servidor1`, `servidor2` e `firewall`, SNMP v2c, comunidade `laboratorio`, porta 161. As credenciais propostas são exclusivamente didáticas. Não exponha o ambiente na rede física.

## Operação

Execute `menu.bat` ou `bash menu.sh` para simular incidentes. Os dados são persistidos em volumes. `docker compose down` preserva os dados; `docker compose down -v` apaga todos os dados deste projeto, inclusive cadastro e histórico. Não execute este último comando sem desejar reiniciar do zero.

## Topologia

Todos os serviços estão em uma rede bridge privada do projeto. O container firewall é um endpoint Linux para exercícios de filtragem local, não um gateway entre sub-redes. Os nomes DNS internos são usados no cadastro dos dispositivos. Não é feita descoberta da rede física. O acesso Web é publicado somente em loopback. SNMP e syslog não são publicados no host.

## Atividades

Consulte a pasta atividades. Aguarde pelo menos dois ciclos de polling (normalmente 5 minutos cada) para comparar gráficos. O agente Net-SNMP em container pode apresentar métricas do kernel compartilhado, não necessariamente métricas limitadas ao container; compare com `docker stats`.

## Diagnóstico

- `docker compose ps` e `docker compose logs --tail=100 librenms dispatcher db`
- `docker compose exec librenms lnms device:add --help`
- `docker compose exec librenms lnms user:add --help`
- `docker compose exec servidor1 snmpwalk -v2c -c laboratorio servidor2 .1.3.6.1.2.1.1`
- Para trocar a porta, pare o laboratório (`docker compose down`) e execute novamente o script de início. Não apague os volumes. A verificação de portas é local e não reserva a porta até o Docker iniciar; se houver conflito nesse intervalo, execute novamente. Use Docker local, não um contexto remoto. Consulte a porta efetivamente publicada com `docker compose port librenms 8000`.
- A imagem LibreNMS usa tag latest; após homologação, fixe a tag ou digest em `.env` com LIBRENMS_IMAGE para reproduzir a mesma versão.

## Referências

- https://github.com/librenms/docker
- https://docs.librenms.org/

## Estado da validação

Projeto revisado estaticamente; a nova seleção de portas ainda não foi homologada em Docker ou Windows. Homologue em um computador antes de distribuir. A criação automática de usuários/dispositivos depende da versão e do estado da instalação; o cadastro manual é o caminho alternativo.
