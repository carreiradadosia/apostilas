---
title: "9. Saber que falhou: registro de carga, alerta e falha silenciosa"
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

[Índice](../README.md#capítulos) · [Anterior: 8. Fuso horário: o dia de quem?](08-fuso-horario.md) · [Próximo: 10. Proteger a origem e guardar o que some](10-proteger-a-origem-e-guardar-o-que-some.md)

## 9. Saber que falhou: registro de carga, alerta e falha silenciosa

"Como eu sei se a carga falhou?"

Essa pergunta veio do gerente de TI que montava a primeira arquitetura de dados. Na sessão, saiu uma ideia: registrar cada carga e alertar quando a contagem de linhas repete a do ciclo anterior.

Uma carga falha de dois jeitos. Quebrando, ou terminando verde.

### 9.1 Duas formas de falhar

"Se a tarefa ficou verde, deu certo?"

**O que é**

Falha barulhenta é a tarefa que quebra: o estado vira falha, e alguém pode ser avisado. Falha silenciosa é a carga que termina com sucesso e não traz dado, ou traz dado errado.

**Como funciona na prática**

Num teste feito para esta apostila, rodamos o mesmo SQL pelo cron e pelo Airflow. O cron não faz parte do laboratório da mentoria; aqui ele aparece só como resultado observado.

Com o login da réplica cortado, o cron se comportou como o capítulo 4 contou: o erro ficou só num arquivo de log dentro do contêiner, e o `docker compose logs cron` voltou vazio. Ninguém foi avisado, porque não havia alerta configurado.

Num dia sem dado novo, todos os passos do cron disseram `ok`, com `bronze=0`. A execução agendada do Airflow terminou em sucesso, com zero linhas no bronze.

**O equívoco comum**

Achar que verde quer dizer dado certo. Verde quer dizer que o código não lançou erro. Sem checagem explícita, o orquestrador não sabe que zero linhas é problema.

### 9.2 Avisar quando quebra: callback e notifier

"Quando a tarefa quebra, quem me avisa?"

**O que é**

No Airflow, o aviso vem de callbacks, funções chamadas quando o estado muda. São cinco: `on_success_callback`, `on_failure_callback`, `on_retry_callback`, `on_execute_callback` e `on_skipped_callback`. No lugar da função, cabe um notifier, um notificador pronto.

O alerta de prazo (Deadline Alerts) chama um callback quando a execução da Dag passa do tempo definido. É novo na 3.1, a documentação pede que seja tratado como experimental, e substitui o SLA, que saiu no Airflow 3. Na mentoria, recomendamos começar por callback ou notifier.

**O equívoco comum**

Testar o alerta marcando a tarefa como falha na interface. Estado mudado pela interface ou pela linha de comando não executa callback. O teste fica mudo e não prova nada.

E erro dentro do callback vai para o log do Dag processor, que por padrão não aparece na interface. Callback quebrado é alerta mudo. No laboratório, o `print` do callback apareceu no log da própria tarefa, logo depois da exceção; o callback que quebra não foi testado.

### 9.3 O registro de carga

"Como sei o que rodou ontem, e quantas linhas trouxe?"

**O que é**

Registro de carga é uma tabela com cada carga: quando rodou, se foi agendada ou manual, quantas linhas.

**Como funciona na prática**

Dá para começar à mão, com um `INSERT` depois de cada carga. Quando a entrega à diretoria virar recorrente, uma tarefa grava a linha sozinha. A tabela do laboratório:

```sql
CREATE TABLE IF NOT EXISTS controle_carga (
    id             bigserial PRIMARY KEY,
    run_id         text NOT NULL,
    tipo_execucao  text NOT NULL,
    linhas         integer NOT NULL,
    registrado_em  timestamptz NOT NULL DEFAULT now()
);
```

A tarefa que grava, trecho da Dag `registro_de_carga`:

```python
@task
def registrar_carga() -> int:
    contexto = get_current_context()
    tipo = contexto["dag_run"].run_type.value
    hook = PostgresHook(postgres_conn_id=CONN_ID)
    linhas = hook.get_first("SELECT count(*) FROM pedidos_tratados")[0]
    hook.run(
        "INSERT INTO controle_carga (run_id, tipo_execucao, linhas) "
        "VALUES (%s, %s, %s)",
        parameters=(contexto["run_id"], tipo, linhas),
    )
    print(f"Carga registrada: {linhas} linhas, tipo {tipo}")
    return linhas
```

**O equívoco comum**

Gravar o tipo com `str()`. O `run_type` é uma enumeração: `str()` grava `DagRunType.MANUAL`, e `.value` grava `manual`. A primeira versão do laboratório saiu com `DagRunType.SCHEDULED` na tabela, e todo filtro depois teria de conhecer esse texto.

### 9.4 O alerta que pega a falha verde

"E se a carga rodar e não trouxer nada novo?"

**O que é**

Uma checagem que compara a contagem com a da carga anterior. Se repetiu, a origem pode não ter sido atualizada.

**Como funciona na prática**

Trechos da mesma Dag, sem a indentação da função que a define:

```python
def alertar(context) -> None:
    # Stand-in for a real channel (email, chat); prints so the lab needs no credentials.
    ti = context["task_instance"]
    print(f"ALERTA: a task {ti.task_id} falhou na execução {context['run_id']}")


@task(retries=0, on_failure_callback=alertar)
def checar_repeticao(linhas_agora: int) -> None:
    hook = PostgresHook(postgres_conn_id=CONN_ID)
    anterior = hook.get_first(
        "SELECT linhas FROM controle_carga ORDER BY id DESC LIMIT 1 OFFSET 1"
    )
    if anterior is None:
        print("Primeira carga registrada, nada para comparar.")
        return
    if anterior[0] == linhas_agora:
        raise ValueError(
            f"A contagem repetiu a carga anterior ({linhas_agora} linhas). "
            "A origem pode não ter sido atualizada."
        )
    print(f"Contagem mudou: {anterior[0]} para {linhas_agora} linhas.")

linhas = registrar_carga()
criar_tabelas >> carregar_pedidos_tratados >> linhas
checar_repeticao(linhas)
```

A checagem quebra de propósito, e a falha chama o callback. Ela roda sem nova tentativa, porque repetir a comparação não atualiza a origem.

As três cargas do laboratório:

| Carga | Tipo | Linhas | Resultado |
|---|---|---|---|
| 1 | agendada | 5 | sucesso, primeira carga |
| 2 | manual, depois de dois pedidos novos | 7 | sucesso, a contagem mudou de 5 para 7 |
| 3 | manual, sem mudança na origem | 7 | falha em `checar_repeticao`, `ALERTA` no log |

Log da terceira carga, sem o horário de cada linha:

```text
error Task failed with exception
    ValueError A contagem repetiu a carga anterior (7 linhas). A origem pode não ter sido atualizada.
info ALERTA: a task checar_repeticao falhou na execução manual__2026-10-29T15:37:56.280786+00:00
```

Aqui o alerta só escreve no log, para rodar sem credencial. Nenhum canal real foi testado. No seu ambiente, troque o `print` por um canal que alguém lê.

Contagem repetida nem sempre é erro. Num dia sem venda, ela repete de verdade. Por isso o alerta chama uma pessoa, e a pessoa decide.

**O equívoco comum**

Achar que a Dag roda na ordem que você imaginou. Ela roda na ordem que você declarou. Na primeira versão do laboratório, a contagem não dependia da carga. Ela começou junto com a criação das tabelas e falhou com `UndefinedTable`. A Dag tinha uma nova tentativa configurada (no Airflow 3 ela vem desligada), e essa nova tentativa passou e escondeu o erro de ordem. Na carga seguinte, contou antes de carregar, registrou 5 em vez de 7 e disparou um alerta falso.

### 9.5 Checagens prontas e a tarefa vigia

"Preciso escrever toda checagem à mão?"

**O que é**

Não. As boas práticas do Airflow, na seção de autochecagens (Self-Checks), mandam pôr checagens dentro da própria Dag. O provider common-sql traz `SQLColumnCheckOperator` e `SQLTableCheckOperator`, para coluna e tabela. Traz também `SQLValueCheckOperator`, que compara uma consulta com um valor esperado, e `SQLThresholdCheckOperator`, que confere mínimo e máximo, cada um número ou outra consulta SQL.

Nível 1: a página do provider está na 2.4.0, a imagem do laboratório traz a 2.1.1, e nenhum desses operadores rodou nele.

**O equívoco comum**

Confiar numa tarefa final que roda sempre. O estado da execução vem das tarefas folha, as que não têm nada depois. Uma folha com regra de disparo (trigger rule) `all_done` roda de qualquer jeito e, se passa, deixa a execução verde com falha no meio. A correção da documentação é a tarefa vigia (watcher): uma tarefa com `TriggerRule.ONE_FAILED`, a jusante de todas as outras.

### 9.6 Quem vigia o orquestrador

"E se o próprio Airflow parar?"

**O que é**

O código HTTP de `/api/v2/monitor/health` não prova saúde. Ele responde 200 mesmo com um componente doente. A saúde está no campo `status` de cada componente. O scheduler vira `unhealthy` depois de 30 segundos sem sinal de vida (heartbeat), o padrão de `scheduler_health_check_threshold`.

O `/api/v2/version` também não serve de prova. No compose oficial, ele respondeu 200 sem token, enquanto `/api/v2/dags` respondeu 401: a resposta não mostra que a API autenticada está de pé. O próprio compose oficial checa o servidor de API por `/api/v2/monitor/health`.

**O equívoco comum**

Confiar num alerta que nunca chegou a ninguém. No postmortem público da queda de 31 de janeiro de 2017, o GitLab conta que o backup diário com `pg_dump` 9.2 falhava contra o PostgreSQL 9.6. Os e-mails de erro do cron eram rejeitados pelo destino, por falta de DMARC. Ninguém soube da falha até precisar restaurar o backup. Entre as ações listadas, estão monitorar o backup e testar a restauração de forma automática.

A lição, na leitura da mentoria: alerta só vale se comprovadamente chega. Provoque uma falha real, executada pelo Airflow, e confira se a mensagem chegou.

**Como inspecionar**

Você roda o registro de carga e o alerta deste capítulo no Lab 3. Para ver o estado de cada tarefa e o registro:

```bash
docker compose exec airflow-scheduler airflow tasks states-for-dag-run registro_de_carga <run_id>
docker compose exec postgres psql -U loja -d loja -c \
  "SELECT id, run_id, tipo_execucao, linhas FROM controle_carga ORDER BY id;"
```

Saída observada (o `run_id` muda a cada execução):

```text
 id |                  run_id                  | tipo_execucao | linhas
----+------------------------------------------+---------------+--------
  1 | scheduled__2026-10-29T10:00:00+00:00     | scheduled     |      5
  2 | manual__2026-10-29T15:37:31.582613+00:00 | manual        |      7
  3 | manual__2026-10-29T15:37:56.280786+00:00 | manual        |      7
(3 rows)
```

**Verificação do código deste capítulo**

- Dag `registro_de_carga` e tabela `controle_carga`: nível 3. Executadas em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2-python3.13` (mesmo digest de `apache/airflow:3.3.2`; Python 3.13.15, provider common-sql 2.1.1), LocalExecutor e Postgres `16.15-alpine`. Comandos que provaram: `airflow dags unpause registro_de_carga`, dois `airflow dags trigger registro_de_carga`, `airflow tasks states-for-dag-run registro_de_carga <run_id>` e a consulta ao `controle_carga` acima. Os comandos de "Como inspecionar" estão no nível 3.
- A mesma Dag no nível 2: `ruff check --select AIR,E,F,W --preview` com ruff 0.12.12, sem erro, em 2026-10-29.
- Operadores de checagem do common-sql e tarefa vigia: nível 1, só documentação.

O registro de carga diz o que aconteceu na sua ponta. O capítulo 10 volta à origem: ler sem travar e guardar o que ela apaga.

---

[Índice](../README.md#capítulos) · [Anterior: 8. Fuso horário: o dia de quem?](08-fuso-horario.md) · [Próximo: 10. Proteger a origem e guardar o que some](10-proteger-a-origem-e-guardar-o-que-some.md)
