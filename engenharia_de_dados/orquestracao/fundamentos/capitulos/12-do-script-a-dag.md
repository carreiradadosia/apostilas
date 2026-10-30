---
title: "12. Do script à Dag: o mesmo fluxo, muda quem roda"
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

[Índice](../README.md#capítulos) · [Anterior: 11. Onde rodar e quanto custa: a decisão do gestor](11-onde-rodar-e-quanto-custa.md) · [Próximo: 13. Laboratório](13-laboratorio.md)

## 12. Do script à Dag: o mesmo fluxo, muda quem roda

Você já roda a carga da loja à mão. Funciona, e é um bom começo. Quando a entrega para a
diretoria virar diária, alguém vai ter de rodar o comando todo dia, no horário, e lembrar do que
falhou. Este capítulo troca quem roda. O SQL não muda.

### 12.1 O mesmo SQL, outro executor

"Vou ter de reescrever o tratamento para o Airflow?" Não.

**O que é**

A Dag é a definição do fluxo: quais passos existem e em que ordem rodam. O tratamento continua
nos arquivos SQL, executados pelo banco. O Python da Dag só encadeia e entrega cada arquivo ao
banco.

**Como funciona na prática**

À mão, no laboratório, você roda um comando por dia; o contêiner `runner` recebe a variável
`DW_URL`, que aponta para o armazém:

```text
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-21
2026-10-29T13:37:09-03:00 dia=2026-10-21 modo=idempotente executor=manual
  bronze_pedidos.sql: ok
  silver_pedidos.sql: ok
  gold_vendas_por_dia.sql: ok
  registrar_carga.sql: ok
  resultado: bronze=3 silver=3 receita_paga=111.90
```

*Saída do laboratório, sem as linhas de contêiner do Compose.*

O script executa quatro arquivos da pasta `dags/sql/` numa transação só. O arquivo
`dags/pipeline_loja.py` lê os mesmos arquivos, da mesma pasta, e cria duas Dags que só mudam no
arquivo do bronze: `loja_idempotente`, a deste capítulo, e `loja_ingenua`, que só insere
(capítulo 6). O bronze é uma tarefa Python só para o laboratório simular a queda depois de gravar
(capítulo 6); o SQL que ele roda é o mesmo do script.

```python
"""Same SQL files as scripts/pipeline.py, now run by Airflow, one task per layer.

Two Dags differ only in the bronze file: loja_ingenua appends, loja_idempotente replaces the day.
"""

from pathlib import Path

import pendulum
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sdk import dag, get_current_context, task

CONN_ID = "dw_db"
SQL_DIR = Path(__file__).parent / "sql"
# The run at 06:00 local time loads the day before its logical date.
DIA = "{{ macros.ds_add(ds, -1) }}"


def criar_dag(dag_id: str, arquivo_bronze: str):
    @dag(
        dag_id=dag_id,
        schedule="0 6 * * *",
        start_date=pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo"),
        catchup=False,
        max_active_runs=1,
        default_args={"retries": 1, "retry_delay": pendulum.duration(seconds=10)},
        tags=["mentoria", "laboratorio"],
    )
    def pipeline():
        @task
        def bronze(dia: str) -> None:
            hook = PostgresHook(postgres_conn_id=CONN_ID)
            hook.run((SQL_DIR / arquivo_bronze).read_text(), parameters={"dia": dia}, split_statements=True)
            contexto = get_current_context()
            # Lab only: fail after the commit on the first try, like a worker lost mid-run.
            if contexto["dag_run"].conf.get("simular_queda") and contexto["ti"].try_number == 1:
                raise RuntimeError("Queda simulada depois do commit: o dia já foi gravado no bronze.")

        silver = SQLExecuteQueryOperator(
            task_id="silver",
            conn_id=CONN_ID,
            sql="sql/silver_pedidos.sql",
            parameters={"dia": DIA},
            split_statements=True,
        )

        gold = SQLExecuteQueryOperator(
            task_id="gold",
            conn_id=CONN_ID,
            sql="sql/gold_vendas_por_dia.sql",
            parameters={"dia": DIA},
            split_statements=True,
        )

        registrar = SQLExecuteQueryOperator(
            task_id="registrar_carga",
            conn_id=CONN_ID,
            sql="sql/registrar_carga.sql",
            parameters={"dia": DIA, "executor": "airflow:{{ dag_run.run_type.value }}"},
        )

        bronze(DIA) >> silver >> gold >> registrar

    return pipeline()


criar_dag("loja_ingenua", "bronze_pedidos_ingenuo.sql")
criar_dag("loja_idempotente", "bronze_pedidos.sql")
```

> Verificação: nível 3. É o arquivo `dags/pipeline_loja.py` do laboratório do capítulo 13,
> sem mudança, executado em 2026-10-29 em ambiente descartável, com a imagem `apache/airflow:3.3.2`
> (mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que a apostila fixa) e PostgreSQL
> 16.15 em contêiner. Comandos que provaram: `airflow dags list-import-errors`,
> `airflow dags trigger` e `airflow tasks states-for-dag-run`, com as saídas da seção 12.4, e
> `airflow backfill create` (capítulo 7). Nível 2: `ruff check --select E,F,W,I,B,UP
> --line-length 120` e `ruff format --check --line-length 120`, ruff 0.12.12, sem erro.

O que acontece a cada dia:

1. O Dag processor lê o arquivo e registra as duas Dags, cada uma com quatro tarefas.
2. Com a `start_date` no fuso de São Paulo, `0 6 * * *` cria uma execução às 6h de Brasília (9h
   em UTC, no laboratório). Fuso é o capítulo 8.
3. `DIA` vira o dia anterior à data lógica (capítulo 7).
4. Cada tarefa abre a Connection `dw_db`, troca `%(dia)s` pelo valor e manda o arquivo ao banco.
5. A última tarefa grava quem rodou: `airflow:scheduled` na execução das 6h, `airflow:manual` num
   disparo à mão e `airflow:backfill` num reprocessamento de datas passadas.

Por que `split_statements=True`? Os arquivos de bronze, silver e gold têm um `DELETE` e um
`INSERT`, e o psycopg 3, driver do Postgres na imagem 3.3.2, não executa várias instruções com
parâmetros num comando só. Ligada, a opção separa as instruções; o padrão é desligada.
`catchup=False` deixa explícito o padrão do Airflow 3, e `max_active_runs=1` segura uma execução
agendada por vez; o reprocessamento de datas passadas tem limite próprio (capítulo 7).

Uma diferença é real. O script grava tudo numa transação. Na Dag, cada camada é uma tarefa com
conexão própria, que grava ao terminar: no laboratório, para o dia 21, o silver leu as 3 linhas que
o bronze acabara de gravar. Se o gold falhar, bronze e silver já estão no banco. Por isso bronze,
silver e gold apagam o dia antes de inserir, e rodar de novo dá o mesmo resultado (capítulo 6). O
registro de carga é a exceção: ganha uma linha por execução, porque guarda o histórico.

**O equívoco comum**

Achar que o Airflow é o código de limpeza. Ele é quem roda o código. Tratamento errado no script
continua errado na Dag, só que todo dia às 6h.

### 12.2 Imports do Airflow 3 e o que saiu do 2

"Copiei um tutorial e deu erro antes de rodar. O que houve?"

**O que é**

No Airflow 3, o que você escreve na Dag (`dag`, `task`, `DAG`) vem de `airflow.sdk`, e os
operadores vêm de pacotes de provedores (providers).

**Como funciona na prática**

| No material do Airflow 2 | Na 3.3.2 | Use |
|---|---|---|
| `DAG(schedule_interval="@daily")` | `TypeError` | `schedule="@daily"` |
| `from airflow.providers.postgres.operators.postgres import PostgresOperator` | `ModuleNotFoundError` | `SQLExecuteQueryOperator`, do provider common-sql |
| `from airflow.operators.python_operator import PythonOperator` | `ModuleNotFoundError` | `airflow.providers.standard.operators.python` |
| `from airflow.decorators import dag, task` | ainda importa | `from airflow.sdk import dag, task` |

> Verificação: nível 3. Cada linha da coluna do meio foi observada em 2026-10-29, em ambiente
> descartável, na imagem `apache/airflow:3.3.2`.

O guia de atualização marca os caminhos antigos que ainda importam para remoção numa versão
futura. Aprenda só os novos. O `MsSqlOperator` também saiu, e o pacote do SQL Server manda usar o
mesmo `SQLExecuteQueryOperator`. Para um ERP em SQL Server, a troca esperada é a Connection; o
laboratório só testou Postgres.

**O equívoco comum**

Reinstalar tudo por causa de um erro de import. Antes, confira a versão do tutorial.

### 12.3 O que não vai no arquivo da Dag

"Posso deixar a senha e uma consulta de configuração no topo do arquivo?"

**O que é**

O Dag processor relê cada arquivo a cada 30 segundos, no padrão. Tudo que está no topo roda a cada
leitura, não só quando a Dag executa.

**Como funciona na prática**

- Nada de acesso a banco, rede ou cálculo pesado no topo. `Variable.get` no topo faz uma chamada a
  cada leitura; use o modelo de texto (template) `{{ var.value.<nome> }}`, resolvido na execução.
- `start_date` fixa. Com `datetime.now()`, o agendamento se confunde e o Airflow 3 cria uma versão
  nova da Dag a cada leitura. Desde a 3.2, o Dag processor avisa.
- Senha fora do código. A Connection pode vir de uma variável de ambiente `AIRFLOW_CONN_` mais o id
  em maiúsculas: `AIRFLOW_CONN_DW_DB` alimenta `conn_id="dw_db"`. O mascaramento nos logs vale para
  o que vem de Connection ou Variable; valor repassado por XCom não é mascarado.
- Paciência com Dag nova. Ela pode levar até cerca de 5 minutos para aparecer, pela varredura
  explicada na seção 5.5. O laboratório baixa para 30 segundos.

**O equívoco comum**

Salvar o arquivo, não ver a Dag e concluir que está quebrada. Rode
`airflow dags list-import-errors` antes de mexer.

### 12.4 Como inspecionar

"Como sei que a Dag funciona antes de subir?"

Dag é código de produção. Teste antes, nesta ordem:

```bash
python dags/pipeline_loja.py
airflow dags list-import-errors
airflow dags test loja_idempotente 2026-10-22
airflow tasks states-for-dag-run loja_idempotente <run_id>
```

1. O Python carrega o arquivo no mesmo ambiente do scheduler: dependência faltando ou erro de
   sintaxe aparecem aqui, antes de qualquer execução.
2. A lista de erros responde `No data found`.
3. O `dags test` roda uma execução inteira, sem agendador, na data lógica que você passar. Num
   contêiner que sai, com SQLite e a imagem já baixada, a Dag mínima levou cerca de 33 s, contando
   a criação do banco.
4. O `states-for-dag-run` mostra o estado de cada tarefa, com o `run_id` da execução. No
   laboratório, para a execução `retry_idempotente`, disparada com data lógica 2026-10-21 às 9h
   UTC, a saída foi esta (o bronze passou na segunda tentativa, depois da queda simulada do
   capítulo 6):

```text
dag_id           | logical_date              | task_id         | state   | start_date                       | end_date
=================+===========================+=================+=========+==================================+=================================
loja_idempotente | 2026-10-21T09:00:00+00:00 | silver          | success | 2026-10-29T16:47:09.015959+00:00 | 2026-10-29T16:47:10.751191+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | gold            | success | 2026-10-29T16:47:11.313194+00:00 | 2026-10-29T16:47:12.529448+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | registrar_carga | success | 2026-10-29T16:47:13.532590+00:00 | 2026-10-29T16:47:14.638679+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | bronze          | success | 2026-10-29T16:47:06.639183+00:00 | 2026-10-29T16:47:08.811795+00:00
```

Se preferir a interface, abra a execução da Dag e confira o estado de cada tarefa.

Por fim, olhe o registro de carga. Os mesmos dias, rodados à mão e pela Dag. À mão:

```text
 id | executor | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+----------+----------------+---------------+---------------+--------------
  1 | manual   | 2026-10-20     |             4 |             4 |       430.90
  2 | manual   | 2026-10-21     |             3 |             3 |       111.90
  3 | manual   | 2026-10-22     |             3 |             3 |       293.30
(3 rows)
```

Pela Dag, num reprocessamento dos mesmos três dias, rodado duas vezes (capítulo 7):

```text
 id |     executor     | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+------------------+----------------+---------------+---------------+--------------
  1 | airflow:backfill | 2026-10-22     |             3 |             3 |       293.30
  2 | airflow:backfill | 2026-10-21     |             3 |             3 |       111.90
  3 | airflow:backfill | 2026-10-20     |             4 |             4 |       430.90
  4 | airflow:backfill | 2026-10-20     |             4 |             4 |       430.90
  5 | airflow:backfill | 2026-10-21     |             3 |             3 |       111.90
  6 | airflow:backfill | 2026-10-22     |             3 |             3 |       293.30
(6 rows)
```

Mesmos números. Só mudou quem rodou.

> Verificação: nível 3. Saídas copiadas sem mudança do laboratório, executado em
> 2026-10-29 em ambiente descartável, com a imagem `apache/airflow:3.3.2` e PostgreSQL 16.15:
> `airflow dags list-import-errors`, `airflow tasks states-for-dag-run` da execução
> `retry_idempotente`, o script à mão e o backfill. Os comandos do Airflow rodaram com
> `docker compose --profile airflow exec -T airflow-scheduler` na frente. Os 33 s vêm do
> `airflow dags test` da Dag mínima, no mesmo dia e na mesma imagem. `python dags/pipeline_loja.py`
> e `airflow dags test loja_idempotente 2026-10-22` também estão no nível 3: rodaram em 2026-10-29
> no laboratório do capítulo 13, com `docker compose exec airflow-scheduler` na frente e a imagem
> `apache/airflow:3.3.2-python3.13`. O primeiro terminou sem saída e com código 0; o segundo marcou
> a execução como `successful` em cerca de 15 s e gravou o dia 21 no registro de carga, com o
> executor `airflow:manual`.

**O equívoco comum**

Tratar o `dags test` como simulação. Ele executa as tarefas de verdade, e o que a Dag grava vai
para o banco. Aponte a Connection para um banco de homologação, com a Dag parametrizada por
variável de ambiente, nunca para a produção.

Agora é com você. O capítulo 13 monta tudo isso na sua máquina.

---

[Índice](../README.md#capítulos) · [Anterior: 11. Onde rodar e quanto custa: a decisão do gestor](11-onde-rodar-e-quanto-custa.md) · [Próximo: 13. Laboratório](13-laboratorio.md)
