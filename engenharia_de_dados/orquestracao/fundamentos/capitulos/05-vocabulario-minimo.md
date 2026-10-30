---
title: "5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado"
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

[Índice](../README.md#capítulos) · [Anterior: 4. Os degraus: à mão, agendador, orquestrador](04-os-degraus.md) · [Próximo: 6. Nova tentativa e idempotência: o preço do orquestrador](06-nova-tentativa-e-idempotencia.md)

## 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado

Antes do código, o desenho. Este capítulo dá as palavras do desenho e mostra o que o orquestrador guarda de cada execução, com o Airflow 3.3.2 como exemplo.

### 5.1 Dag, o fluxo como grafo

"Todo mundo fala em Dag. O que é isso?"

**O que é**

Dag é um grafo dirigido sem ciclo de tarefas. No Airflow, é a definição do fluxo.

Dirigido: cada seta tem sentido. Sem ciclo: nenhum caminho volta ao ponto de partida. A documentação do Airflow escreve "Dag", e não "DAG", porque ali o termo foi além da estrutura matemática.

**Como funciona na prática**

Vamos desenhar o fluxo da loja no papel:

```text
réplica só leitura   (origem: o bronze lê dela, não é tarefa)
        |
        v
     bronze --> silver --> gold --> registrar_carga --> checar_repeticao
```

Este é o desenho alvo. No laboratório ele está dividido em duas Dags: uma faz bronze, silver, gold e o registro; a outra registra a carga e checa a repetição.

Cada nome é uma tarefa. Cada seta é uma dependência.

**O equívoco comum**

Achar que a Dag faz o trabalho. Ela só diz a ordem. Quem limpa nulo e ajusta fuso é o SQL de cada camada.

### 5.2 Tarefa, operador e sensor

"Cada nome do desenho vira o quê no código?"

**O que é**

Tarefa (task) é um passo da Dag, criado a partir de um operador. Operador é um modelo de tarefa, como o que executa SQL num banco.

**Como funciona na prática**

Chamar um operador dentro da Dag cria uma tarefa. Na Dag do fluxo da loja (pipeline_loja), silver, gold e registrar_carga usam o `SQLExecuteQueryOperator`; o bronze é uma função Python com `@task`, que também vira tarefa.

Sensor é um operador que só espera uma condição externa. Se a réplica atrasar, um sensor antes do bronze espera por ela. O laboratório não usa sensor.

**O equívoco comum**

Achar que a tarefa precisa tratar o dado em Python. Aqui o Python só manda rodar. O tratamento é SQL, dentro do banco.

### 5.3 Dependência e disparo

"Como o orquestrador sabe a ordem? E o que faz o fluxo começar?"

**O que é**

Dependência é a aresta do grafo: uma tarefa só começa depois das anteriores.

**Como funciona na prática**

Por padrão, uma tarefa espera todas as anteriores terminarem com sucesso. No código, a seta do desenho vira `>>`:

```python
bronze(DIA) >> silver >> gold >> registrar
```

Nível 3: Airflow 3.3.2, Linux, 2026-10-29; `airflow tasks states-for-dag-run` mostrou as quatro tarefas em `success`, na ordem. `DIA` é o dia processado (capítulo 7).

Passar o resultado de uma tarefa para outra também cria a dependência. Numa Dag menor do laboratório, registro_de_carga, é assim que checar_repeticao espera registrar_carga:

```python
linhas = registrar_carga()
criar_tabelas >> carregar_pedidos_tratados >> linhas
checar_repeticao(linhas)
```

Nível 3, mesma versão e data: três execuções, uma agendada e duas com `airflow dags trigger registro_de_carga`, gravaram 5, 7 e 7 linhas; a terceira falhou em checar_repeticao, como esperado.

A execução nasce, no dia a dia, de três jeitos. Disparo por horário: a agenda cria a execução; no laboratório, `0 6 * * *`, todo dia às 6h de Brasília, porque a data de início da Dag declara esse fuso; sem fuso declarado, o Airflow usa UTC (capítulo 8). Disparo por evento: a Dag roda quando uma tarefa atualiza um dado (asset) e termina com sucesso. E disparo à mão. O reprocessamento de datas passadas e o catchup também criam execuções; ficam para o capítulo 7.

**O equívoco comum**

Achar que horário resolve ordem. Agendar a gold meia hora depois do bronze não é dependência. Se o bronze atrasar, a gold roda com dado velho.

### 5.4 Execução e estado

"O que o orquestrador guarda cada vez que o fluxo roda?"

**O que é**

Execução da Dag (Dag run) é uma instância da Dag no tempo, com estado próprio. Dentro dela, cada tarefa vira uma instância de tarefa, também com estado.

**Como funciona na prática**

O caminho ideal de uma tarefa e os estados que você mais vai ver fora dele:

| Caminho ideal | Fora do caminho ideal |
|---|---|
| `none`, `scheduled`, `queued`, `running`, `success` | `failed`, `up_for_retry`, `upstream_failed` |

A execução herda o estado das tarefas finais, as que não têm seguinte; o capítulo 9 mostra a armadilha que isso esconde. O Airflow guarda ainda o tipo da execução, agendada ou manual, e um log por tentativa.

**Como inspecionar**

```bash
airflow tasks states-for-dag-run registro_de_carga <run_id>
```

Saída observada na execução que repetiu a contagem (trecho, sem as colunas de data):

```text
task_id                   | state
==========================+========
criar_tabelas             | success
carregar_pedidos_tratados | success
registrar_carga           | success
checar_repeticao          | failed
```

Nível 3: Airflow 3.3.2, Linux, 2026-10-29, via `docker compose exec airflow-scheduler`.

**O equívoco comum**

Achar que `success` quer dizer dado certo. Quer dizer que a tarefa terminou sem erro. No laboratório, simulamos uma queda logo depois de o bronze gravar. A Dag do laboratório liga uma nova tentativa (`retries=1`); sem isso, o Airflow 3 não tenta de novo. A nova tentativa gravou o dia de novo (dois logs, `attempt=1.log` e `attempt=2.log`), e tudo terminou em `success`, com cada pedido duas vezes no bronze. A queda foi simulada; a duplicação, real. Capítulos 6 e 9.

### 5.5 As peças do Airflow 3: quem lê, quem decide, onde fica

"Salvei o arquivo da Dag. Por que ela não aparece?"

**O que é**

O Airflow 3 é feito de peças separadas, cada uma com um papel.

**Como funciona na prática**

- **Dag processor**: lê os arquivos das Dags. No Airflow 3, roda à parte, até no ambiente local.
- **Scheduler**: decide o que roda e quando. O executor é configuração dele; o padrão, `LocalExecutor`, roda até 32 tarefas (`parallelism`) como subprocessos do scheduler. Em contêiner, ajuste o `parallelism` ao limite de memória; o laboratório usa 4.
- **API server**: substitui o webserver do Airflow 2.
- **Banco de metadados**: guarda execuções, estados e histórico.

O Dag processor procura arquivo novo a cada 300 segundos, por padrão: Dag nova pode levar até cinco minutos para aparecer. Arquivo conhecido é relido a cada 30 segundos. O laboratório baixa a busca para 30.

Entre tarefas passa pouco dado, pelo XCom, como a seção 3.2 mostrou; no laboratório, só a contagem de linhas. No Airflow 3, o XCom é limpo a cada nova tentativa.

Três padrões mudaram no Airflow 3: sem agenda, a Dag só roda à mão, porque o padrão de `schedule` é `None`; toda Dag nasce pausada; e o catchup, que cria sozinho as execuções perdidas, vem desligado. No laboratório, as Dags nasceram com `is_paused` em `True`. Nível 3: Airflow 3.3.2, Linux, 2026-10-29, com `airflow dags list` via `docker compose exec airflow-scheduler`.

**O equívoco comum**

Material do Airflow 2 diz que o scheduler lê os arquivos. No 3, quem lê é o Dag processor, e ele é obrigatório. Se a Dag não aparece, confira se ele está de pé, espere a próxima busca e rode `airflow dags list-import-errors`; no laboratório, `No data found` quis dizer nenhum arquivo com erro. Nível 3: Airflow 3.3.2, Linux, 2026-10-29, com `airflow dags list-import-errors` via `docker compose exec airflow-scheduler`.

Com o vocabulário na mão, vamos ao custo que vem junto: o orquestrador roda as coisas de novo. É o capítulo 6.

---

[Índice](../README.md#capítulos) · [Anterior: 4. Os degraus: à mão, agendador, orquestrador](04-os-degraus.md) · [Próximo: 6. Nova tentativa e idempotência: o preço do orquestrador](06-nova-tentativa-e-idempotencia.md)
