---
title: "14. Exercícios, entregáveis e mini-desafio"
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

[Índice](../README.md#capítulos) · [Anterior: 13. Laboratório](13-laboratorio.md) · [Próximo: 15. Rubrica de validação da aprendizagem](15-rubrica-de-validacao-da-aprendizagem.md)

## 14. Exercícios, entregáveis e mini-desafio

"Li tudo. Como sei que consigo fazer sozinho?"

Fazendo. São três níveis. O conceitual pede uma decisão, o cenário pede um diagnóstico e o prático pede prova na tela. O mini-desafio junta datas, fuso e reprocesso.

Tente antes de ler o gabarito. Leve o entregável para a call: o mentor vai pedir para ver, não para ouvir.

### 14.1 Nível conceitual

"Preciso mesmo de um orquestrador para isso?"

**Exercício 1: Qual degrau?**

Objetivo: escolher entre à mão, agendador e orquestrador pelo sinal, não pela ferramenta.

Contexto: cinco cargas da rede de lojas.

1. Um relatório pedido uma vez, para a reunião de amanhã.
2. Descobrir de onde vem cada número do ERP, pelo monitor de consultas do sistema.
3. A cópia noturna de um arquivo para uma pasta, um passo só, sem ninguém esperando por ela.
4. Réplica, bronze, silver, gold e registro de carga, todo dia, com o número na mesa da diretoria.
5. O painel da operação, atualizado várias vezes por hora, com três passos encadeados.

Entregável: uma tabela com a carga, o degrau e o sinal que decidiu.

**Gabarito comentado**

| Carga | Degrau | Sinal que decidiu |
|---|---|---|
| 1 | À mão | Entrega eventual. |
| 2 | À mão | Você ainda está descobrindo de onde vem o número. |
| 3 | Agendador | Tem hora, mas é um passo só e nada depende dele. |
| 4 | Orquestrador | Passos dependentes, entrega recorrente e alguém precisa saber quando falha. |
| 5 | Orquestrador | Frequência alta e passos encadeados. |

A carga 4 é o caso do mentorado. Começar à mão continua valendo, e o sinal de subir é a entrega virar rotina. Esses sinais são critério da mentoria, do capítulo 4. O equívoco comum é subir por catálogo, porque a ferramenta apareceu numa lista.

**Exercício 2: Quem faz o quê no desenho**

Objetivo: separar orquestração, captura de mudanças (CDC) e organização de SQL.

Contexto: um desenho do tipo que a pesquisa com IA devolve a quem monta a primeira arquitetura. ERP, depois AWS DMS, depois o banco de análise, depois dbt, depois o painel. O Airflow aparece "em cima de tudo".

Entregável: uma frase por peça, dizendo se ela copia, transforma ou decide quando e em que ordem.

**Gabarito comentado**

- **DMS copia.** Lê as mudanças no log de transações da origem e as leva de forma contínua. A AWS avisa que não é replicação em tempo real. O Debezium cumpre o mesmo papel.
- **dbt transforma.** Você escreve `SELECT`, e ele cria tabelas e visões (views) na ordem certa entre os modelos.
- **Airflow decide quando e em que ordem, e guarda o estado.** Com o DMS, tem operadores para criar, iniciar, parar e apagar a tarefa de replicação e um sensor que espera por ela; quem copia continua sendo o DMS. Com o dbt, a execução vira um passo do fluxo.

Um equívoco possível é achar que são o mesmo grafo, porque os dois usam a palavra DAG. O dbt tem um DAG próprio, entre os modelos dele. A Dag do Airflow encadeia o dbt com o que está fora dele, como a carga da réplica.

### 14.2 Nível cenário

"Rodou verde e o número está errado. Por onde eu começo?"

Os quatro cenários aconteceram no laboratório, com dados sintéticos. A pergunta é sempre a mesma: o que o orquestrador fez, e o que ele não tinha como saber.

**Exercício 3: Verde com painel vazio**

Objetivo: reconhecer uma falha silenciosa.

Contexto: a Dag da loja roda às 06h de Brasília. As quatro tarefas terminaram em sucesso, e o painel mostra o dia 28 vazio. O registro de carga:

```text
 id |     executor      | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+-------------------+----------------+---------------+---------------+--------------
 11 | airflow:scheduled | 2026-10-28     |             0 |             0 |         0.00
```

Entregável: o que aconteceu, por que ficou verde e o que muda na Dag, em três linhas.

**Gabarito comentado**

Falha silenciosa: o SQL rodou sem erro e não trouxe linha. Verde só quer dizer que o código não lançou exceção. No teste feito para esta apostila (seção 9.1), um dia sem dado novo passou como sucesso no cron, com `bronze=0`, e no Airflow. Sem checagem explícita, nenhum dos dois sabe que zero é problema.

Confira a origem antes de mexer na Dag. Na origem sintética, não houve venda no dia 28, e mesmo assim alguém precisava saber. A mudança está no Exercício 8.

**Exercício 4: O reprocesso que dobrou a semana**

Objetivo: ligar a duplicação à carga, não ao orquestrador.

Contexto: os três dias entraram na gold por um reprocessamento de datas passadas (backfill), que foi a primeira carga deles. Depois de corrigir a silver, alguém rodou o mesmo reprocesso de novo. Tudo terminou em sucesso. A gold:

| Dia | Depois da primeira carga | Depois do reprocesso |
|---|---|---|
| 2026-10-20 | 4 pedidos, 430,90 | 8 pedidos, 861,80 |
| 2026-10-21 | 3 pedidos, 111,90 | 6 pedidos, 223,80 |
| 2026-10-22 | 3 pedidos, 293,30 | 6 pedidos, 586,60 |

Entregável: a causa, a correção antes do próximo reprocesso e o conserto dos dias dobrados.

**Gabarito comentado**

O bronze ingênuo só faz `INSERT`, sem chave. Cada execução acrescenta o dia de novo, e a silver e a gold herdam a cópia. O reprocesso fez o que pedimos: rodou o dia outra vez.

A nova tentativa tem o mesmo efeito. No laboratório, a tarefa gravou, caiu depois do commit e, na nova tentativa, gravou de novo: sucesso, e a gold em 8 pedidos e 861,80. A queda foi simulada, só para o teste.

A correção é o bronze idempotente, do Exercício 7. Ele manteve 4 linhas e 430,90 em duas reexecuções à mão e em dois reprocessos, e consertou um dia já duplicado. Rode-o sobre os dias dobrados.

**Exercício 5: O dia 28 na partição 29**

Objetivo: prever em que partição a carga grava.

Contexto: a loja fecha às 22h. Uma Dag com agenda em cron, sem `interval`, dispara às 22h de Brasília e grava em `dt={{ ds }}`. As vendas do dia 28 aparecem em `dt=2026-10-29`.

Entregável: a explicação em uma frase e a correção.

**Gabarito comentado**

`ds` é a data lógica no formato AAAA-MM-DD, tirada do valor em UTC. O Airflow trabalha em UTC, três horas à frente de Brasília: 22h do dia 28 é 01h do dia 29. Saída do laboratório:

```text
DATAS logical_date=2026-10-29T01:00:00+00:00 (Brasilia 28/10 22:00)
DATAS ds=2026-10-29
```

Corrija calculando o dia do negócio no fuso da loja, a partir da janela convertida para Brasília, como no capítulo 8. O equívoco comum é ler `ds` como "hoje no Brasil".

**Exercício 6: A nova tentativa que escondeu o erro**

Objetivo: ler o grafo que você declarou, não o que imaginou.

Contexto: primeira versão da Dag `registro_de_carga`.

```python
criar_tabelas >> carregar >> checar_repeticao(registrar_carga())
```

Na execução agendada, `registrar_carga` falhou na primeira tentativa com `UndefinedTable`, e a nova tentativa passou. Na carga seguinte, com dois pedidos novos, o registro gravou 5 linhas em vez de 7, e o alerta disparou.

Entregável: o grafo que rodou de fato, a linha corrigida e por que a nova tentativa enganou.

**Gabarito comentado**

Nada põe `registrar_carga` depois da carga. Sem tarefa anterior, ela começou junto com `criar_tabelas` e contou uma tabela que não existia. O orquestrador executa exatamente o grafo declarado.

A nova tentativa passou porque, na hora dela, a tabela já existia. Foi sorte de tempo. Na carga seguinte, a contagem veio antes da carga, repetiu o 5 e gerou um alerta falso. A versão corrigida, com a variável da carga renomeada:

```python
linhas = registrar_carga()
criar_tabelas >> carregar_pedidos_tratados >> linhas
checar_repeticao(linhas)
```

Esta falha é real, não simulada. Tarefa que passa na segunda tentativa merece a leitura do log da primeira.

### 14.3 Nível prático

"Como eu provo que a carga aguenta rodar de novo?"

Os dois exercícios usam o laboratório do capítulo 13, o mesmo dos Labs 1 e 4.

**Exercício 7: Bronze idempotente, provado duas vezes**

Objetivo: tornar o bronze idempotente, em que rodar de novo dá o mesmo resultado de rodar uma vez.

Contexto: o arquivo `bronze_pedidos_ingenuo.sql`.

```sql
-- Naive load: every rerun of the same day appends the same rows again.
INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Entregável: o SQL novo, duas reexecuções do mesmo dia com a saída e a contagem de cópias por pedido.

**Gabarito comentado**

O dia é a unidade que a execução controla. A carga apaga o dia e insere de novo:

```sql
-- Idempotent load: replace the whole day, the caller commits both statements together.
DELETE FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;

INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Os dois comandos ficam na mesma transação. O script do laboratório confirma tudo no fim ou desfaz tudo no erro, então uma queda no meio não deixa o dia vazio. A prova, rodada duas vezes:

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
```

```text
  resultado: bronze=4 silver=4 receita_paga=430.90
  resultado: bronze=4 silver=4 receita_paga=430.90
```

Na versão ingênua, sobre o dia já carregado, as duas rodadas deram 8 e 12 linhas. As cópias por pedido:

```sql
SELECT id, count(*) AS copias FROM bronze.pedidos
WHERE _dia_referencia = '2026-10-20' GROUP BY id ORDER BY id;
```

Na ingênua, cada pedido saiu com 3 cópias. Na idempotente, com uma.

O outro caminho é o UPSERT, inserir ou atualizar pela chave. No laboratório, a carga repetida deu 6 linhas sem chave, falhou com `duplicate key value violates unique constraint` com chave primária e ficou em 3 com `ON CONFLICT DO UPDATE`.

**Exercício 8: Uma checagem que pega carga vazia**

Objetivo: fazer o dia vazio do Exercício 3 virar falha.

Contexto: o arquivo `pipeline_loja.py`, que monta as Dags `loja_ingenua` e `loja_idempotente`, com `bronze(DIA) >> silver >> gold >> registrar`.

Entregável: uma tarefa entre o bronze e a silver que falha com o dia vazio, e quem recebe o aviso.

**Gabarito comentado**

As boas práticas do Airflow mandam pôr checagens dentro da Dag. O `SQLThresholdCheckOperator`, do provider common-sql, confere se um valor fica entre um mínimo e um máximo, cada um número ou consulta SQL. O import vai no topo do arquivo; o resto entra dentro da função que monta a Dag, aqui sem a indentação dela:

```python
from airflow.providers.common.sql.operators.sql import SQLThresholdCheckOperator

checar_bronze = SQLThresholdCheckOperator(
    task_id="checar_bronze",
    conn_id=CONN_ID,
    sql=f"SELECT count(*) FROM bronze.pedidos WHERE _dia_referencia = '{DIA}'::date",
    # At least one row catches the empty load; the source count catches duplicates.
    min_threshold=1,
    max_threshold=(
        "SELECT count(*) FROM replica.pedidos "
        f"WHERE criado_em >= '{DIA}'::date AND criado_em < '{DIA}'::date + 1"
    ),
)

bronze(DIA) >> checar_bronze >> silver >> gold >> registrar
```

Pela documentação do operador, o mínimo 1 faz o dia vazio falhar, e o máximo, tirado da origem, faz falhar também o dia dobrado do Exercício 4. A checagem fica em SQL; o Python só encadeia.

Esta checagem ficou no nível 2: a Dag carrega e as consultas saem com o dia certo, mas ela não rodou contra o banco do laboratório. Antes de confiar nela, ligue-a e repita os cenários dos Exercícios 3 e 4 para ver as duas falhas.

Para virar alerta, ligue um callback de falha, como no capítulo 9. Num dia sem venda, ela falha de verdade. Por isso o aviso chama uma pessoa, e a pessoa decide.

### 14.4 Mini-desafio com solução

"Corrigi a silver. Como refaço três dias sem perder nenhum?"

**Enunciado**

Outra Dag diária da loja, diferente da das 06h dos exercícios anteriores, dispara à meia-noite de Brasília, com janela de um dia. Cada execução processa o dia local que acabou de terminar:

```python
CronTriggerTimetable("0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1))
```

No laboratório, essa agenda é a da Dag `datas_dia_brasilia`, e é ela que aparece nos comandos. O bronze já é idempotente. Reprocesse os dias locais 23, 24 e 25 de outubro de 2026, que já rodaram.

Entregável: o comando e o ensaio que prova, antes de gravar, que entram exatamente os três dias.

**Dicas**

1. Ensaie com `--dry-run`. Ele lista as execuções e não grava nada.
2. Data sem hora vira 00:00 no fuso padrão do Airflow, que vem como UTC, qualquer que seja o fuso da Dag. O fim é inclusivo.
3. Nesta agenda, o filtro olha o disparo. A execução do dia 23 dispara à meia-noite do dia 24.
4. Dias que já rodaram pedem um comportamento de reprocesso que os refaça.

**Solução comentada**

A primeira tentativa costuma ser esta:

```bash
airflow backfill create --dag-id datas_dia_brasilia \
  --from-date 2026-10-23 --to-date 2026-10-25 --dry-run
```

Trecho da saída, sem o cabeçalho e os separadores da tabela:

```text
| 2026-10-22 03:00:00+00:00 |                 |                  |
| 2026-10-23 03:00:00+00:00 |                 |                  |
```

Vieram 22 e 23. Os limites ficaram em 00:00 UTC, e a meia-noite de Brasília é 03:00 UTC. Empurrar um dia, ainda sem hora, também falha: de 24 a 26 vieram 23 e 24. O disparo do dia 25 cai às 03:00 UTC do dia 26, depois do fim.

A solução põe hora explícita nos dois limites, no instante do disparo:

```bash
airflow backfill create --dag-id datas_dia_brasilia \
  --from-date 2026-10-24T03:00:00+00:00 --to-date 2026-10-26T03:00:00+00:00 \
  --reprocess-behavior completed --max-active-runs 1 --dry-run
```

Trecho da saída, com quatro dos parâmetros impressos e sem o cabeçalho e os separadores da tabela:

```text
    - from_date = 2026-10-24 03:00:00+00:00
    - to_date = 2026-10-26 03:00:00+00:00
    - max_active_runs = 1
    - reprocess_behavior = ReprocessBehavior.COMPLETED
| 2026-10-23 03:00:00+00:00 |                 |                  |
| 2026-10-24 03:00:00+00:00 |                 |                  |
| 2026-10-25 03:00:00+00:00 |                 |                  |
```

O porquê de cada escolha:

- **Hora nos limites.** O fim precisa de hora: o disparo do dia 25 cai às 03:00 UTC do dia 26 e, sem hora no fim, ficou de fora. No início, a hora deixa explícito o primeiro disparo; o ensaio de 24 a 26 sem hora já começou na data lógica 23. Com `2026-10-24T00:00:00-03:00` e `2026-10-26T00:00:00-03:00`, o mesmo instante escrito no horário de Brasília, saíram as mesmas três datas; a saída mostrou a primeira com `-03:00`.
- **`--reprocess-behavior completed`.** O padrão pula data que já tem execução.
- **`--max-active-runs 1`.** Um dia por vez contra a réplica.
- **Bronze idempotente antes.** Sem ele, o reprocesso dobra os três dias.

Confirmado o ensaio, rode o mesmo comando sem `--dry-run`.

**Interpretação**

Cada data lógica é o início da janela. 23/10 às 03:00 UTC é meia-noite do dia 23 em Brasília, e a janela vai até a meia-noite do dia 24. No laboratório, as execuções de datas lógicas 22 e 23 às 03:00 UTC cobriram exatamente os dias locais 22 e 23.

Depois, confira a gold e o registro de carga dos três dias. A diretoria vai perguntar se o número de sexta a domingo está certo. O ensaio responde antes de você gravar.

**Verificação do código deste capítulo**

- Código e saídas dos Exercícios 3 a 7 e janelas citadas na Interpretação: nível 3. Executados em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2` (Python 3.13.15), LocalExecutor e Postgres `16.15-alpine`. Os dois SQL do bronze do Exercício 7 são os arquivos do laboratório, rodados pelo serviço `runner` (imagem `python:3.13.15-alpine3.24`) com `python scripts/pipeline.py --dia 2026-10-20` repetido, nos modos idempotente e ingênuo; a consulta de cópias rodou por `psql` logo depois. A primeira versão da dependência do Exercício 6 gerou as saídas da falha; a corrigida é a da Dag `registro_de_carga`, rodada por `airflow dags unpause` e `airflow dags trigger`, e passa em `ruff check --select AIR,E,F,W --preview` e `ruff format --check`, com ruff 0.12.12. Os demais comandos que provaram: `airflow dags trigger loja_ingenua` com a queda simulada; `airflow backfill create` nas Dags `loja_ingenua` e `loja_idempotente`, duas vezes cada; e os valores de data impressos pelas Dags das 22h e da meia-noite de Brasília.
- Agenda do mini-desafio: a da Dag `datas_dia_brasilia` do laboratório, nível 3, na mesma execução.
- Ensaios do mini-desafio: nível 3 no `--dry-run`. Executados em 2026-10-29 com Airflow 3.3.2 instalado por `uv` em Python 3.12.3, banco SQLite novo, sem execuções anteriores. Comando que provou: `airflow backfill create --dag-id datas_dia_brasilia ... --dry-run`, com as quatro janelas citadas. O reprocesso de verdade com esses limites não foi executado.
- Checagem do Exercício 8: nível 2, em 2026-10-29. A Dag da loja com a checagem ligada passou em `ruff check --select E,F,W,I,B,UP --line-length 120` e `ruff format --check --line-length 120`, com ruff 0.12.12, os mesmos do laboratório. Carregou sem erro de importação no Airflow 3.3.2, com providers postgres 7.0.2 e common-sql 2.1.1, e o grafo saiu com `checar_bronze` depois de `bronze` e antes de `silver`. Numa Dag mínima, só com a mesma checagem e a mesma agenda, que passou em `ruff check --select AIR,E,F,W --preview` e `ruff format --check`, o `airflow tasks render` mostrou as duas consultas com o dia 2026-10-20 para a data lógica 2026-10-21 às 09:00 UTC. Não rodou contra o banco.

---

[Índice](../README.md#capítulos) · [Anterior: 13. Laboratório](13-laboratorio.md) · [Próximo: 15. Rubrica de validação da aprendizagem](15-rubrica-de-validacao-da-aprendizagem.md)
