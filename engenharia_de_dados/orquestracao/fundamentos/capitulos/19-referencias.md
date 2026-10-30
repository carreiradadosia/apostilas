---
title: "Referências, Fontes verificadas (2026-10-29) e Reconferência na 3.4.0"
date: 2026-10-29
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - orquestracao
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Anterior: 18. Glossário](18-glossario.md)

## Referências

De onde veio cada afirmação desta apostila? Daqui. Referência é a documentação oficial que você abre para conferir o que leu. Memória não conta como fonte, nem a nossa.

O Airflow muda rápido. Um exemplo: no Airflow 3 o catchup vem desligado, e material escrito antes dizia que vinha ligado. Outro: o `schedule_interval` do Airflow 2 foi removido no 3. Por isso cada linha abaixo traz URL e data de consulta. Se a data ficou velha, confira de novo antes de repetir a afirmação.

Vamos ver como usar esta lista na prática:

1. Achou uma afirmação na apostila que parece estranha? Procure o tema abaixo.
2. Abra a URL e confira se a doc ainda diz o mesmo.
3. Mudou? Avise o mentor. Conteúdo errado publicado como certo é pior que conteúdo ausente.

O equívoco comum é confiar no primeiro tutorial que aparece na busca. Tutorial escrito para o Airflow 2 pode ensinar padrões que o 3 removeu, como `schedule_interval`, SubDAG, SLA e `execution_date`.

### Documentação oficial principal

Todas consultadas em 2026-10-29: Airflow na versão 3.3.2 e PostgreSQL na 16.

- Apresentação do Airflow. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- Conceitos centrais. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Referência de configuração. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Execução da Dag (Dag run) e catchup. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- Reprocessamento de datas passadas (backfill). https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- Boas práticas. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Fuso horário. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Timetable. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timetable.html
- Migração para o Airflow 3. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- Notas de versão. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- Docker Compose oficial. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- UPSERT no PostgreSQL. https://www.postgresql.org/docs/16/sql-insert.html

## Fontes verificadas (2026-10-29)

Uma linha por afirmação factual que sustenta os capítulos, agrupadas por fonte. A data de consulta de todas é 2026-10-29.

### Apache Airflow 3.3.2

- O Airflow é uma plataforma para orquestrar fluxos em lote, com início e fim claros, disparados por tempo ou por evento. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- Fluxo como código traz versionamento, trabalho em equipe e teste; pela interface se dispara Dag, lê log, faz backfill e roda de novo só as tarefas que falharam. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- A seção "Why not Airflow?" diz que, para quem prefere clicar a programar, ele talvez não seja a melhor escolha. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- A Dag não se importa com o que acontece dentro das tarefas, só com como executá-las: ordem, tentativas, tempo limite. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dags.html ; https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- O termo vem do grafo dirigido acíclico, mas o sentido no Airflow foi além da estrutura de dados, e por isso a documentação adotou "Dag". https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dags.html
- A Dag define as dependências e, com elas, a ordem; por padrão, uma tarefa espera todas as anteriores terminarem com sucesso. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Operadores e sensores são modelos, e chamá-los numa Dag cria uma tarefa; `@task` empacota uma função Python como tarefa. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Sensor é o operador que só espera um evento externo. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Peças de uma instalação: scheduler, Dag processor, API server e banco de metadados; o executor é propriedade de configuração do scheduler e roda dentro do processo dele. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Passar o retorno de uma tarefa para outra define a dependência e leva o valor por XCom; decorators e `DAG` vêm de `airflow.sdk`, e os operadores Python, do provider standard. https://airflow.apache.org/docs/apache-airflow/3.3.2/tutorial/taskflow.html
- Caminho ideal de uma instância de tarefa (`none`, `scheduled`, `queued`, `running`, `success`) e os estados `up_for_retry` e `upstream_failed`, entre outros. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/tasks.html
- `AirflowFailException` marca a tarefa como falha e ignora as tentativas restantes; as políticas de nova tentativa decidem entre RETRY, FAIL e DEFAULT e não passam do máximo configurado. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/tasks.html
- Dag run é uma instância da Dag no tempo; o estado da execução vem das tarefas folha, e uma folha com `all_done` pode deixar a execução em sucesso com falha antes dela. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- Catchup cria uma execução por intervalo não executado; limpar uma tarefa a faz rodar de novo, pela interface ou por `airflow tasks clear`. A mesma página ainda explica datas pelo modelo de intervalo e manda disparar com `-e`, o que não vale para a 3.3.2. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- XCom serve para pouco dado, nunca para a tabela inteira ou um dataframe; é limpo a cada nova tentativa e não guarda estado entre tentativas. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/xcoms.html
- O `LocalExecutor` roda as tarefas como subprocessos do scheduler, limitados pelo `parallelism`; em contêiner isso pode parecer memória alta do scheduler, e a documentação manda ajustar o `parallelism` ao limite do contêiner. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/executor/local.html
- Padrões de configuração: executor `LocalExecutor`, `parallelism` 32, `dags_are_paused_at_creation` True, `catchup_by_default` False e `default_timezone` UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O padrão do Airflow 3 é não tentar de novo (`default_task_retries` 0, ajustável na Dag ou na tarefa), e nenhuma tarefa tem tempo limite (`default_task_execution_timeout` vazio). https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- `create_cron_data_intervals` vem False, e a agenda cron vira `CronTriggerTimetable`. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Sem limite, até 16 execuções da mesma Dag rodam juntas (`max_active_runs_per_dag`). https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O Dag processor procura arquivos novos a cada 300 s (`refresh_interval`), e `min_file_process_interval` vale 30 s. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O tempo limite padrão do sensor é de 604800 s, 7 dias (`[sensors] default_timeout`), e `[operators] default_deferrable` vem false. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Desde a 3.2.0, `dag_version_inflation_check_level` vem em `warning` e avisa sobre versões infladas da Dag. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- A opção `rerun_with_latest_version` está na referência de configuração e chegou na 3.3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html ; https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- O Airflow guarda datas em UTC por dentro e no banco, e `default_timezone` vem `utc`, o recomendado; mesmo num fuso só, é boa prática guardar dado em UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Data sem fuso recebe o fuso padrão, e o `start_date` deve levar fuso, criado com `pendulum`; cron com fuso segue o horário local. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Templates entregam datas com fuso, sem converter para o horário local, e cabe à Dag tratar isso; a página diz, em dois trechos, que a interface mostra UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- O timetable de disparo não tem janela de dados, e início e fim são iguais; com `interval=`, a janela tem essa duração e termina no disparo; com catchup desligado, os dias do período pausado não rodam. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timetable.html
- Na migração para o 3, quem depende de `data_interval_start` e `data_interval_end` pode ligar `create_cron_data_intervals=True` antes do upgrade ou declarar `interval=`; mudar a configuração depois de existirem execuções no 3 pula uma execução agendada; a janela do disparo manual depende do timetable e do caminho do disparo. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- `ds` é a data lógica da execução no formato AAAA-MM-DD e só existe quando a execução tem data lógica. https://airflow.apache.org/docs/apache-airflow/3.3.2/templates-ref.html
- `start_date` dinâmico confunde o agendamento: no Airflow 3 ele gera versão nova da Dag a cada leitura do arquivo; a correção é data fixa. https://airflow.apache.org/docs/apache-airflow/3.3.2/faq.html
- O FAQ ainda explica `ds` pelo modelo de intervalo e diz que a agenda padrão é de um dia. https://airflow.apache.org/docs/apache-airflow/3.3.2/faq.html
- Uma Dag pode rodar quando uma tarefa atualiza um dado (asset), e o asset só é marcado como atualizado se a tarefa terminar com sucesso. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/asset-scheduling.html
- O disparo por evento externo existe desde a 3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/event-scheduling.html
- Backfill cria execuções de datas passadas e não faz sentido sem agenda por tempo; com catchup ligado, o scheduler cria uma execução para cada intervalo não executado. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- O backfill tem os comportamentos de reprocessamento `none`, `failed` e `completed`; execução ainda em running ou queued não ganha outra, qualquer que seja a opção; o `max_active_runs` do backfill vale à parte do da Dag. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- O backfill tem ensaio com `--dry-run`, que imprime as datas consideradas. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- Só um backfill fica aberto por Dag: um segundo pedido logo depois foi recusado com a mensagem "There can be only one running backfill per Dag". Executado em ambiente descartável, Airflow 3.3.2, 2026-10-29.
- `airflow backfill create` tem `--from-date` e `--to-date` como início e fim inclusivos, `--dry-run`, `--max-active-runs` e `--reprocess-behavior` com padrão `none`; `airflow dags trigger` aceita `-l/--logical-date`. https://airflow.apache.org/docs/apache-airflow/3.3.2/cli-and-env-variables-ref.html
- `airflow dags test` executa uma execução da Dag para uma data lógica. https://airflow.apache.org/docs/apache-airflow/3.3.2/cli-and-env-variables-ref.html
- Pacotes de Dag versionados (Git) e não versionados (local, S3, GCS); ao limpar, o padrão é rodar a versão original, e no backfill, a mais recente. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/dag-bundles.html
- A tarefa é tratada como transação, com o mesmo resultado a cada reexecução; INSERT numa reexecução pode duplicar linhas e dá lugar ao UPSERT. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Gravar numa partição específica, com `data_interval_start` como partição, nunca o dado mais recente; `now()` fica fora de cálculo crítico. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Não guardar arquivo no disco local entre tarefas, porque a seguinte pode rodar em outro servidor; dado grande vai para armazenamento remoto, com o caminho no XCom. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Checagens dentro da própria Dag e tarefa vigia com `TriggerRule.ONE_FAILED`, a jusante de todas as outras. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Nada de banco, rede ou cálculo pesado no topo do arquivo da Dag; `Variable.get` no topo e o template `{{ var.value.<nome> }}`; teste de carga com `python` e homologação parametrizada. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- O alerta vem de cinco callbacks, que aceitam notifier no lugar da função; marcar estado pela interface ou pela linha de comando não dispara callback; erro de callback vai para o log do Dag processor, fora da interface por padrão. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/logging-monitoring/callbacks.html
- Deadline Alerts são novos na 3.1, devem ser tratados como experimentais e chamam um callback quando o prazo estoura. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/deadline-alerts.html
- O código HTTP de `/api/v2/monitor/health` não indica saúde; o campo `status` de cada componente indica, e o scheduler fica `unhealthy` depois de 30 s sem heartbeat. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/logging-monitoring/check-health.html
- Pool serve para limitar tarefas simultâneas contra um sistema frágil; o `default_pool` começa com 128 vagas. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/pools.html
- No modo poke o sensor ocupa a vaga o tempo todo; no reschedule, só enquanto confere. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/sensors.html
- Tarefa adiada não ocupa vaga, e a instalação precisa de ao menos um processo triggerer. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/deferring.html
- Senha fica em Connection, fora do código da Dag, e a Connection pode vir por variável de ambiente `AIRFLOW_CONN_{CONN_ID}`. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/connection.html
- O mascaramento é acionado por Connection e Variable; XCom não é mascarado. https://airflow.apache.org/docs/apache-airflow/3.3.2/security/secrets/mask-sensitive-values.html
- O Airflow 3 removeu SubDAG, SLA e `execution_date`; o SLA foi substituído por Deadline Alerts. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- O Dag processor precisa ser iniciado à parte, mesmo em ambiente local (`airflow dag-processor`), e o webserver virou API server (`airflow api-server`). https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- Caminhos de import antigos estão marcados para remoção numa versão futura. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- O Airflow 3.0 removeu `schedule_interval` e `timetable` em favor de `schedule`, cujo padrão passou a ser `None`, e `catchup_by_default` passou a False. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- A partir da 3.0, execução manual ou disparo pela API sem data lógica fica com `logical_date=None` e sem janela de dados. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- As políticas de nova tentativa chegaram no Airflow 3.3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- As notas da 3.3.2 registram que a 3.3.0 trouxe SDKs de tarefa em Java e Go, experimentais, com a Dag e o agendamento ainda em Python. https://raw.githubusercontent.com/apache/airflow/3.3.2/RELEASE_NOTES.rst
- A 3.3.2 é a versão estável, publicada no PyPI em 2026-09-17. https://pypi.org/pypi/apache-airflow/json
- A linha 3 está em manutenção, sem data de fim; a linha 2 está em fim de vida desde 2026-04-22, e versão em fim de vida não recebe correção nem suporte. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/supported-versions.html
- O Airflow recomenda no mínimo 4 GB de memória; no Windows roda só por WSL2 ou contêiner Linux; produção só é suportada em Linux. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/prerequisites.html
- No Windows é obrigatório usar o WSL2, com os arquivos na home do Linux, não na montagem do Windows. https://airflow.apache.org/docs/apache-airflow/3.3.2/start.html
- Na instalação por imagem Docker, montagem, banco, schema, monitoramento e dimensionamento ficam com o usuário; o serviço gerenciado é para quem prefere tê-lo gerenciado e aceita pagar por isso. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/index.html
- O SQLite nunca deve ser usado em produção. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/set-up-database.html
- O Docker Compose oficial é para aprendizado, sem garantias de segurança de produção; pede ao menos 4 GB de memória para o Docker, 8 GB o ideal, e Compose v2.14.0 ou mais novo; para produção, a recomendação é Kubernetes com o Helm chart oficial. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- No Linux, `AIRFLOW_UID=$(id -u)` vai no `.env`, senão os arquivos ficam com dono root; o valor 50000 serve para outros sistemas. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- O compose oficial da 3.3.2 avisa, sem bloquear, abaixo de 10 GB de disco livre, 4000 MiB de memória ou 2 CPUs; checa o servidor de API por `/api/v2/monitor/health`; e usa `postgresql+psycopg2` na conexão do banco de metadados. https://airflow.apache.org/docs/apache-airflow/3.3.2/docker-compose.yaml
- A página da imagem Docker do Airflow cita Python 3.12 como padrão. https://airflow.apache.org/docs/docker-stack/index.html
- Como `"0 0 * * *"`, `"@daily"`, `"@hourly"` e `timedelta` viram timetable na 3.3.2. https://github.com/apache/airflow/blob/3.3.2/task-sdk/src/airflow/sdk/definitions/dag.py
- Os rótulos da interface para o reprocessamento (Missing Runs para `none`, Missing and Errored Runs para `failed`, All Runs para `completed`), que a página de backfill não declara, estão no formulário de backfill da 3.3.2. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/constants/reprocessBehaviourParams.ts
- O botão Acionar preenche a data lógica com o instante atual e oferece janela inferida ou manual; os rótulos em português "Acionar", "Inferido da Data Lógica e do Timetable" e "Especificar Manualmente" estão no arquivo de tradução. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/components/TriggerDag/TriggerDAGForm.tsx ; https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/public/i18n/locales/pt/components.json
- A interface toma o fuso padrão do navegador e guarda a escolha no armazenamento local; o seletor junta UTC, o fuso detectado e a lista IANA. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/context/timezone/TimezoneProvider.tsx ; https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/layouts/Nav/TimezoneSelector.tsx

### Providers e Task SDK do Airflow

Pacotes com versão própria, separada da versão do Airflow.

- `catchup` desligado por padrão e o significado de `max_active_runs` no `DAG`. https://airflow.apache.org/docs/task-sdk/stable/api.html
- O `SQLExecuteQueryOperator` do provider common-sql é o caminho atual para rodar SQL a partir da Dag e aceita `parameters` e `split_statements`, desligado por padrão. https://airflow.apache.org/docs/apache-airflow-providers-common-sql/stable/operators.html ; https://airflow.apache.org/docs/apache-airflow-providers-postgres/stable/changelog.html
- `PostgresOperator` saiu no provider postgres 6.0.0, e `MsSqlOperator`, no microsoft-mssql 4.0.0, os dois com indicação do `SQLExecuteQueryOperator`. https://airflow.apache.org/docs/apache-airflow-providers-postgres/stable/changelog.html ; https://airflow.apache.org/docs/apache-airflow-providers-microsoft-mssql/stable/changelog.html
- `SQLColumnCheckOperator`, `SQLTableCheckOperator`, `SQLValueCheckOperator` e `SQLThresholdCheckOperator`, com limites que podem ser número ou consulta SQL; provider common-sql na versão 2.4.0. https://airflow.apache.org/docs/apache-airflow-providers-common-sql/stable/operators.html
- O provider Amazon tem operadores para criar, iniciar, parar e apagar tarefas do DMS e um sensor que espera a tarefa; provider na versão 9.39.0. https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/operators/dms.html

### Apache Airflow 3.4.0, versão candidata

- A 3.4.0 teve rc1 publicada no PyPI em 2026-10-28, sem versão final publicada na data da consulta. https://pypi.org/pypi/apache-airflow/json
- As notas da rc1 datam a 3.4.0 em 2026-11-02, data prevista; exigem Python 3.11 ou mais; tornam o psycopg3 o driver padrão do banco de metadados; criam uma execução por evento em Dags disparadas por asset, com `batch_asset_events=True` para manter o lote. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/RELEASE_NOTES.rst
- As notas da rc1 trazem, experimentais, a escrita da Dag inteira fora do Python, pelos SDKs de TypeScript, Go e Java e pelo formato YAML nativo de Dag. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/RELEASE_NOTES.rst
- O compose oficial da rc1 usa `postgresql+psycopg` na conexão do banco de metadados. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/airflow-core/docs/howto/docker-compose/docker-compose.yaml

### PostgreSQL 16

- `ON CONFLICT DO UPDATE` garante resultado atômico de inserir ou atualizar, mesmo com concorrência, desde que não haja erro independente; também chamado de UPSERT. https://www.postgresql.org/docs/16/sql-insert.html
- Conexões a um PostgreSQL em hot standby são estritamente só leitura; nem tabelas temporárias podem ser gravadas. https://www.postgresql.org/docs/16/hot-standby.html
- Servidor estrangeiro guarda os dados de conexão que o foreign-data wrapper usa para acessar um recurso externo. https://www.postgresql.org/docs/16/sql-createserver.html
- O `postgres_fdw` acessa dados guardados em servidores PostgreSQL externos e exige senha, ou credencial GSSAPI delegada, para usuário comum. https://www.postgresql.org/docs/16/postgres-fdw.html
- `AT TIME ZONE` sobre horário sem fuso interpreta o valor naquele fuso e devolve `timestamptz`. https://www.postgresql.org/docs/16/functions-datetime.html

### Microsoft Learn

- Por padrão, a VM do WSL 2 recebe 50% da memória do Windows e swap de 25%, arredondado para o GB acima; `.wslconfig` fica em `%UserProfile%` e só vale depois que a VM para; `localhostForwarding` é `true` por padrão. https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- No WSL, a distribuição desliga depois de 15 segundos ociosa, e o usuário padrão recebe UID 1000 na primeira instalação. https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- O disco de cada distribuição do WSL 2 é um arquivo `ext4.vhdx` no disco do Windows, e o `df` dentro do Linux mostra o máximo alocado ao disco virtual, não o espaço livre do disco físico. https://learn.microsoft.com/en-us/windows/wsl/disk-space
- `wsl --install` roda em PowerShell de administrador, exige Windows 10 versão 2004 (build 19041) ou Windows 11, instala o Ubuntu em WSL 2 e pede reinício. https://learn.microsoft.com/en-us/windows/wsl/install
- Usuário e senha do Linux são criados no primeiro uso e não têm relação com o usuário do Windows. https://learn.microsoft.com/en-us/windows/wsl/setup/environment
- Para comandos Linux, guarde os arquivos no sistema de arquivos do WSL. https://learn.microsoft.com/en-us/windows/wsl/filesystems
- O Agendador de Tarefas do Windows dispara por horário e por evento, tenta de novo em falha com contagem e intervalo, e deixa desligada por padrão a execução de horário perdido, que vale só para tarefas por horário com fim definido ou repetição infinita. https://learn.microsoft.com/en-us/windows/win32/taskschd/task-triggers ; https://learn.microsoft.com/en-us/windows/win32/taskschd/taskschedulerschema-restartonfailure-settingstype-element ; https://learn.microsoft.com/en-us/windows/win32/taskschd/tasksettings-restartcount ; https://learn.microsoft.com/en-us/windows/win32/taskschd/tasksettings-startwhenavailable
- `schtasks /create /sc` é o equivalente de linha de comando ao cron. https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks-create
- O SQL Server Agent roda trabalhos de um ou mais passos, por agenda, alerta ou sob demanda, avisa por e-mail via Database Mail e vem desligado na instalação. https://learn.microsoft.com/en-us/ssms/agent/sql-server-agent
- O SQL Server Agent não existe na edição Express; grupos de disponibilidade Always On completos são da Enterprise, e os básicos, da Standard. https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022 ; https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2025
- Na réplica legível do SQL Server, as consultas usam isolamento por snapshot, sem disputa entre leitura e escrita; não se grava nos bancos secundários, mas sim em outros bancos da mesma instância. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups
- O grupo de disponibilidade básico não permite leitura na réplica secundária. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/basic-availability-groups-always-on-availability-groups
- A atualização agendada do Power BI permite oito por dia na capacidade compartilhada e até 48 em Premium, PPU ou Fabric; fonte na sua rede exige gateway; a falha vai por e-mail ao dono. https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data
- O Power BI desativa a agenda após quatro falhas seguidas e inicia a atualização em até 15 minutos do horário, com atraso possível de até uma hora. https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-scheduled-refresh
- O Airflow do Azure Data Factory não cria instância nova desde 2026-01-01. https://learn.microsoft.com/en-us/azure/data-factory/concepts-workflow-orchestration-manager
- O Airflow do Fabric suporta só a versão 2.10.5 e não aceita rede privada nem rede virtual. https://learn.microsoft.com/en-us/fabric/data-factory/apache-airflow-jobs-concepts

### Docker

- O `docker info` expõe `MemTotal`, o total de memória física disponível no host do Docker, em bytes. https://docs.docker.com/reference/cli/docker/system/info/ ; https://docs.docker.com/reference/api/engine/version/v1.51.yaml
- Requisitos do Docker Desktop no Windows com WSL 2: Windows 10 22H2 ou Windows 11 23H2 nas edições Enterprise, Pro ou Education, 8 GB de RAM e virtualização ligada. https://docs.docker.com/desktop/setup/install/windows-install/
- O Docker Desktop é grátis para empresas com menos de 250 funcionários e menos de 10 milhões de dólares de receita anual, entre outros usos; organização maior e governo exigem assinatura. https://docs.docker.com/subscription/desktop-license/
- Arquivos montados em contêiner rendem muito mais no sistema de arquivos do Linux, por isso evite `/mnt/c`; o WSL mínimo é o 2.1.5, e WSL antigo pode fazer o `vmmem.exe` consumir toda a memória. https://docs.docker.com/desktop/features/wsl/best-practices/
- Porta publicada pelo Docker Desktop pode ser restrita a `127.0.0.1`. https://docs.docker.com/desktop/features/networking/
- Nos perfis do Compose, serviço citado na linha de comando roda sem ativar o perfil. https://docs.docker.com/compose/how-tos/profiles/
- A imagem `apache/airflow:3.3.2-python3.13` está publicada e ativa no Docker Hub, e a `apache/airflow:3.3.2` tem o mesmo digest. https://hub.docker.com/v2/repositories/apache/airflow/tags/3.3.2-python3.13 ; https://hub.docker.com/v2/repositories/apache/airflow/tags?name=3.3.2

### Git

- Com `core.autocrlf=true`, o Git converte LF em CRLF no checkout, e `.gitattributes` com `eol=lf` força LF; `*.sh text eol=lf` mantém LF na cópia de trabalho (Git 2.56.0). https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration ; https://git-scm.com/docs/gitattributes

### SRE do Google

- O cron é uma lista de comandos com horários, sem dependência entre eles nem nova tentativa, e dispara e esquece. https://pubs.opengroup.org/onlinepubs/9799919799/utilities/crontab.html ; https://sre.google/sre-book/distributed-periodic-scheduling/
- Pular uma execução é preferível a dobrar, porque a pulada se recupera e a dobrada às vezes não; o dono deve acompanhar o efeito da rotina. https://sre.google/sre-book/distributed-periodic-scheduling/
- O pipeline periódico fica frágil quando o volume cresce, e com intervalo curto as execuções se empilham. https://sre.google/sre-book/data-processing-pipelines/
- Definição de toil. https://sre.google/sre-book/eliminating-toil/
- Não convém automatizar todo componente; automação sem critério cria tantos problemas quanto resolve. https://sre.google/sre-book/automation-at-google/
- Agendas legíveis concentram tarefas na hora cheia e à meia-noite; a correção foi um horário espalhado de forma determinística pelo hash do `dag_id`. https://shopify.engineering/lessons-learned-apache-airflow-scale ; https://sre.google/sre-book/distributed-periodic-scheduling/

### RFC 9110

- Um método é idempotente quando várias requisições idênticas têm o mesmo efeito de uma só, e o cliente não deve repetir automaticamente uma requisição não idempotente. A RFC trata de HTTP; a aplicação a cargas de dados é extrapolação didática. https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2

### AWS

- O AWS DMS migra dados uma vez ou replica as mudanças contínuas para manter origem e destino em sincronia. https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html
- No DMS, replicação contínua e CDC são o mesmo processo, que lê os logs do banco de origem e não é replicação em tempo real. https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Task.CDC.html
- Novas tentativas são egoístas: pedem espera crescente (backoff) exponencial com teto, variação aleatória (jitter) e limite no número de tentativas; API com efeito colateral só é segura de repetir se for idempotente. Artigo de 2019-12-05. https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- O MWAA `mw1.micro` comporta até 25 Dags e 3 tarefas simultâneas, sem autoescala. https://docs.aws.amazon.com/mwaa/latest/userguide/environment-class.html
- O MWAA oferece até a 3.3.1, disponível desde 2026-09-01, e a 2.11.2, disponível desde julho de 2026; só troca versão menor; o suporte é de ao menos 12 meses por versão, com aviso de 180 dias. https://docs.aws.amazon.com/mwaa/latest/userguide/airflow-versions.html
- O MWAA Serverless cobra pelo tempo de tarefa, usa definição em YAML com operadores da AWS e não dá acesso direto à interface do Airflow; operador próprio pede o MWAA provisionado. https://docs.aws.amazon.com/mwaa/latest/mwaa-serverless-userguide/what-is-mwaa-serverless.html
- Preço de tabela público: a máquina de 8 GB e 2 vCPU do Lightsail, Linux com IPv4, custa US$ 0,05913 por hora em us-east-1 e sa-east-1. https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonLightsail/current/us-east-1/index.json ; https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonLightsail/current/sa-east-1/index.json
- Preço de tabela público: o MWAA `mw1.micro` custa US$ 0,29 por hora em us-east-1 e cerca de US$ 0,4986 em sa-east-1; o MWAA Serverless custa US$ 0,08 por hora de tarefa em us-east-1 e US$ 0,104 em sa-east-1. https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonMWAA/current/us-east-1/index.json ; https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonMWAA/current/sa-east-1/index.json

### Google Cloud

- Em 2026-04-15, o Google anunciou que o Cloud Composer está se tornando o Managed Service for Apache Airflow. https://docs.cloud.google.com/composer/docs/release-notes
- A imagem mais nova traz o Airflow 3.3.1, e a imagem padrão é a 2.11.1. https://docs.cloud.google.com/composer/docs/composer-versions
- A geração 3 custa US$ 0,06 por DCU-hora em us-central1; a DCU (Data Compute Unit) é uma unidade abstrata de medida dos recursos de computação alocados ao ambiente. https://cloud.google.com/composer/pricing

### dbt

- O dbt transforma dado que já está no banco a partir de consultas SELECT, cria tabelas e views e resolve a ordem entre os modelos, com um DAG próprio. https://docs.getdbt.com/docs/introduction
- Quem decide quando o dbt roda é a plataforma do próprio dbt ou uma ferramenta externa, como o Airflow. https://docs.getdbt.com/docs/deploy/deployments ; https://docs.getdbt.com/docs/deploy/deployment-tools
- Snapshots do dbt implementam SCD tipo 2 com `dbt_valid_from` e `dbt_valid_to`; a estratégia `check` usa o horário corrente sem `updated_at`; snapshots não podem ser reconstruídos, com sugestão de schema separado; rodam em agenda, entre de hora em hora e diariamente. https://docs.getdbt.com/docs/build/snapshots
- Snapshot é captura de mudanças em lote: a cada execução, o dbt compara a origem com o último snapshot e não recupera mudanças sobrescritas entre duas execuções. https://docs.getdbt.com/best-practices/how-we-handle-cdc/1-intro ; https://docs.getdbt.com/best-practices/how-we-handle-cdc/2-choosing-incremental-or-snapshots

### Kimball

- SCD tipo 1 sobrescreve e perde o histórico. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-1/
- SCD tipo 2 guarda cada versão numa linha nova, com início e fim de vigência e indicador de linha atual. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/

### Debezium

- O Debezium grava as mudanças de linha de cada tabela num fluxo ordenado de eventos; documentação estável 3.7. https://debezium.io/documentation/reference/stable/index.html ; https://debezium.io/documentation/faq/
- CDC lê o log de transações do banco de origem e leva cada mudança adiante. https://debezium.io/documentation/reference/stable/index.html ; https://debezium.io/documentation/reference/stable/features.html

### Outras fontes primárias

- Orquestrar é executar um fluxo definido: primeiro A, depois B, depois C; a frase aparece onde a documentação diz que o Kubernetes não é só um sistema de orquestração. https://kubernetes.io/docs/concepts/overview/
- Os cinco campos de horário do crontab são minuto, hora, dia do mês, mês e dia da semana, e a única reação a erro descrita é mandar por e-mail a saída não redirecionada. https://pubs.opengroup.org/onlinepubs/9799919799/utilities/crontab.html
- No cronie, `CRON_TZ` define o fuso da tabela. https://man7.org/linux/man-pages/man5/crontab.5.html
- No pacote `cron` do Debian, o daemon roda num fuso definido e não há fuso por usuário. https://manpages.debian.org/trixie/cron/crontab.5.en.html
- `flock -n` falha em vez de esperar pela trava, com saída 1 por padrão. https://man7.org/linux/man-pages/man1/flock.1.html
- O `pg_cron` agenda dentro do Postgres, uma instância de cada trabalho por vez, com fuso padrão GMT e histórico numa tabela. https://github.com/citusdata/pg_cron
- O `numfmt --to=iec` escala por potências de 1024, então o "G" da saída é GiB. https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html
- O Brasil não tem horário de verão desde 2019: a última regra Brazil com mudança na base de fusos é de fevereiro de 2019, e `America/Sao_Paulo` fica em -3:00, três horas atrás de UTC. https://data.iana.org/time-zones/tzdb/southamerica ; https://data.iana.org/time-zones/tzdb/version
- O psycopg 3 não executa várias instruções com parâmetros num mesmo `execute()`. https://www.psycopg.org/psycopg3/docs/basic/from_pg2.html
- O `python3` padrão do Ubuntu 22.04 é o 3.10.6. https://launchpad.net/ubuntu/+source/python3-defaults
- Um grafo dirigido acíclico é um grafo dirigido sem ciclos dirigidos. https://en.wikipedia.org/wiki/Directed_acyclic_graph
- O Luigi cuida de resolução de dependências, gestão do fluxo, visualização e tratamento de falhas, e não substitui os motores de processamento. https://luigi.readthedocs.io/en/stable/
- O Prefect promete rastreamento de estado, tratamento de falha e monitoramento. https://docs.prefect.io/v3/get-started
- As etapas do ciclo de vida são gerar, armazenar, ingerir, transformar e servir, e orquestração está entre as seis correntes subjacentes. Texto de Joe Reis de 2026-07-27. https://joereis.substack.com/p/the-data-engineering-lifecycle-and
- Seguir a arquitetura medalhão é prática recomendada, não requisito; bronze recebe o dado cru, silver o validado, gold o enriquecido. https://docs.databricks.com/aws/en/lakehouse/medallion
- Padrões Fast Metadata Cleaner, Data Overwrite, Merger, Stateful Merger e Keyed Idempotency, no repositório de código do livro. https://github.com/bartosz25/data-engineering-design-patterns-book
- Backup com `pg_dump` 9.2 contra PostgreSQL 9.6, e-mails de erro do cron rejeitados por falta de DMARC e falha descoberta só na hora de restaurar. https://about.gitlab.com/blog/postmortem-of-database-outage-of-january-31/
- Na Astronomer, a versão do Airflow 3.3 tem manutenção até julho de 2028, e a do 2.11, até abril de 2027. https://www.astronomer.io/docs/runtime/runtime-version-lifecycle-policy

### Saídas capturadas em ambiente descartável

Nível 3: executadas em 2026-10-29, com a saída capturada, em Linux nativo, salvo onde a linha diz
outra coisa. Versões: Airflow 3.3.2 nas imagens `apache/airflow:3.3.2` e
`apache/airflow:3.3.2-python3.13`, que têm o mesmo digest (Python 3.13.15); PostgreSQL 16.15
(`postgres:16.15-alpine`); Docker Engine 28.3.3 e Compose 2.39.1. Dados sintéticos. Os arquivos de
Dag e de compose passaram no validador (nível 2): `ruff check` e `ruff format --check`, com ruff
0.12.12, e `docker compose config -q`. O comportamento do backfill descrito nos capítulos, como as
execuções simultâneas e a recusa do segundo backfill, vem destas saídas, não da documentação.

- Máquina: `docker compose version` respondeu `Docker Compose version v2.39.1`, e o `numfmt` da
  memória do Docker deu `31G`; a imagem do Airflow ocupa 2,33 GB em disco e não traz o provider do
  SQL Server.
- Ambiente principal: saudável em cerca de 1 min 21 s a 1 min 27 s na primeira subida e 53 s nas
  seguintes; contêineres com cerca de 0,7 GiB ociosos e pico de 1,1 GiB; cenário completo sob teto
  rígido de 1,8 GiB, sem swap, e saudável em 91 s com duas CPUs.
- Windows 11 (versão 10.0.26200) com WSL 2.7.13.0 e Docker Engine dentro do Ubuntu: subida em 41 a
  42 s; registro de carga igual ao do Linux; contêineres somando de 1,1 a 1,3 GiB; VM do WSL em
  9,2 GB e memória livre do Windows perto de 2 GB no pior momento; `df` com cerca de 205 GiB livres
  no disco virtual enquanto o C: tinha cerca de 2,3 GiB; `AIRFLOW_UID` 50000 com
  `Permission denied`; leitura de arquivo de 120 a 170 vezes mais lenta em `/mnt/c`, com a opção
  `metadata` ligada; Dag nova gravada pelo caminho `\\wsl.localhost` visível em cerca de 29 s; `.sh`
  com LF no Git do Ubuntu; `Get-PSDrive` com o espaço livre do C:, em bytes.
- Fim de linha: `.sh` com CRLF falhou com `bash\r` e saída 127, sem criar o `.env`; o script de
  inicialização do Postgres com CRLF falhou com `bad interpreter`, e a subida seguinte deixou o
  Postgres pronto sem a base `loja`.
- Degraus lado a lado: script à mão com cerca de 3 s por dia, contando a subida do contêiner, e
  primeira tentativa desfeita por um comentário com ponto e vírgula; cron do busybox na imagem
  `python:3.13.15-alpine3.24`, na casa de 5 MiB, com o erro da réplica derrubada só num arquivo de
  log do contêiner, sem nova tentativa nem linha no registro de carga, e relógio em UTC (16:38 em
  UTC às 13:38 de Brasília); degraus 1 e 2 na casa de 34 MiB de memória, com imagem de 72,7 MB;
  Airflow com LocalExecutor subindo em 1 min 17 s, em quatro contêineres, na casa de 680 MiB logo
  depois de subir e de 0,86 GiB depois dos experimentos.
- `flock -n` com duas execuções sobrepostas: a segunda saiu com 1, e a terceira rodou depois de a
  trava ser liberada; util-linux 2.39.3.
- Réplica só leitura: o papel `replica_leitura`, criado pelo script de inicialização com a senha
  passada ao psql por `-v`, aceita `BEGIN READ WRITE` apesar do `default_transaction_read_only`, e
  só o GRANT apenas de SELECT barra a escrita, com `permission denied for table pedidos`; a imagem
  oficial deixa `127.0.0.1` entrar pela regra `trust`, e o `postgres_fdw` de usuário comum por esse
  endereço falha com "Non-superuser cannot connect if the server does not request a password or use
  GSSAPI with delegated credentials".
- Mesmo SQL, outro executor: o `silver_pedidos.sql` rodado à mão e pela Dag `loja_idempotente` deu
  4 pedidos e 430,90 no gold do dia 20; o registro de carga mostrou os mesmos números à mão e em
  dois reprocessos pela Dag, com o executor `airflow:backfill`.
- Airflow 3 na prática: `TypeError` com `schedule_interval`, `ModuleNotFoundError` nos imports
  antigos e o import de `airflow.decorators` ainda funcionando; Dags nascendo com `is_paused` em
  `True`; `No data found` em `airflow dags list-import-errors`; Dag mínima `ola_orquestracao` em
  `success`, com `Total do dia: 245.5` no log; `airflow dags test` da Dag mínima em cerca de 33 s,
  com SQLite; `docker compose down --volumes --remove-orphans` removendo o volume do banco e a rede
  do laboratório.
- Idempotência: a versão que apaga e regrava o dia ficou em 4 linhas e 430,90 a cada reexecução; o
  INSERT sem chave, sobre o dia já carregado, levou a 8 linhas e 861,80, depois a 12 e 1.292,70,
  com 3 cópias de cada pedido, sempre com sucesso, e a versão que apaga e regrava consertou o dia;
  na tabela de rascunho, sem chave, 3 linhas viraram 6, com chave primária a segunda carga falhou
  com `duplicate key value violates unique constraint`, e com `ON CONFLICT DO UPDATE` ficaram 3.
- Nova tentativa, reprocesso e limpeza, com a queda simulada de propósito: na versão ingênua, a
  nova tentativa deixou o gold em 8 pedidos e 861,80, com `attempt=1.log` e `attempt=2.log`; o
  reprocesso de três dias, rodado duas vezes, levou 430,90, 111,90 e 293,30 a 861,80, 223,80 e
  586,60; a limpeza da tarefa do bronze e das seguintes levou o dia de 111,90 a 223,80, com o
  efeito capturado e o comando transcrito à mão. Na versão idempotente, nova tentativa e
  reprocessos mantiveram os números.
- Datas: data lógica, janela e `ds` por timetable e por caminho de disparo (CLI, API e botão
  Acionar); partição gravada por disparo manual na CLI e na API; `UndefinedError` em `{{ ds }}` no
  disparo sem data lógica; ensaio com limites em 00:00 UTC listando só `2026-10-22 09:00:00+00:00`;
  três execuções do reprocesso começando com menos de 2 milissegundos de diferença numa Dag com
  `max_active_runs=1`, e o reprocesso registrado com limite 10; segundo reprocesso recusado com
  `AlreadyRunningBackfill` ("There can be only one running backfill per Dag"); despausar com
  catchup desligado criando só a execução mais recente; execução das 6h de Brasília com a data
  `2026-10-29T09:00:00+00:00`.
- Fuso: cron `"0 0 * * *"` sem fuso disparando às 21h de Brasília; `ds=2026-10-29` na execução das
  22h de Brasília do dia 28; janela diária em UTC lendo dois atendimentos do dia local anterior e
  perdendo o das 21h30; janela em Brasília lendo o dia local; pedido das 21h30 de 20/10 gravado
  como 00:30 UTC de 21/10 e contado no dia 20 da gold; interface com 29/10 no identificador e
  28/10 21:00 na coluna Executar Depois; `-03:00` para `America/Sao_Paulo` em janeiro e outubro de
  2026; `airflow config get-value core default_timezone` devolvendo `utc`.
- Registro de carga e alerta: 5, 7 e 7 linhas, com a terceira carga em falha em `checar_repeticao`
  e `ALERTA` no log; `run_type` gravado como `DagRunType.MANUAL` com `str()` e como `manual` com
  `.value`; dependência mal declarada com `UndefinedTable`, escondida pela nova tentativa, e alerta
  falso com 5 linhas em vez de 7; carga com zero linhas terminando em sucesso no cron e no
  Airflow; `/api/v2/version` com 200 sem token e `/api/v2/dags` com 401 no compose oficial;
  `No alive jobs found` quando o `$HOSTNAME` expande no shell da máquina.
- Mini-desafio, com o Airflow 3.3.2 instalado por `uv` em Python 3.12.3 e banco SQLite novo:
  limites sem hora impressos como 00:00 UTC e padrão de reprocesso `None`; ensaio de 23 a 25 sem
  hora listando as datas lógicas 22 e 23, e de 24 a 26 listando 23 e 24; limites com hora, em UTC
  ou com `-03:00`, listando 23, 24 e 25.
- Nível 2: a checagem do Exercício 8 carregou sem erro de importação, com os providers postgres
  7.0.2 e common-sql 2.1.1, e o `airflow tasks render` mostrou as duas consultas no dia anterior à
  data lógica, sem rodar contra o banco; o `docker-compose.yaml` do laboratório usa
  `postgresql+psycopg2`, conferido na leitura do arquivo.
- Laboratório do capítulo 13, em `engenharia_de_dados/orquestracao/airflow/lab/`: Lab 0 a Lab 5
  rodados em sequência num ambiente só, com a saída de cada lab em `saidas/`; Airflow saudável em
  46 s com o Postgres já no ar e em 54 s e 82 s partindo do zero; `python dags/pipeline_loja.py`
  sem saída e com código 0; `airflow dags test loja_idempotente 2026-10-22` em `success` em cerca
  de 15 s; contêineres somando cerca de 0,9 GiB no fim do Lab 5; o `down` final sem contêiner nem
  volume do projeto; `.gitattributes` com `*.sh text eol=lf` mantendo o `.sh` com LF num clone com
  `core.autocrlf=true`, no Git 2.55.0.

## Reconferência na 3.4.0

A apostila foi escrita e conferida na 3.3.2. A 3.4.0 estava em versão candidata na data da
pesquisa, com a rc1 no PyPI em 2026-10-28 e a versão final prevista para 2026-11-02; as fontes
estão no grupo "Apache Airflow 3.4.0, versão candidata", acima.

Antes de publicar, confira de novo, na versão final:

- o ciclo de vida e as versões dos serviços gerenciados, no capítulo 11;
- as mudanças da 3.4 listadas no capítulo 17: Python 3.11 ou mais, psycopg3 como driver padrão do
  banco de metadados e uma execução por evento em Dags disparadas por asset;
- os padrões de configuração citados nos capítulos 5 a 9, que podem mudar de uma versão para
  outra.

Data da reconferência na 3.4.0: pendente. Até lá, vale a 3.3.2.

---

[Índice](../README.md#capítulos) · [Anterior: 18. Glossário](18-glossario.md)
