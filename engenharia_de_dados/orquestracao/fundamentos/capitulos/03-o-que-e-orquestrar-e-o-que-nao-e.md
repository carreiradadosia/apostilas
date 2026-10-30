---
title: "3. O que é orquestrar, e o que não é"
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

[Índice](../README.md#capítulos) · [Anterior: 2. Contexto de negócio](02-contexto-de-negocio.md) · [Próximo: 4. Os degraus: à mão, agendador, orquestrador](04-os-degraus.md)

## 3. O que é orquestrar, e o que não é

"Trato o dado em Python ou em SQL?" A pergunta aparece cedo, na primeira arquitetura. A resposta
curta: o tratamento fica em SQL, no banco. O Python só manda rodar, na ordem certa.

Por trás dela está a frase guia desta apostila: **o orquestrador não é o código de limpeza, é
quem roda o código.** Vamos ver por que ela vale e onde termina o papel do orquestrador.

### 3.1 Orquestrar é rodar na ordem, com memória

"O que um orquestrador faz que um script não faz?"

**O que é**

A definição técnica é executar um fluxo definido: primeiro A, depois B, depois C. A frase está
na documentação do Kubernetes, que a usa para dizer que ele não é só isso. Nos orquestradores de
dados, esse fluxo vem com estado, nova tentativa e histórico, como mostram as
ferramentas abaixo.

**Como funciona na prática**

Ferramentas diferentes descrevem o mesmo núcleo. O Luigi cuida de dependências, fluxo,
visualização e falhas, e avisa que não substitui os motores que processam o dado: só costura as
tarefas. O Prefect promete rastrear estado, tratar falha e monitorar.

O Apache Airflow, nosso exemplo, se define como plataforma para orquestrar fluxos em lote. A
mesma página cita também treino de modelos e cargas com LLM, mas o caso típico é o lote. Serve
bem quando o fluxo tem início e fim e roda em agenda, disparado por horário ou por evento. O
fluxo é escrito em Python, o que traz versionamento, trabalho em equipe e teste. Pela interface
você dispara uma execução, lê o log, reprocessa datas passadas (backfill) e roda de novo só as
tarefas que falharam. A documentação avisa: quem prefere clicar a programar talvez não ache ali
a melhor escolha, porque algum código sempre será necessário.

**O equívoco comum**

Ver a orquestração como uma etapa do fluxo, entre ingerir e transformar. Joe Reis, coautor do
livro *Fundamentals of Data Engineering* (2022), separa as etapas do ciclo de vida (gerar,
armazenar, ingerir, transformar, servir) das correntes que atravessam todas elas. Orquestração é
uma dessas correntes, ao lado de segurança e DataOps, entre outras. O orquestrador não faz uma
etapa. Ele faz as etapas acontecerem na ordem.

### 3.2 Quem roda o código e quem trata o dado

"Se o Airflow é programado em Python, a limpeza também não deveria ser em Python?"

**O que é**

O orquestrador decide quando e em que ordem cada passo roda. O banco executa o SQL que trata o
dado.

**Como funciona na prática**

A documentação do Airflow é direta: a Dag, o grafo de tarefas do fluxo, não se importa com o que
acontece dentro das tarefas. Ela cuida de como executá-las: ordem, tentativas, tempo limite.

Na rede de lojas desta apostila, a camada silver resolve nulo, espaço sobrando, maiúscula e fuso
do pedido que veio do bronze. Quem faz isso é este SQL, arquivo completo:

```sql
-- Clean the day: nulls, padding, case, drop the redundant text column, local time to UTC.
DELETE FROM silver.pedidos
WHERE dia_local = %(dia)s::date;

INSERT INTO silver.pedidos (id, cliente, valor, status, criado_em_utc, dia_local)
SELECT
    id,
    COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado'),
    valor,
    COALESCE(lower(trim(status)), 'desconhecido'),
    criado_em AT TIME ZONE 'America/Sao_Paulo',
    criado_em::date
FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;
```

A parte do Airflow que cuida da silver é este trecho da Dag:

```python
silver = SQLExecuteQueryOperator(
    task_id="silver",
    conn_id=CONN_ID,
    sql="sql/silver_pedidos.sql",
    parameters={"dia": DIA},
    split_statements=True,
)

bronze(DIA) >> silver >> gold >> registrar
```

A tarefa aponta para o arquivo SQL e para o banco. `DIA` é o dia processado, o anterior à data
lógica; datas ganham capítulo próprio adiante. A última linha define a ordem. Nenhuma linha de
Python troca nulo nem ajusta fuso.

O laboratório prova a separação. O mesmo `silver_pedidos.sql` rodou à mão, por um script, e
depois como tarefa da Dag. Para 20 de outubro de 2026, o gold deu a mesma receita paga nas duas
formas: 430,90. Mudou quem manda rodar. O tratamento não mudou.

> Verificação: nível 3. Executado em 2026-10-29, em Linux nativo, com Airflow 3.3.2 (imagem
> `apache/airflow:3.3.2`, o mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que esta
> apostila fixa; Python 3.13.15) e Postgres 16.15-alpine. À mão:
> `docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20`. Pela Dag:
> `airflow tasks states-for-dag-run loja_idempotente retry_idempotente`, com `silver` em
> `success`, numa execução disparada com data lógica 2026-10-21 09:00 UTC (dia processado
> 20/10), em que a primeira tentativa do bronze tem uma queda simulada de propósito, pelo conf
> `simular_queda`; silver e gold rodaram uma vez, com sucesso. Python aprovado no `ruff check`
> (ruff 0.12.12). Trechos de `dags/sql/silver_pedidos.sql` e `dags/pipeline_loja.py`, do
> laboratório do capítulo 13.

Por isso começar à mão é um caminho válido. O SQL que você valida hoje é o mesmo que o
orquestrador vai rodar quando a entrega virar recorrente.

**O equívoco comum**

Achar que o orquestrador carrega o dado entre os passos. Ele passa referência e estado, não a
tabela. O XCom, canal do Airflow entre tarefas, é para pouco dado; a documentação veta valores
grandes, como tabelas em memória do Python (dataframes). Arquivo no disco local também não serve,
porque a tarefa seguinte provavelmente roda em outro servidor. Dado grande fica num armazenamento
remoto, e segue adiante só o caminho. Na Dag da loja, cada tarefa lê e grava no banco.

### 3.3 Os vizinhos que não são orquestração

"Pesquisei e apareceram DMS, Debezium e dbt na mesma lista que o Airflow. É tudo a mesma coisa?"

**O que é**

Não. São vizinhos, e cada um responde a uma pergunta diferente.

| Categoria | Exemplo | Pergunta que responde |
|---|---|---|
| Orquestração | Airflow | Quando e em que ordem cada passo roda, e o que aconteceu com ele? |
| Replicação e captura de mudanças (CDC) | AWS DMS, Debezium | Como levar cada mudança da origem para outro lugar, de forma contínua? |
| Organização de SQL | dbt | Como escrever e encadear as transformações em SQL no banco? |

**Como funciona na prática**

Ferramentas de replicação e CDC, como o AWS DMS e o Debezium, leem as mudanças no log de
transações do banco de origem e as levam de forma contínua para outro lugar. O orquestrador não
faz essa cópia. No caso do DMS, o Airflow tem operadores para criar, iniciar, parar e apagar a
tarefa de replicação e um sensor que espera a tarefa terminar; quem copia continua sendo o DMS.

O dbt organiza a transformação em SQL: você escreve consultas `SELECT` e ele cria as tabelas e
visões (views) no banco, na ordem certa entre os modelos. Quando ele roda, quem decide é o
agendamento, na plataforma do próprio dbt ou num orquestrador como o Airflow, em que a execução
do dbt vira um passo do fluxo.

**O equívoco comum**

Achar que, com o dbt, o orquestrador some. O dbt resolve a ordem entre os modelos dele, dentro do
banco. Quem encadeia o dbt com o que está fora dele, como a carga que vem da réplica, é o
orquestrador.

Se orquestrar é rodar na ordem e guardar o que aconteceu, a próxima pergunta é quando você
precisa disso. O capítulo 4 responde em degraus.

---

[Índice](../README.md#capítulos) · [Anterior: 2. Contexto de negócio](02-contexto-de-negocio.md) · [Próximo: 4. Os degraus: à mão, agendador, orquestrador](04-os-degraus.md)
