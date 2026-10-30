---
title: "16. Erros comuns e como corrigir"
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

[Índice](../README.md#capítulos) · [Anterior: 15. Rubrica de validação da aprendizagem](15-rubrica-de-validacao-da-aprendizagem.md) · [Próximo: 17. Plano de continuidade](17-plano-de-continuidade.md)

## 16. Erros comuns e como corrigir

"Deu erro. Por onde eu começo?" Pelo sintoma. Erro comum, aqui, é o que o laboratório
mostrou acontecer, com a mensagem copiada da tela, ou o que a documentação oficial aponta como armadilha;
a nota abaixo diz qual é qual. Cada tabela é um momento do fluxo da nossa rede de
lojas. Ache a linha pelo que você vê, leia a causa e corrija. E guarde uma regra: verde não é
certo.

> Verificação: mensagens e comandos no nível 3, observados em 2026-10-29 na imagem
> `apache/airflow:3.3.2-python3.13`, mesmo digest de `3.3.2`, em Linux e em Windows 11 com WSL2 e
> Docker Engine. A mensagem sai no idioma do sistema: `Permission denied` vira `Permissão negada`.
> O `.gitattributes` do repositório, com `*.sh text eol=lf`, está no nível 3 no Git 2.55.0 do Linux:
> num clone com `core.autocrlf=true`, o `.sh` ficou com LF e um `.txt` virou CRLF; no Git for
> Windows, não foi testado. Ficam no nível 1, conferidos na documentação: o `start_date` com `pendulum`
> (página de fuso, nas fontes), o aviso de versão da Dag, o sensor, o `dag_run.logical_date`, o
> callback e o health.

### 16.1 Antes da primeira carga: subir o ambiente

"Nada sobe. É a minha máquina?" Muitas vezes é: nenhum destes erros é defeito do Airflow.

| Sintoma | Causa | Correção |
|---|---|---|
| `/usr/bin/env: “bash\r”`, saída 127, sem `.env` | Script com fim de linha do Windows (CRLF) | Clone de dentro do WSL, cujo Git não converte; no repositório, `*.sh text eol=lf` no `.gitattributes` |
| `/bin/sh^M: bad interpreter` no Postgres; depois, `Skipping initialization` e nada do banco `loja` | Script de inicialização em CRLF; com o volume criado, o Postgres não roda o script de novo | Converta para LF e apague o volume: `docker compose down --volumes --remove-orphans`. O `pg_isready` não pega esse caso |
| `Permission denied` ao criar ou editar Dag; `dags/` com dono `50000:0` | `AIRFLOW_UID` fixo em 50000, como num runbook antigo | Apague esse `.env`, rode o `preparar.sh`, que grava `AIRFLOW_UID=$(id -u)`, e suba de novo: o `airflow-init` devolve `dags/` e `logs/` ao seu usuário |
| `df -h` no WSL mostrando `205G` livres (cerca de 205 GiB) e o C: com pouco mais de 2 GB | O disco do WSL é o arquivo `ext4.vhdx`, no C:; o `df` mede o disco virtual, cujo tamanho máximo não depende do espaço que sobra no C: | Meça com `Get-PSDrive C` no PowerShell e libere espaço antes de baixar a imagem, que ocupa cerca de 2,3 GB em disco depois de extraída (capítulo 0) |
| Ler arquivo fica de 120 a 170 vezes mais lento | Projeto em `/mnt/c` (medido com a opção `metadata` ligada no `/mnt/c`, que não é o padrão; sem ela, o número não foi medido) | Clone no home do Linux; nas Dags pequenas do laboratório, o Airflow não mostrou diferença de tempo |

**O equívoco comum**

Copiar `AIRFLOW_UID=50000` porque a documentação cita o número. Ela cita
para outros sistemas. No Linux vale o seu usuário, e no teste o WSL se comportou como Linux.

### 16.2 Ao escrever a Dag da loja

"Copiei um tutorial e deu erro antes de rodar."

| Sintoma | Causa | Correção |
|---|---|---|
| `TypeError: DAG.__init__() got an unexpected keyword argument 'schedule_interval'` | O Airflow 3 removeu `schedule_interval` | `schedule=`, como `schedule="0 6 * * *"` na Dag da loja |
| `ModuleNotFoundError` em `python_operator`, `bash_operator` ou `PostgresOperator` | Caminhos do Airflow 2 | `airflow.sdk` e providers (capítulo 12) |
| Dag processor avisa que a versão da Dag não para de crescer | `start_date=datetime.now()` muda a cada leitura | `pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo")` |
| Dag nova não aparece | Varredura de arquivo novo a cada 300 s | Espere até 5 minutos; o laboratório usa 30 s |
| `UndefinedTable` na primeira tentativa da contagem, sucesso na segunda, alerta falso com 5 linhas em vez de 7 | A contagem não dependia da carga | `carregar_pedidos_tratados >> linhas`, e leia o log de cada tentativa |

**O equívoco comum**

Achar que a nova tentativa resolveu. Esse erro de ordem foi real, e a
segunda tentativa o escondeu. O orquestrador executa o grafo que você declarou.

### 16.3 Na carga do dia

"Ficou tudo verde. Por que a receita dobrou?" A Dag da loja roda às 6h de Brasília e carrega o
dia anterior. Nenhum destes erros fica vermelho na hora.

| Sintoma | Causa | Correção |
|---|---|---|
| Receita do dia de 430,90 para 861,80 | INSERT sem chave: a nova tentativa, ou a reexecução à mão, grava o dia de novo | Apague o dia e insira na mesma transação, ou UPSERT pela chave |
| Zero linhas no bronze | Falha silenciosa: ninguém confere a contagem | Registro de carga e tarefa que falha quando a contagem repete (capítulo 9); uma checagem de zero linhas segue a mesma ideia (não verificado: essa checagem não foi implementada no laboratório) |
| Sensor há dias segurando vaga de execução (slot) | O modo padrão, poke, ocupa a vaga; o tempo limite padrão é de 7 dias | `mode="reschedule"` e tempo limite explícito; a versão adiável exige o triggerer, que o compose leve não sobe |

O conserto da primeira linha é o bronze que apaga e regrava o dia, o mesmo SQL da seção 6.2.

> Verificação: nível 3, Postgres 16.15. `python scripts/pipeline.py --dia 2026-10-20` duas vezes
> deu 430,90 nas duas; só com INSERT, 861,80 e 1.292,70, com saída 0. Na Dag, a nova tentativa
> deixou uma cópia de cada pedido. A queda foi simulada de propósito, depois do commit.

**O equívoco comum**

Ligar a nova tentativa antes de a carga ser idempotente. Na 3.3.2, sem
configuração, ela vem desligada (`default_task_retries` 0). Ligue quando rodar duas vezes der o
mesmo número.

### 16.4 Nas datas: o fechamento das 22h e o reprocesso à mão

"Por que o dia 28 foi parar no 29? E por que o disparo à mão quebrou?"

| Sintoma | Causa | Correção |
|---|---|---|
| Carga do dia 28 na partição `dt=2026-10-29` | `ds` é a data lógica em UTC; 22h do dia 28 em Brasília já é dia 29 em UTC | `CronTriggerTimetable("0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1))` deu `ds=2026-10-28` (capítulo 8) |
| `UndefinedError: 'ds' is undefined` | Disparo sem data lógica (CLI sem `-l`, API com `logical_date: null`) não tem `ds` nem janela | `airflow dags trigger datas_cron_puro -l 2026-10-20T00:00:00+00:00` deu `ds=2026-10-20`. Com `-l`, o `ds` segue a data pedida, mas pela CLI o intervalo de dados continua ancorado no disparo; para reprocessar um dia, use backfill, ou leia `dag_run.logical_date` em vez do intervalo |

**O equívoco comum**

Testar só à mão e supor que a execução agendada recebe o mesmo contexto.

### 16.5 Ao vigiar a carga

"Como sei que o alerta funciona e que o Airflow está vivo?"

| Sintoma | Causa | Correção |
|---|---|---|
| Marcou falha na interface e o alerta não chegou | Callback só roda quando o worker muda o estado | Teste com falha real; erro no callback vai para o log do Dag processor, fora da interface por padrão |
| `/api/v2/monitor/health` responde 200 com o scheduler doente | O 200 só diz que a chamada deu certo | Leia o `status` de cada componente; o scheduler fica `unhealthy` após 30 s sem sinal |
| `No alive jobs found`, saída 1, scheduler saudável | `$HOSTNAME` expande no bash da sua máquina | `docker compose exec airflow-scheduler bash -c 'airflow jobs check --job-type SchedulerJob --hostname "$HOSTNAME"'` |

**O equívoco comum**

Vigiar pelo código HTTP. Um 200 não é um scheduler vivo.

Na dúvida, volte ao registro de carga: quando rodou, se foi agendada ou manual, quantas linhas.
É nele que aparecem a contagem dobrada, o zero e a contagem fora de ordem, desde que alguém, ou
uma checagem, olhe para ele. A receita dobrada apareceu na consulta do gold.

---

[Índice](../README.md#capítulos) · [Anterior: 15. Rubrica de validação da aprendizagem](15-rubrica-de-validacao-da-aprendizagem.md) · [Próximo: 17. Plano de continuidade](17-plano-de-continuidade.md)
