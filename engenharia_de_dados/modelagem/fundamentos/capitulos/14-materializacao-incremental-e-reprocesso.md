---
title: "14. Materialização, incremental e reprocesso"
date: 2026-11-04
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - modelagem
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Anterior: 13. Testes de dado: consultas que precisam voltar vazias](13-testes-de-dado.md) · [Próximo: 15. O mesmo SQL como projeto dbt](15-o-mesmo-sql-como-projeto-dbt.md)

## 14. Materialização, incremental e reprocesso

Os testes dizem quando não publicar. Faltam duas decisões: como guardar o resultado e o que acontece quando a mesma carga roda de novo. Quem decidiu o que uma linha significa já sabe qual é a chave. E é a chave que separa reprocesso de duplicata.

### 14.1 View, table ou incremental?

"Preciso gravar tudo em tabela, ou a view resolve?"

**O que é**

Materialização é a estratégia para guardar o resultado do modelo no banco. O dbt tem cinco tipos embutidos: table, view, incremental, ephemeral e materialized view. Vamos ficar em três. A escolha existe com ou sem ferramenta.

| Forma | O que guarda | Quando processa | Indicação | O preço |
|---|---|---|---|---|
| View | Nada, só a consulta | A cada uso | É o padrão do dbt | Fica lenta quando empilhada |
| Table | O resultado | Refeita a cada execução | O que o BI consulta | Refaz tudo, até o que não mudou |
| Incremental | O resultado acumulado | Só parte dos dados, sobre o que já existe | Nunca como ponto de partida | Chave, reprocesso, atraso e afastamento da origem |

Critério da mentoria: comece em view. Passe para table o que o BI consulta, quando a lentidão aparecer medida no seu banco. Passe para incremental só quando refazer a table ficar lento demais, também medido.

**Como funciona sem ferramenta**

Sem ferramenta, o Postgres já entrega as peças. `CREATE VIEW` não materializa: a consulta roda a cada uso. `CREATE OR REPLACE VIEW` exige as mesmas colunas, com os mesmos nomes, na mesma ordem e com os mesmos tipos, e pode acrescentar colunas no fim. `REFRESH MATERIALIZED VIEW` substitui todo o conteúdo. Numa prova curta, depois de um `INSERT` na tabela base, a view mostrou 2 linhas e a materializada 1. Depois do `REFRESH`, 2 e 2.

> Verificação: nível 3, `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`.

**O equívoco comum**

"Incremental é o jeito profissional." A documentação do dbt diz o contrário: "don't start with incremental models". Incremental troca tempo de execução por decisões que você passa a carregar. O resto do capítulo é essa conta.

### 14.2 A mesma carga, rodada duas vezes

"O orquestrador repetiu a tarefa. O que aconteceu com o meu número?"

**O que é**

A apostila de Orquestração deixou a definição: idempotência é rodar de novo e ter o mesmo resultado de rodar uma vez. O orquestrador repete a tarefa que falha. Por isso a documentação do Airflow pede o mesmo resultado a cada nova tentativa e manda trocar `INSERT` por `UPSERT` (atualizar se a linha existe, inserir se não).

**Como funciona na prática**

Vamos ver por que dobra, na menor carga possível: uma linha por loja e dia.

```sql
-- A daily load with one row per store. Synthetic data.
CREATE TEMP TABLE carga_do_dia (dia date, loja_id int, receita numeric(10,2));
INSERT INTO carga_do_dia VALUES ('2026-10-20', 1, 130.00), ('2026-10-20', 2, 90.00);
CREATE TEMP TABLE fct_dia (dia date, loja_id int, receita numeric(10,2));

-- The same load twice, as an orchestrator retry would do.
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
INSERT INTO fct_dia SELECT * FROM carga_do_dia;

SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;
```

```text
 loja_id | linhas | receita 
---------+--------+---------
       1 |      2 |  260.00
       2 |      2 |  180.00
(2 rows)
```

Nenhum erro. A loja 1 vendeu 130,00, e a tabela diz 260,00. Há dois caminhos de saída. Limpe a tabela antes de cada um e repita o `SELECT` no fim.

```sql
TRUNCATE fct_dia;

-- Path A: replace the window inside one transaction. Run this block twice.
BEGIN;
DELETE FROM fct_dia WHERE dia = '2026-10-20';
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
COMMIT;
```

```sql
TRUNCATE fct_dia;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE (dia, loja_id);

-- Path B: the key lives in the table. Run this INSERT twice.
INSERT INTO fct_dia SELECT * FROM carga_do_dia
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
```

| Caminho, rodado duas vezes | Linhas por loja | Receita da loja 1 |
|---|---|---|
| `INSERT` | 2 | 260,00 |
| `DELETE` da janela e `INSERT`, numa transação | 1 | 130,00 |
| `UNIQUE (dia, loja_id)` e `ON CONFLICT DO UPDATE` | 1 | 130,00 |

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`. O arquivo traz os blocos desta seção e da 14.4, sem `ON_ERROR_STOP`.

Por que a transação? Sem ela, um erro no meio pode deixar a janela pela metade. Na mesma prova, forçamos um erro no `INSERT` depois do `DELETE`: o `ROLLBACK` deixou a janela como estava, com 1 linha e 130,00. No teste do capítulo 19, rodado à mão, o script que falhou no meio apagou a carga anterior, gravou metade da nova e o `psql` saiu com 0. Com `ON_ERROR_STOP` e `--single-transaction`, saiu com 3 e preservou o estado anterior.

Critério da mentoria: refaz a janela inteira? `DELETE` e `INSERT`. A chave é estável e a tabela aceita `UNIQUE`? `ON CONFLICT`.

### 14.3 O mesmo reprocesso no dbt

"A ferramenta me protege sozinha?"

**Como funciona na prática**

Só se você der a chave a ela. No Lab 6, dois modelos leem os mesmos 4 atendimentos com o mesmo filtro.

```sql
{{ config(materialized='incremental') }}

-- No unique_key: dbt appends, so the lookback window duplicates rows on every reprocess.
select atendimento_id, loja_id, dia_local
from {{ ref('stg_atendimentos') }}
{% if is_incremental() %}
where dia_local >= (select max(dia_local) from {{ this }})
{% endif %}
```

O outro modelo muda a primeira linha e o comentário:

```sql
{{ config(materialized='incremental', unique_key='atendimento_id') }}
```

Rode o `dbt build` duas vezes e conte as linhas:

```text
  modelo   | linhas | atendimentos 
-----------+--------+--------------
 sem_chave |      5 |            4
 com_chave |      4 |            4
(2 rows)
```

> Verificação: nível 3. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, `postgres:16.15-alpine`, 2026-11-03. Primeira carga com `docker compose --profile dbt run --rm dbt dbt build --select tag:experimento --vars '{experimentos: true}'`. Reprocesso com `docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'`. Saída em `lab/saidas/lab6_testes_que_param.txt`. Nível 2: `dbt parse` em `lab/saidas/lab5_projeto_dbt.txt` e o SQL compilado em `target/compiled`.

Vamos ver por que deu 5, e não 8. O filtro traz de volta só o último dia, que tem 1 atendimento. A segunda execução registra `INSERT 0 1` nos dois modelos. Sem chave, essa linha fica repetida. Com chave, o adaptador usa `delete+insert`: o `logs/dbt.log` mostra `delete from` antes do `insert`, e o total fica em 4.

O teste `unique` do capítulo 13 acusa a diferença: `FAIL 1` no modelo sem chave, `PASS` no outro, e o `dbt build` sai com 1. Depois, `--full-refresh` reconstruiu o modelo sem chave com 4.

**O que é**

Sem `unique_key`, a maioria dos adaptadores só acrescenta (append), sem olhar se a linha é duplicata. No `dbt-postgres`, as estratégias são `append`, padrão sem chave; `merge`; `delete+insert`, padrão com chave; e `microbatch`. Se a regra mudou, `--full-refresh` derruba a tabela e reconstrói tudo.

### 14.4 Tenho chave. Estou protegido?

"O que ainda duplica depois da chave única?"

**Chave com nulo**

Por padrão, dois nulos não colidem numa restrição `UNIQUE`. O `ON CONFLICT` não vê o conflito. Continue na tabela do caminho B:

```sql
-- Run this INSERT twice: the nulls do not collide.
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;

SELECT count(*) AS linhas FROM fct_dia WHERE dia = '2026-10-23';
```

```text
 linhas 
--------
      2
(1 row)
```

Com a restrição refeita como `UNIQUE NULLS NOT DISTINCT (dia, loja_id)`, as mesmas duas cargas deram 1 linha. O dbt faz o mesmo aviso: coluna de `unique_key` com nulo pode gerar duplicata.

Critério da mentoria: não esconda na restrição um defeito da chave. Ponha `not_null` ao lado do `unique`, como no capítulo 13, e decida o que aquele nulo significa, como no capítulo 7.

**Chave repetida no lote**

Agora a própria carga traz a mesma chave duas vezes. Testamos cada comando em separado, com chave nova e com chave já gravada no alvo.

```sql
-- A batch with the same key twice.
CREATE TEMP TABLE lote (dia date, loja_id int, receita numeric(10,2));
INSERT INTO lote VALUES ('2026-10-22', 1, 10.00), ('2026-10-22', 1, 20.00);

INSERT INTO fct_dia SELECT * FROM lote
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;

MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);

DELETE FROM fct_dia f USING lote l WHERE f.dia = l.dia AND f.loja_id = l.loja_id;
INSERT INTO fct_dia SELECT * FROM lote;
```

| Comando | Chave nova no alvo | Chave já no alvo |
|---|---|---|
| `ON CONFLICT DO UPDATE` | `ON CONFLICT DO UPDATE command cannot affect row a second time` | O mesmo erro |
| `MERGE`, com `UNIQUE` | `duplicate key value violates unique constraint` | `MERGE command cannot affect row a second time` |
| `MERGE`, sem `UNIQUE` | Grava as duas, `MERGE 2`, 30,00 | `MERGE command cannot affect row a second time` |
| `DELETE ... USING` e `INSERT`, numa transação, sem `UNIQUE` | Grava as duas, 30,00 | Grava as duas, 30,00 |

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`. O `DELETE` e o `INSERT` rodaram entre `BEGIN` e `COMMIT`.

Erro é o caso bom: a carga parou, e o alvo ficou como estava. O caso ruim é o silencioso: duas linhas e 30,00 numa chave só. A documentação do `MERGE` explica a diferença: `INSERT` repetido causa violação de unicidade; `UPDATE` ou `DELETE` repetido, violação de cardinalidade.

E no dbt? O `delete+insert` apaga as chaves do lote e insere o lote inteiro, sem deduplicar. Lendo a macro `default__get_delete_insert_merge_sql`, a chave repetida entraria duas vezes. Nível 1: leitura de código, não executamos esse caso no dbt.

Critério da mentoria: deduplique o lote antes de gravar, por chave e com desempate explícito, como no capítulo 6. Depois da carga, rode `unique`.

Tudo aqui rodou em Postgres, em Linux. Em outro banco, confira o comportamento antes de confiar na tabela. O `MERGE` em T-SQL está no capítulo 17.

### 14.5 O fato que chega atrasado

"O atendimento de ontem só apareceu hoje. Ele entra?"

**O equívoco comum**

"Filtro por `max(updated_at)` e todo dado novo entra." Não entra. O incremental filtrado assim perde o fato que chega atrasado. O dbt recomenda uma janela de volta (lookback window) junto com `unique_key`. E admite o limite: os incrementais "inevitably drift from the source data over time", ou seja, se afastam da origem com o tempo.

**Como funciona na prática**

Numa prova curta, com `atendimento_id` como chave e `ON CONFLICT`, só muda o `WHERE`:

```sql
-- Looks forward only: the late row is older than the target's maximum.
WHERE dia >= (SELECT max(dia) FROM alvo)

-- Lookback window of one day: the key absorbs the rows that come back.
WHERE dia >= (SELECT max(dia) FROM alvo) - 1
```

| Situação, com o alvo já no dia 21 | Na origem | No alvo |
|---|---|---|
| Chega um atendimento do dia 20, filtro no máximo | 3 | 2 |
| O mesmo caso, janela de um dia | 3 | 3 |
| Chega outro, do dia 18, fora da janela | 4 | 3 |

> Verificação: nível 3, `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`.

A última linha é o afastamento que o dbt admite. A janela só alcança o atraso que cabe nela. O filtro do Lab 6 é o caso mínimo: volta só ao último dia.

Critério da mentoria: meça o maior atraso real da sua origem antes de escolher a janela. Lembre que janela sem chave duplica, como na seção 14.3. E agende uma reconstrução com `--full-refresh`, conferindo o total contra a origem. Ela só funciona enquanto a camada anterior ainda guarda o dado.

### 14.6 O histórico cabe num incremental?

"Posso guardar o histórico do preço com incremental?"

Não. `delete+insert` apaga a linha antiga e não guarda histórico. A documentação do dbt é direta: "For SCD2, use dbt snapshots, not delete+insert". O tipo 2 do capítulo 11 cria uma linha nova a cada mudança. O incremental com chave substitui a linha. O capítulo 15 mostra o snapshot.

**Como decidir**

Critério da mentoria, para revisar qualquer incremental:

1. Qual é o grão, e que coluna o garante?
2. A chave pode ter nulo?
3. O lote pode trazer a chave repetida?
4. Qual é o maior atraso da origem, e a janela o cobre?
5. Se a tarefa rodar duas vezes, o que muda no total?

Alguma resposta foi "não sei"? Fique na table até saber.

Decidido como guardar, falta organizar. No próximo capítulo, o mesmo SQL vira projeto dbt, e vamos conferir se o número continua o mesmo.

---

[Índice](../README.md#capítulos) · [Anterior: 13. Testes de dado: consultas que precisam voltar vazias](13-testes-de-dado.md) · [Próximo: 15. O mesmo SQL como projeto dbt](15-o-mesmo-sql-como-projeto-dbt.md)
