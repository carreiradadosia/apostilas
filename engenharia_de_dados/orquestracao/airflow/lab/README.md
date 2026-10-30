---
title: "Laboratório de orquestração com Airflow 3.3.2"
date: 2026-10-29
type: lab
status: draft
project: zambotto-mentoria
tags:
  - mentoria
  - orquestracao
  - airflow
  - laboratorio
---

# Laboratório de orquestração com Airflow 3.3.2

Ambiente descartável dos Labs 0 a 5 da apostila de Fundamentos de orquestração
(`engenharia_de_dados/orquestracao/fundamentos/apostila.md`, capítulo 13). Uma rede de lojas
fictícia, com dados sintéticos, roda o mesmo fluxo à mão e como Dag: réplica só leitura, camadas
bronze, silver e gold em SQL, registro de carga com alerta e o atendimento da meia-noite.

O orquestrador não é o código de limpeza, é quem roda o código. Aqui o tratamento fica em SQL no
banco; o Python só executa e encadeia.

**Todos os comandos rodam de dentro desta pasta.** A partir da raiz do repositório clonado:

```bash
cd engenharia_de_dados/orquestracao/airflow/lab
```

## Requisitos de máquina

| Item | Mínimo | Observado neste laboratório |
|---|---|---|
| Sistema | Linux, ou Windows 10 versão 2004 ou mais nova, ou Windows 11, com WSL2 | Linux nativo; Windows 11 com WSL2 e Docker Engine dentro do Ubuntu |
| Docker | Docker Engine com Compose 2.14.0 ou mais novo | Docker Engine 28.3.3 e Compose 2.39.1 |
| Memória para o Docker | 4 GB, segundo o Airflow; 8 GB o ideal | contêineres somando cerca de 0,9 GiB no fim do Lab 5; pico de 1,1 a 1,3 GiB nos testes de pesquisa |
| Disco livre | 10 GB, o piso que o compose oficial do Airflow usa para avisar | imagem do Airflow com 2,33 GB, Postgres com 294 MB e a do `runner` com 73 MB |
| CPU | 2 | o cenário completo ficou saudável com 2 CPUs nos testes de pesquisa |

Confira a sua máquina:

```bash
docker compose version
numfmt --to=iec $(docker info --format '{{.MemTotal}}')
```

## O que tem aqui

| Arquivo | Papel |
|---|---|
| `docker-compose.yaml` | um compose só: Postgres sempre; `runner` no perfil `manual`; Airflow 3.3.2 com LocalExecutor no perfil `airflow` |
| `preparar.sh` | cria o `.env` com `AIRFLOW_UID=$(id -u)` e senhas aleatórias; nada de senha no repositório |
| `postgres-init/01_loja.sh` | banco `loja`, origem da Dag `registro_de_carga` |
| `postgres-init/02_erp_e_dw.sh` | banco `erp`, a réplica fictícia com um papel que só lê, e banco `dw`, que lê a réplica por `postgres_fdw` e guarda bronze, silver, gold e o registro de carga |
| `dags/sql/` | o SQL de cada camada; o mesmo arquivo roda no script à mão e na Dag |
| `scripts/pipeline.py` | o fluxo à mão: executa os arquivos SQL em ordem, numa transação só |
| `runner/Dockerfile` | imagem do `runner`: `python:3.13.15-alpine3.24` com `psycopg[binary]==3.3.5` |
| `dags/ola_orquestracao.py` | a primeira Dag: três tarefas em sequência, sem sistema externo |
| `dags/registro_de_carga.py` | registro de cada carga e alerta quando a contagem repete a anterior |
| `dags/pipeline_loja.py` | `loja_ingenua` e `loja_idempotente`, que só mudam no arquivo do bronze |
| `dags/datas_por_timetable.py` | seis Dags iguais que só mudam a agenda, para ver data lógica, janela e fuso |
| `checagens/extrair_logs.py` | lê os logs das tarefas e imprime só as linhas do experimento de datas |
| `saidas/` | saída real de cada lab, capturada na execução de 2026-10-29 |

### Perfis do compose

| Caminho | Comando que sobe | Labs |
|---|---|---|
| À mão | `docker compose up -d --wait postgres` e `docker compose run --rm -T runner ...` (perfil `manual`) | 1 e 4 |
| Airflow | `docker compose --profile airflow up -d --wait --wait-timeout 300` | 2, 4 e 5 |
| Registro de carga | o mesmo perfil `airflow`: a Dag `registro_de_carga` e o banco `loja` | 3 |

O cron fica só como explicação na apostila: este compose não tem perfil de cron.

O serviço `runner` pertence ao perfil `manual`, mas citá-lo pelo nome no `run` já o executa sem
ativar o perfil. O `docker compose exec` nos serviços do Airflow funciona com ou sem
`--profile airflow` na frente, depois que eles sobem.

## Passo a passo

A ordem é a da apostila. O ambiente sobe uma vez e fica no ar do Lab 1 ao Lab 5; só o fim do
Lab 5 derruba tudo.

### Lab 0: Preparar a máquina

```bash
./preparar.sh
```

Saída esperada: `.env criado com AIRFLOW_UID=<o seu id> e segredos aleatórios.` No WSL, o
primeiro usuário recebe o UID 1000.

### Lab 1: Réplica só leitura e o fluxo à mão

```bash
docker compose up -d --wait postgres
docker compose exec -T postgres psql -U dw -d dw \
  -c "SELECT count(*) AS pedidos_lidos_pela_replica FROM replica.pedidos;"
docker compose exec -T postgres psql -U replica_leitura -h localhost -d erp \
  -c "BEGIN READ WRITE; UPDATE pedidos SET valor = 0 WHERE id = 101;"
docker compose build runner
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-21
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-22
```

Saída esperada: contagem `10`, escrita recusada com `ERROR:  permission denied for table pedidos`
e, na última linha de cada dia, `bronze=4 silver=4 receita_paga=430.90`,
`bronze=3 silver=3 receita_paga=111.90` e `bronze=3 silver=3 receita_paga=293.30`.

### Lab 2: A primeira Dag

```bash
docker compose --profile airflow up -d --wait --wait-timeout 300
docker compose exec airflow-scheduler airflow dags list-import-errors
docker compose exec airflow-scheduler airflow dags unpause ola_orquestracao
docker compose exec airflow-scheduler airflow dags trigger ola_orquestracao
docker compose exec airflow-scheduler airflow dags list-runs ola_orquestracao
```

Saída esperada: `No data found` nos erros de importação e a execução em `success` alguns segundos
depois do disparo, com `Total do dia: 245.5` no log da tarefa `carregar`. A interface fica em
`http://127.0.0.1:8080`, sem login; por isso a porta fica presa ao `127.0.0.1`.

Para testar a Dag da loja antes de agendar (capítulo 12 da apostila):

```bash
docker compose exec airflow-scheduler python dags/pipeline_loja.py
docker compose exec airflow-scheduler airflow dags test loja_idempotente 2026-10-22
```

O primeiro não imprime nada quando o arquivo carrega. O segundo executa as quatro tarefas de
verdade, sem o agendador, e grava o dia 21 no banco `dw`.

### Lab 3: Registro de carga e alerta

```bash
docker compose exec airflow-scheduler airflow dags unpause registro_de_carga
docker compose exec airflow-scheduler airflow dags list-runs registro_de_carga
docker compose exec postgres psql -U loja -d loja -c \
  "INSERT INTO pedidos_origem (id, cliente, valor, status, criado_em) VALUES
   (6, 'Cliente E', 99.90, 'pago', '2026-10-29 10:00:00'),
   (7, 'Cliente F', 15.00, NULL, '2026-10-29 11:30:00');"
docker compose exec airflow-scheduler airflow dags trigger registro_de_carga
docker compose exec airflow-scheduler airflow dags trigger registro_de_carga
docker compose exec postgres psql -U loja -d loja -c \
  "SELECT id, run_id, tipo_execucao, linhas FROM controle_carga ORDER BY id;"
```

Espere a execução agendada, criada ao despausar, chegar a `success` antes de inserir os pedidos.
Saída esperada: 5, 7 e 7 linhas; a segunda manual falha em `checar_repeticao`, e o log dessa
tarefa traz `A contagem repetiu a carga anterior (7 linhas)` e `ALERTA`. Deixe o ambiente no ar.

### Lab 4: Duplicar e consertar

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 --modo ingenuo
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 --modo ingenuo
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
```

Saída esperada: `bronze=8`, depois `bronze=12`, e a versão idempotente volta a `bronze=4` com
`receita_paga=430.90`. Depois, pela Dag, com a queda simulada de propósito na primeira tentativa:

```bash
docker compose --profile airflow up -d --wait --wait-timeout 300
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-import-errors
docker compose --profile airflow exec -T airflow-scheduler airflow dags unpause loja_ingenua
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-runs loja_ingenua
docker compose exec -T postgres psql -U dw -d dw \
  -c 'TRUNCATE bronze.pedidos, silver.pedidos, gold.vendas_por_dia, controle.carga RESTART IDENTITY;'
docker compose --profile airflow exec -T airflow-scheduler airflow dags trigger loja_ingenua \
  -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}'
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-runs loja_ingenua
ls logs/dag_id=loja_ingenua/run_id=retry_ingenuo/task_id=bronze/
docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia;'
```

Saída esperada: `attempt=1.log` e `attempt=2.log` e o gold do dia 20 com 8 pedidos e `861.80`.
Repita com `loja_idempotente` e `retry_idempotente`: o gold fica em 4 pedidos e `430.90`. O
reprocessamento de datas passadas, com ensaio antes, está no Lab 4 da apostila:

```bash
docker compose --profile airflow exec -T airflow-scheduler airflow backfill create \
  --dag-id loja_ingenua --from-date 2026-10-21 --to-date 2026-10-23 --dry-run
docker compose exec -T postgres psql -U dw -d dw \
  -c 'TRUNCATE bronze.pedidos, silver.pedidos, gold.vendas_por_dia, controle.carga RESTART IDENTITY;'
docker compose --profile airflow exec -T airflow-scheduler airflow backfill create \
  --dag-id loja_ingenua --from-date 2026-10-21 --to-date 2026-10-23T23:59:59+00:00 \
  --reprocess-behavior completed
docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia ORDER BY dia;'
```

Rode o `backfill create` uma segunda vez depois que as três execuções terminarem: na ingênua, os
dias dobram para `861.80`, `223.80` e `586.60`; com `loja_idempotente`, ficam em `430.90`,
`111.90` e `293.30` nas duas vezes. Se responder `AlreadyRunningBackfill`, espere alguns segundos.

### Lab 5: Meia-noite e datas

```bash
docker compose exec -T postgres psql -U dw -d dw \
  -c "SET TimeZone = 'UTC';" \
  -c "SELECT id, cliente, valor, status, criado_em_utc, dia_local FROM silver.pedidos ORDER BY id;"
docker compose exec airflow-scheduler airflow dags unpause datas_trigger_intervalo
docker compose exec airflow-scheduler airflow dags unpause datas_dia_brasilia
docker compose cp checagens/extrair_logs.py airflow-scheduler:/tmp/extrair_logs.py
docker compose exec airflow-scheduler python /tmp/extrair_logs.py /opt/airflow/logs dag_id=datas_
```

Saída esperada: o pedido 104 com `2026-10-21 00:30:00+00` e `dia_local` `2026-10-20`. Nas Dags de
datas, a janela em UTC e a janela em Brasília leem visitas diferentes; a tabela da apostila vale
para a execução agendada de 29/10/2026, e em outra data as visitas sintéticas ficam fora da
janela.

Derrube tudo:

```bash
docker compose --profile airflow --profile manual down --volumes --remove-orphans
```

A imagem do `runner`, de cerca de 73 MB, fica; apague com
`docker image rm orquestracao-lab-runner:local` se quiser. Para recomeçar do zero, apague também a
pasta `logs/`.

## Windows

- **Testado:** Windows 11 com WSL2 e Docker Engine instalado dentro do Ubuntu, sem Docker Desktop.
  O teste rodou a subida do Airflow e o registro de carga na versão de pesquisa deste laboratório,
  antes da unificação, com a mesma imagem, o mesmo Postgres e as mesmas Dags; o compose unificado
  em si não rodou no Windows.
- **Não verificado:** Docker Desktop. Ele pede WSL 2.1.5 ou mais novo, Windows 10 22H2 ou
  Windows 11 23H2 nas edições Enterprise, Pro ou Education, 8 GB de RAM e virtualização ligada.
- **Licença do Docker Desktop:** grátis para uso pessoal, educação, código aberto não comercial e
  empresas com menos de 250 funcionários **e** menos de 10 milhões de dólares de receita anual. Uso
  profissional em organização maior e em governo exige assinatura paga. No notebook da empresa,
  confira antes.
- **Disco:** o que conta é o espaço livre no disco físico onde mora o WSL, em geral o C:. O `df`
  de dentro do Linux mostra o tamanho máximo do disco virtual, não o que sobra no C:. Confira no
  PowerShell com `Get-PSDrive C | Select-Object Free`.
- **Onde clonar:** no home do Linux, não em `/mnt/c`. No teste, ler arquivo no contêiner foi de 120
  a 170 vezes mais lento em `/mnt/c`.
- **Fim de linha:** o repositório traz um `.gitattributes` com `*.sh text eol=lf`, que mantém os
  scripts com LF mesmo com `core.autocrlf=true`. Script com CRLF faz o `preparar.sh` falhar com
  `bash\r` e o Postgres subir sem os bancos do laboratório. Windows Home não é coberto.

## Verificação

Nível 3: Lab 0 a Lab 5 executados em 2026-10-29, em Linux nativo, com Docker Engine 28.3.3,
Compose 2.39.1, `apache/airflow:3.3.2-python3.13` (Airflow 3.3.2, Python 3.13.15) e
`postgres:16.15-alpine` (PostgreSQL 16.15). As saídas estão em `saidas/`, uma por lab. A execução
usou um nome de projeto próprio do Compose, por isso os contêineres aparecem como
`orqlab-verif-...`; na sua máquina, o nome vem do `name:` do compose, `orquestracao-lab`.

| Arquivo em `saidas/` | O que prova |
|---|---|
| `lab0_preparar.txt` | `.env` criado, perfis e imagens do compose |
| `lab1_replica_e_a_mao.txt` | réplica só leitura e o fluxo à mão |
| `lab2_primeira_dag.txt` | subida do Airflow e a primeira Dag |
| `cap12_inspecionar.txt` | `python dags/pipeline_loja.py` e `airflow dags test loja_idempotente` |
| `lab3_registro_e_alerta.txt` | registro de carga e alerta |
| `lab4_duplicar_e_consertar.txt` | duplicação à mão, nova tentativa, ensaio e reprocessamentos |
| `lab5_meia_noite_e_datas.txt` | fuso na silver, datas e o `down` final |
| `lab5-datas-2026-10-29-20h/` | rodada anterior, só do experimento de datas, com subida e `down` próprios |
| `memoria_e_disco.txt` | memória dos contêineres, tamanho das imagens e versões |
| `nivel2.txt` | `ruff check`, `ruff format --check`, `shellcheck`, `docker compose config -q` e o SQL lido pelo `sqlglot` no dialeto postgres |
| `smoke_compose_final.txt` | nova subida curta com a versão final do `docker-compose.yaml`, a imagem fixada na tag explícita |
| `gitattributes_lf.txt` | clone com `core.autocrlf=true` mantendo o `.sh` com LF (Git 2.55.0, Linux) |

Não verificado: SQL Server como origem, Docker Desktop, máquina com só 8 GB físicos, Git for
Windows e o alerta enviado por e-mail ou mensagem.

## Fontes verificadas (2026-10-29)

- Requisitos do Docker Compose do Airflow (4 GB, 8 GB ideal, Compose 2.14.0) e `AIRFLOW_UID=$(id -u)` no Linux. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- O compose oficial da 3.3.2 avisa, sem bloquear, abaixo de 10 GB de disco livre, 4000 MiB de memória ou 2 CPUs. https://airflow.apache.org/docs/apache-airflow/3.3.2/docker-compose.yaml
- No Windows, o Airflow pede WSL2, com os arquivos na home do Linux. https://airflow.apache.org/docs/apache-airflow/3.3.2/start.html
- `wsl --install` exige Windows 10 versão 2004 ou Windows 11. https://learn.microsoft.com/en-us/windows/wsl/install
- O disco do WSL 2 é um `ext4.vhdx` no disco do Windows, e o `df` mostra o máximo do disco virtual. https://learn.microsoft.com/en-us/windows/wsl/disk-space
- Requisitos do Docker Desktop com WSL 2. https://docs.docker.com/desktop/setup/install/windows-install/
- Licença do Docker Desktop. https://docs.docker.com/subscription/desktop-license/
- Evitar `/mnt/c` em arquivos montados em contêiner. https://docs.docker.com/desktop/features/wsl/best-practices/
- Serviço citado na linha de comando roda sem ativar o perfil. https://docs.docker.com/compose/how-tos/profiles/
- `.gitattributes` com `eol=lf` força LF no checkout. https://git-scm.com/docs/gitattributes
- O `postgres_fdw` acessa dados de servidores PostgreSQL externos. https://www.postgresql.org/docs/16/postgres-fdw.html
