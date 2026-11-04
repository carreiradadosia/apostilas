---
title: "20. Laboratório"
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

[Índice](../README.md#capítulos) · [Anterior: 19. Onde a regra mora: a decisão de quem gerencia](19-onde-a-regra-mora.md) · [Próximo: 21. Exercícios, entregáveis e mini-desafio](21-exercicios-entregaveis-e-mini-desafio.md)

## 20. Laboratório

"Li até aqui. Dá para ver isso acontecendo na minha máquina, sem servidor e sem nuvem?"

Dá. O laboratório leva a rede de lojas fictícia do dado cru ao número da diretoria. Você sobe o ambiente, roda a silver e a gold e vê a receita de 430,90 no dia 20. Depois dobra a carga de itens e vê o dbt parar onde o SQL à mão publica 741,80. O laboratório mostra o que acontece quando ninguém testa o que uma linha significa.

### 20.1 O que preciso e o que pode dar errado?

"Preciso instalar o quê? Isso mexe em alguma coisa minha?"

**O que protege você**

- Todos os dados são sintéticos.
- Nenhuma porta é publicada na sua máquina. Todo comando entra pelo Docker.
- Nenhuma credencial aparece neste texto. O `./preparar.sh` gera o `.env` com segredos aleatórios, e o `.gitignore` deixa esse arquivo fora do Git.

**O que você precisa ter**

Docker com Compose, terminal com bash e internet na primeira vez. O capítulo 0 traz o comando que confere. Tudo rodou em Linux x86-64. Não testamos em Windows nem em máquina de 8 GB.

| O quê | Medido em 2026-11-03 |
|---|---|
| Imagem do Postgres | 294 MB |
| Imagem do dbt | 531 MB |
| Imagem do Airflow com dbt, só no Lab 7 | 2,65 GB |
| Volume do Postgres, depois de todos os Labs | cerca de 74 MB |
| Postgres em repouso | 31 a 41 MiB |
| Pico do processo do dbt, conforme o comando | 112 a 151 MiB |
| Pico do contêiner do Airflow com dbt | 370 a 435 MiB |

> Verificação: nível 3, num Linux de 14 CPUs e 31 GB, com `docker image ls`, `docker system df -v`, `docker stats` e o log de recursos do dbt. Saídas: `lab/saidas/recursos_medidos.txt` e `lab/saidas/lab0_subir_do_zero.txt`. A ordem de grandeza é firme; as faixas variam por rodada.

Os Labs 8 e 9 têm exigências próprias: a licença do SQL Server, lida antes do comando, e a memória que o `README.md` de cada pasta pede. Não publicamos medida de SQL Server, e o Lab 8 diz por quê.

Quer rodar sem Postgres? `lab/alternativa_duckdb/` traz um projeto menor, que não reproduz estes Labs e não saiu mais leve em memória que Postgres mais dbt.

**Onde está e como ler**

O laboratório fica em `engenharia_de_dados/modelagem/dbt/lab/`, no repositório clonado. A partir daqui, `lab/` é essa pasta. Rode tudo de dentro dela, salvo quando o Lab mandar entrar em subpasta.

Os comandos são as linhas `$` das capturas. A saída esperada é trecho dessas capturas, e `lab/saidas/` guarda o arquivo inteiro. Nas linhas do dbt e do Airflow, cortamos o carimbo de hora e o prefixo de log. O `[exit 0, 2026-11-03]` não vem do comando: o script de captura acrescenta o código de saída e a data. Na sua rodada, confira com `echo $?`.

**Por onde começar**

| Lab | O que você vê | Para quem é, critério da mentoria |
|---|---|---|
| Lab 0 | Subir o ambiente | todo mundo |
| Lab 1 | A silver à mão | todo mundo |
| Lab 2 | Fuso e datas | todo mundo |
| Lab 3 | Estrela, one big table e fan-out | todo mundo |
| Lab 4 | O preço, o `UPDATE` e o tipo 2 | todo mundo |
| Lab 5 | O mesmo fluxo em dbt | quem avalia uma ferramenta |
| Lab 6 | Testes que param | quem avalia uma ferramenta |
| Lab 7 | O dbt numa Dag | quem já usa orquestrador |
| Lab 8 | Silver e gold em T-SQL | quem tem SQL Server |
| Lab 9 | Que SQL um relatório roda | quem precisa achar de onde vem um número |

Os Labs 0 a 7 são uma sequência: cada um parte do estado do anterior. Os Labs 8 e 9 são projetos à parte. Parar no Lab 4 é caminho válido, critério da mentoria. Você já terá silver, estrela e histórico em SQL à mão.

### Lab 0: Subir o ambiente

"O que é esse `.env`? E esse `down -v` não apaga nada meu?"

Pré-condição: Docker com Compose e a pasta `lab/` clonada.

```bash
./preparar.sh
docker compose --profile dbt down -v
docker compose --profile dbt config -q && echo compose ok
docker compose up -d --wait postgres
docker compose exec -T postgres psql -U dw -d dw -c "select version()" -c "\dn" -c "select count(*) as tabelas_na_replica from information_schema.foreign_tables"
docker compose --profile dbt build --no-cache --progress=plain dbt
docker image ls --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -E "^(postgres:16.15-alpine|modelagem-lab-dbt:local|python:3.13.15-slim-bookworm) "
```

O `down -v` só alcança este projeto: contêiner, rede e volume do `modelagem-lab`. Na primeira vez, não há o que apagar. Nas seguintes, ele apaga as tabelas do laboratório, e é por isso que o começo fica limpo.

Saída esperada, em trechos:

```text
.env já existe, nada a fazer.
compose ok
 Container modelagem-lab-postgres-1  Healthy
 PostgreSQL 16.15 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit

       List of schemas
   Name   |       Owner       
----------+-------------------
 bronze   | dw
 controle | dw
 gold     | dw
 public   | pg_database_owner
 replica  | dw
 silver   | dw
(6 rows)

 tabelas_na_replica 
--------------------
                  7
(1 row)

 modelagem-lab-dbt:local  Built
modelagem-lab-dbt:local 531MB
postgres:16.15-alpine 294MB
python:3.13.15-slim-bookworm 121MB
```

Na captura, o `.env` já existia. Na sua primeira vez, o script cria o arquivo e avisa na tela. O aviso do Compose sobre `--progress` não é erro.

**Por que tudo tem versão fixa?**

Porque sem lock (arquivo que trava a versão de cada pacote) o ambiente muda em dias. Resolvendo `dbt-core` 1.12.6 em 2026-11-03, a dependência indireta `dbt-core-experimental-parser` saiu 2.0.11, e o lock de 2026-11-01 tem 2.0.8. Com o lock de 59 pacotes, a captura instala `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, que declaram Python 3.10 a 3.14. O PostgreSQL 16 tem suporte até 2028-11-09.

**Se a imagem não construir**

A construção usa a rede bridge do Docker, e a captura terminou com saída 0 por ela. Mais cedo, no mesmo dia, essa rede ficou sem saída para a internet, por problema do host, não do laboratório. Se acontecer com você, a captura registra também a construção pela rede do host, com o mesmo `Dockerfile` e o mesmo lock:

```bash
docker build --network host --no-cache --progress=plain -t modelagem-lab-dbt:local runner
```

> Verificação: nível 3, em 2026-11-03, em Linux. Imagens `postgres:16.15-alpine` (digest `sha256:0cefaabd882e42bcb2a2f3dc56d3ce4770560ba62fd7f197f1a2e008fd5731ab`) e `python:3.13.15-slim-bookworm`. Saídas: `lab/saidas/lab0_subir_do_zero.txt` e `lab/saidas/lab0_construir_imagem_dbt.txt`. Resolução sem lock em nível 2, com `uv pip compile` e Python 3.13.

### Lab 1: A silver à mão

"O tratamento que eu tenho medo de escrever cabe em SQL puro?"

Pré-condição: Lab 0 concluído, Postgres de pé.

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/10_bronze_carga.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-20 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql
```

Saída esperada, em trechos:

```text
     tabela      | linhas 
-----------------+--------
 bronze.pedidos  |     11
 replica.pedidos |     10
(2 rows)

          tabela          | linhas 
--------------------------+--------
 silver.pedidos           |     10
 silver.itens             |     13
 silver.lojas             |      3
 silver.produtos          |      5
 silver.produtos_vigencia |      5
 silver.atendimentos      |      4
(6 rows)

    status    | pedidos | valor  
--------------+---------+--------
 cancelado    |       1 |  45.00
 desconhecido |       1 |  80.50
 pago         |       7 | 836.10
 pendente     |       1 |  15.00
(4 rows)

 margem_soma_ignora_nulo | margem_com_zero | itens_sem_custo 
-------------------------+-----------------+-----------------
                  397.10 |          409.10 |               1
(1 row)
```

Confira três coisas. A bronze tem 11 pedidos, e a silver, 10: o pedido 103 chegou duas vezes, e ficou o último estado. O status nulo virou `desconhecido` e segue visível. O custo nulo segue nulo: com zero no lugar, a margem iria de 397,10 para 409,10.

Dois detalhes não são erro. Os `NOTICE` de tabela que não existe aparecem na primeira rodada. E a coluna `carregado_utc` do pedido 103 traz o dia em que você rodou; na captura, 2026-11-03.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab1_silver_a_mao.txt`.

### Lab 2: Fuso e datas

"Por que tem atendimento à meia-noite numa loja que fecha às 22h?"

Pré-condição: Lab 1 concluído.

```bash
docker compose exec -T postgres psql -U dw -d dw -f /sql/22_fuso.sql
```

Saída esperada, em trechos:

```text
== O atendimento da meia-noite. Loja fecha às 22h; a origem grava UTC em coluna sem fuso.
 id |     loja      | fecha_as |   lido_como_esta    |        certo        
----+---------------+----------+---------------------+---------------------
  1 | Loja Centro   | 22:00:00 | 2026-10-20 13:15:00 | 2026-10-20 10:15:00
  2 | Loja Centro   | 22:00:00 | 2026-10-21 00:25:00 | 2026-10-20 21:25:00
  3 | Loja Norte    | 22:00:00 | 2026-10-21 00:50:00 | 2026-10-20 21:50:00
  4 | Loja São João | 20:00:00 | 2026-10-21 12:00:00 | 2026-10-21 09:00:00
(4 rows)

psql:/sql/22_fuso.sql:43: ERROR:  date/time field value out of range: "31/02/2026"
[exit 0, 2026-11-03]
```

Os atendimentos 2 e 3 mudam de dia depois da conversão. O `ERROR` é de propósito: uma data impossível para o comando. Este script roda sem `ON_ERROR_STOP`, por isso segue até o fim e sai com 0. Guarde isso para o Lab 6: saída 0 não prova que deu certo.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab2_fuso_e_datas.txt`.

### Lab 3: Estrela, one big table e fan-out

"Onde aparece o número da diretoria? E como ele dobra sem dar erro?"

Pré-condição: Lab 1 concluído. Por enquanto, só existe a foto do dia 20.

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql
```

Saída esperada, em trechos:

```text
SELECT 92
SELECT 3
SELECT 6
SELECT 13
SELECT 3
CREATE VIEW
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       430.90
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
(3 rows)

 linhas_fct | chaves_fct | itens_silver | linhas_obt | receita_obt 
------------+------------+--------------+------------+-------------
         13 |         13 |           13 |         13 |      836.10
(1 row)

== Fan-out 1: dimensão com duas linhas para a mesma chave. Sem erro nenhum.
 linhas | receita_dobrada 
--------+-----------------
      9 |          850.90
(1 row)

== O teste do grão, em SQL puro: devolve linhas quando quebra.
        tabela        | chaves_repetidas 
----------------------+------------------
 fct_vendas           |                0
 itens com fornecedor |                5
(2 rows)
```

Aí está o 430,90. O mesmo dia dá 850,90 com um JOIN a mais, e nada avisa. Só o teste do grão acusa. No começo da saída, o `SELECT 6` é a dimensão de produto: 5 produtos e o membro `'-1'`. Cada rodada da gold acrescenta uma linha em `controle.carga`, então rodar de novo faz esse registro crescer. É o esperado.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

### Lab 4: O preço, o `UPDATE` e o tipo 2

"O sistema troca o preço toda noite. O de ontem sumiu mesmo?"

Pré-condição: Lab 3 concluído. Os scripts `erp_noite` fazem o papel do ERP sobrescrevendo o preço.

```bash
docker compose exec -T postgres psql -U erp -d erp -v ON_ERROR_STOP=1 -f /sql/erp_noite_21.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-21 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U erp -d erp -v ON_ERROR_STOP=1 -f /sql/erp_noite_22.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-22 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/30_gold.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql
```

Saída esperada, em trechos:

```text
== SCD tipo 2 derivado das fotos, por vigência.
 produto_id | preco | valido_de  | valido_ate 
------------+-------+------------+------------
         10 | 60.00 | 2026-10-20 | 
         20 | 33.30 | 2026-10-20 | 
         30 | 15.00 | 2026-10-20 | 2026-10-22
         30 | 17.00 | 2026-10-22 | 
         40 | 20.50 | 2026-10-20 | 2026-10-22
         40 | 20.00 | 2026-10-22 | 
         50 | 12.00 | 2026-10-20 | 
(7 rows)

== Custo de cada caminho: linhas guardadas.
 linhas_nas_fotos | linhas_no_tipo_2 
------------------+------------------
               15 |                7
(1 row)

== BETWEEN com limites fechados: a venda no dia da troca casa com duas versões.
 pedido_id | item_seq | dia_local  | versoes_casadas | valor_somado 
-----------+----------+------------+-----------------+--------------
       108 |        2 | 2026-10-22 |               2 |       160.00
(1 row)
```

A origem guarda só o preço de hoje. As fotos guardam os três dias, e a silver monta a vigência. A receita segue em 430,90, 111,90 e 293,30.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab4_preco_update_e_scd2.txt`.

### Lab 5: O mesmo fluxo em dbt

"O dbt muda o número ou só muda quem roda?"

Pré-condição: Lab 4 concluído, porque o snapshot lê as três fotos, e imagem do dbt construída no Lab 0.

```bash
docker compose --profile dbt run --rm dbt dbt --version
docker compose --profile dbt run --rm dbt dbt debug
docker compose --profile dbt run --rm dbt dbt parse
docker compose --profile dbt run --rm dbt dbt seed
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-21"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-22"}'
docker compose exec -T postgres psql -U dw -d dw -c "select id, preco, dbt_valid_from, dbt_valid_to from dbt_snapshots.snap_produtos_preco order by id, dbt_valid_from" -c "select (select count(*) from dbt_snapshots.snap_produtos_preco) as linhas_check, (select count(*) from dbt_snapshots.snap_produtos_por_timestamp) as linhas_timestamp"
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/50_comparar_a_mao_e_dbt.sql
cat projeto_dbt/target/compiled/rede_de_lojas/models/gold/fct_vendas.sql
docker compose --profile dbt run --rm dbt dbt docs generate
```

A captura guarda duas passadas de snapshot: a segunda apaga as tabelas e refaz, com o mesmo resultado. Você precisa de uma.

Saída esperada, em trechos:

```text
  - installed: 1.12.6
  - postgres: 1.11.0 - Up to date!
dbt v2 is available, and is the default for new installations. This is dbt Core v1.

All checks passed!

 linhas_check | linhas_timestamp 
--------------+------------------
            7 |               15
(1 row)

[WARNING]: in test assert_status_desconhecido (tests/assert_status_desconhecido.sql)
[WARNING]: Got 1 result, configured to warn if != 0
[WARNING]: in test not_null_stg_produtos_custo (models/silver/_silver.yml)
[WARNING]: Got 1 result, configured to warn if != 0
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46

         tabela         | so_a_mao | so_dbt 
------------------------+----------+--------
 vendas_por_dia         |        0 |      0
 fct_vendas             |        0 |      0
 dim_produto            |        0 |      0
 pedidos da silver      |        0 |      0
 atendimentos da silver |        0 |      0
(5 rows)

 lado  | linhas | chaves 
-------+--------+--------
 a_mao |      8 |      8
 dbt   |      8 |      8
(2 rows)
```

Vamos ler. São 46 nós: 1 seed, 2 snapshots, 5 modelos de tabela, 6 de view e 32 testes de dado. Os dois avisos são de propósito: contam o status desconhecido e o custo nulo. A tabela de zeros compara as duas execuções nos dois sentidos, já com a chave `produto_sk`. O dbt não mudou o número. A dimensão tem 8 linhas, 7 versões e o membro `'-1'`. O snapshot `check` tem 7 linhas; o de `timestamp` tem 15, porque o ERP carimba o produto toda noite, mesmo sem mudar o preço.

Quer ver de onde `fct_vendas` lê? Este comando usa o `python3` da sua máquina. Sem ele, pule: nada adiante depende disso.

```bash
ls -la projeto_dbt/target/index.html projeto_dbt/target/catalog.json projeto_dbt/target/manifest.json | awk "{print \$5, \$9}" && python3 -c "import json; m = json.load(open(\"projeto_dbt/target/manifest.json\")); print(\"pais de fct_vendas:\", sorted(m[\"parent_map\"][\"model.rede_de_lojas.fct_vendas\"]))"
```

```text
pais de fct_vendas: ['model.rede_de_lojas.dim_loja', 'model.rede_de_lojas.dim_produto', 'model.rede_de_lojas.stg_itens', 'model.rede_de_lojas.stg_pedidos']
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse` e pelo SQL compilado, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Saída: `lab/saidas/lab5_projeto_dbt.txt`.

### Lab 6: Testes que param

"Se a carga vier duplicada, quem me avisa antes da diretoria?"

Pré-condição: Lab 5 concluído. Aqui `exit 1` é o resultado certo em três comandos.

Primeiro, dois defeitos de propósito, nos modelos `experimentos`:

```bash
docker compose --profile dbt run --rm dbt dbt build --select tag:experimento --vars '{experimentos: true}'
docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'
docker compose exec -T postgres psql -U dw -d dw -c "select 'sem_chave' as modelo, count(*) as linhas, count(distinct atendimento_id) as atendimentos from dbt_experimentos.exp_inc_sem_chave union all select 'com_chave', count(*), count(distinct atendimento_id) from dbt_experimentos.exp_inc_com_chave"
docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave --full-refresh --vars '{experimentos: true}'
```

```text
[ERROR]: in test unique_exp_fct_fan_out_venda_sk (models/experimentos/_experimentos.yml)
  Got 5 results, configured to fail if != 0
Done. PASS=5 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=6
[exit 1, 2026-11-03]

[ERROR]: in test unique_exp_inc_sem_chave_atendimento_id (models/experimentos/_experimentos.yml)
  Got 1 result, configured to fail if != 0
Done. PASS=3 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=4
[exit 1, 2026-11-03]

  modelo   | linhas | atendimentos 
-----------+--------+--------------
 sem_chave |      5 |            4
 com_chave |      4 |            4
(2 rows)

Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

O teste de grão pega o fan-out. O incremental sem chave duplica no reprocesso, e o `--full-refresh` refaz. Agora o caso principal. Dobre a carga de itens e rode os dois executores:

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -c "select g.dia, g.receita_paga as gold_a_mao, d.receita_paga as gold_dbt from gold.vendas_por_dia g join dbt_gold.vendas_por_dia d using (dia) order by dia"
```

Saída esperada, em trechos:

```text
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       741.80
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
(3 rows)

[exit 0, 2026-11-03]

[ERROR]: in test unique_stg_itens__pedido_id_item_seq_ (models/silver/_silver.yml)
  Got 2 results, configured to fail if != 0
[ERROR]: in test assert_itens_batem_com_pedido (tests/assert_itens_batem_com_pedido.sql)
  Got 1 result, configured to fail if != 0
Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
[exit 1, 2026-11-03]

    dia     | gold_a_mao | gold_dbt 
------------+------------+----------
 2026-10-20 |     741.80 |   430.90
 2026-10-21 |     111.90 |   111.90
 2026-10-22 |     293.30 |   293.30
(3 rows)
```

Vamos ver por que dobrou e quem parou. O SQL à mão saiu com 0 e publicou 741,80. O dbt achou a chave repetida, saiu com 1 e pulou 15 nós, e a gold dele manteve 430,90. O teste não melhora o dado: impede que o dado ruim chegue ao número.

O SQL à mão não está errado por ser à mão. Faltou a ele o teste, e os testes do capítulo 13 cabem em SQL puro.

Agora conserte. Refaça a bronze e rode os dois de novo:

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/10_bronze_carga.sql -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile dbt run --rm dbt dbt build
```

```text
 executor | linhas_bronze | linhas_silver | receita_paga 
----------+---------------+---------------+--------------
 a_mao    |            11 |            10 |       836.10
 a_mao    |            11 |            10 |       836.10
 a_mao    |            11 |            10 |      1147.00
 a_mao    |            11 |            10 |       836.10
(4 rows)

Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]
```

O registro de carga guarda o 1147,00 da rodada ruim. É assim que você descobre depois quando o número mudou.

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Saída: `lab/saidas/lab6_testes_que_param.txt`.

### Lab 7: O dbt numa Dag

"O que o orquestrador faz quando o dbt para?"

Pré-condição: Lab 6 concluído e consertado, com espaço para a imagem de 2,65 GB. O código de limpeza continua no projeto dbt, fora do arquivo da Dag: o orquestrador não é o código de limpeza, é quem roda o código.

```bash
docker build --network host --progress=plain -f orquestrador/Dockerfile -t modelagem-lab-airflow-dbt:local .
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/10_bronze_carga.sql -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
```

Saída esperada, em trechos, sem o prefixo de log do Airflow:

```text
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]

Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
airflow.sdk.exceptions.AirflowException: Bash command failed. The command returned a non-zero exit code 1.
DagRun failed
[exit 1, 2026-11-03]

Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]
```

A Dag tem uma tarefa só, com `BashOperator`. O código de saída 1 do dbt vira `AirflowException`, e tarefa e execução falham. A mesma Dag volta ao sucesso depois do conserto do dado. Na captura, a imagem já estava em cache; na sua primeira vez, ela constrói o ambiente virtual do Python (virtualenv) do dbt.

> Verificação: nível 3, em 2026-11-03, em Linux, com `apache/airflow:3.3.2-python3.13`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. Saídas: `lab/saidas/lab7_orquestrador_construir_imagem.txt` e `lab/saidas/lab7_orquestrador_roda_dbt.txt`.

### Lab 8: Silver e gold em T-SQL

"Meu banco é SQL Server. Os mesmos tratamentos dão o mesmo número?"

**Antes do comando: a licença**

Este Lab roda o SQL Server na edição Developer. Leia os termos da versão que vai usar:

- SQL Server 2022: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- SQL Server 2025: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf

Os links de licença das páginas da imagem não levam ao termo da versão, então use estes. O que lemos, sem ser parecer jurídico:

- A Developer da 2022 pode ser instalada e usada em qualquer dispositivo para projetar, desenvolver, testar e demonstrar programas, e não pode ser usada em produção (seção 1.a.i).
- Os termos não citam contêiner. A Microsoft publica a imagem com Developer no registro e documenta como rodá-la.
- Os termos da 2025 mantêm o uso e dividem a edição em Enterprise Developer e Standard Developer.
- A seção 5 exige aprovação prévia por escrito da Microsoft para divulgar resultado de benchmark. Por isso as capturas têm só a data, e aqui não há tempo nem comparação de desempenho. Se você medir, não publique sem essa aprovação.

`ACCEPT_EULA=Y` é ato seu, de quem leu. Por isso o `docker-compose.yaml` não traz o aceite. Ao passar `Y` com uma edição em `MSSQL_PID`, você declara ter licença válida para aquela edição e versão.

Não confie na trava. O `${ACCEPT_EULA:?}` só barra a variável vazia ou ausente. A imagem 2022 subiu e ficou saudável com `N`, com um texto qualquer e com `1`. Nem a trava nem o contêiner de pé provam que alguém leu.

**Rodar**

Pré-condição: termos lidos, Docker com Compose e a memória que o `README.md` da pasta pede. O projeto é à parte e não depende dos outros Labs.

```bash
cd sqlserver
./preparar.sh
ACCEPT_EULA=Y ./roteiro.sh 2022
```

O roteiro parte de um volume vazio, roda cada etapa, grava a saída e derruba tudo com `docker compose down -v`. Ele reescreve `saidas/2022`: para guardar a sua rodada à parte, passe `SAIDA=<pasta>`. Um passo usa o `python3` da máquina. As etapas que criam os bancos, espelham os Labs 1 a 4 e conferem o resultado contra o Postgres são estas, nesta ordem:

```bash
./sq.sh master 00_erp_e_dw.sql -b
./sq.sh dw 10_bronze_carga.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-20
./sq.sh dw 20_silver.sql -b
./sq.sh dw 21_silver_antes_depois.sql
./sq.sh dw 22_fuso.sql
./sq.sh dw 30_gold.sql -b
./sq.sh dw 31_fan_out.sql
./sq.sh erp erp_noite_21.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-21
./sq.sh erp erp_noite_22.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-22
./sq.sh dw 20_silver.sql -b
./sq.sh dw 30_gold.sql -b
./sq.sh dw 40_preco_update_apaga.sql
./sq.sh dw 70_conferencia_postgres.sql
```

Depois vêm as etapas próprias do T-SQL: a etapa de texto e collation, datas em texto, nulos, deduplicação, `MERGE` e recarga, chave substituta, versões, sintaxe do Postgres que não passa, erro na recarga e texto só com tab. Cada uma tem arquivo em `lab/sqlserver/saidas/2022/`, e o capítulo 17 as lê.

Saída esperada, em trechos. Primeiro, a trava e o certificado, em `lab/sqlserver/saidas/2022/lab0_ambiente.txt`:

```text
$ env -u ACCEPT_EULA docker compose config --quiet
error while interpolating services.mssql.environment.ACCEPT_EULA: required variable ACCEPT_EULA is missing a value: read the SQL Server license terms linked in README.md, then rerun with ACCEPT_EULA=Y to accept them
[exit 1, 2026-11-03]

Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : SSL Provider: [error:0A000086:SSL routines::certificate verify failed:self-signed certificate].
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Client unable to establish connection. For solutions related to encryption errors, see https://go.microsoft.com/fwlink/?linkid=2226722.
[exit 1, 2026-11-03]
```

O segundo erro também é de propósito: sem `-C`, o `sqlcmd` recusa o certificado autoassinado do contêiner. Ele fica em `/opt/mssql-tools18/bin`; o caminho antigo, `/opt/mssql-tools/bin`, não existe nas imagens testadas. O `sq.sh` passa `-C` e usa a senha em `SQLCMDPASSWORD`, porque a documentação chama `-P` de inseguro.

Depois, a conferência contra o Postgres, em `lab/sqlserver/saidas/2022/lab5_conferencia_postgres.txt`:

```text
item|postgres|sql_server|resultado
----|--------|----------|---------
gold.dim_produto, linhas|8.00|8.00|bate
gold.dim_produto, membro -1|1.00|1.00|bate
gold.fct_vendas, vendas no membro -1|.00|.00|bate
receita paga, dia 20|430.90|430.90|bate
receita paga, total|836.10|836.10|bate
fan-out 1, receita dobrada|850.90|850.90|bate

(32 rows affected)
```

As 32 linhas dão `bate`, nenhuma `DIVERGE`. O mesmo vale na 2025 Enterprise Developer e na 2025 Standard Developer. A conferência não exercita a collation: quem testa isso é a etapa de texto e collation.

Na 2025, o `MSSQL_PID` decide a edição. A tabela da documentação lista `EnterpriseDeveloper` e `StandardDeveloper`, sem `Developer`, e o exemplo de Docker da mesma página passa `Developer`. Veja o que sobe de fato:

```bash
ACCEPT_EULA=Y ./roteiro.sh 2025
ACCEPT_EULA=Y ./edicoes_2025.sh
ACCEPT_EULA=Y MSSQL_PID=StandardDeveloper SAIDA=/tmp/standard ./roteiro.sh 2025
```

```text
MSSQL_PID=Developer
Enterprise Developer Edition (64-bit) 3
MSSQL_PID=EnterpriseDeveloper
Enterprise Developer Edition (64-bit) 3
MSSQL_PID=StandardDeveloper
Standard Developer Edition (64-bit) 2
```

O número é o `EngineEdition`. Essa saída está em `lab/sqlserver/saidas/2025/lab0_edicoes.txt`.

**O limite**

Rodou em Linux, em contêiner, com uma instância só. A réplica é um banco comum lido por sinônimos, sem grupo de disponibilidade. Não sabemos a versão, a edição, a collation nem a tecnologia de réplica do seu banco. Confira antes de copiar.

> Verificação: nível 3, em 2026-11-03, em Linux, com `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04` e `2025-CU10-ubuntu-24.04`. Comando: `ACCEPT_EULA=Y ./roteiro.sh 2022`, e os da 2025 acima. Termos em nível 1. O teste com outros valores de `ACCEPT_EULA` não está nas capturas. Saídas: `lab/sqlserver/saidas/2022/`, `lab/sqlserver/saidas/2025/` e `lab/sqlserver/saidas/diferencas_2025_enterprise_standard.txt`.

### Lab 9: Que SQL um relatório roda

"Como descubro de onde vem o número que o sistema mostra?"

**Antes do comando: a licença.** Este Lab também sobe o SQL Server 2022 Developer. Valem os termos e os avisos do Lab 8. Leia antes de passar `ACCEPT_EULA=Y`.

Pré-condição: termos lidos e a memória que o `README.md` da pasta pede. O projeto é à parte. Um sistema fictício gera um relatório de faturamento, e você descobre o que ele rodou.

```bash
cd linhagem
./preparar.sh
ACCEPT_EULA=Y ./rodar.sh
```

O `rodar.sh` roda do zero, reescreve `saidas/`, remove contêineres e volumes no fim e mantém as imagens. Depois, leia as capturas em `lab/linhagem/saidas/`. Comece por estas três.

No Postgres, em `lab/linhagem/saidas/pg_02_statements.txt`, o relatório rodou duas vezes com valores diferentes e virou uma linha, com `calls` igual a 2 e `trim(cliente) = $1`. Em geral o valor não fica ali, e isso não é garantia: veja o capítulo 18.

No SQL Server, em `lab/linhagem/saidas/mssql_01_extended_events.txt`, a sessão filtrada pelo nome da aplicação mostra a chamada com os valores:

```text
$ bin/ms sa -i /scripts/11_xe_ler_arquivo.sql
evento|aplicacao|login|objeto|texto
------|---------|-----|------|-----
rpc_completed|erp_relatorios|app_relatorio|faturamento_por_loja|exec relatorios.faturamento_por_loja '2026-10-20','2026-10-22'
```

No dbt, em `lab/linhagem/saidas/dbt_01_linhagem.txt`, a exposição (exposure) declarada à mão lista tudo o que alimenta o painel, até as fontes:

```text
$ # The exposure selects what feeds it, up to the sources.
docker compose --profile dbt run --rm -T --no-deps dbt dbt ls --select +exposure:relatorio_faturamento_diretoria --output name 2>&1 | grep -vE 'Running with|Registered adapter|Found ' || true
relatorio_faturamento_diretoria
mart_faturamento_por_loja
stg_itens
stg_lojas
stg_pedidos
erp.itens_pedido
erp.lojas
erp.pedidos
```

A mesma captura mostra `dbt docs serve` respondendo sem conta:

```text
/ 200 text/html
/manifest.json 200 application/json
/catalog.json 200 application/json
```

**O limite**

Rodou em Linux, em contêiner, contra uma aplicação fictícia. Nada foi testado em Windows, em Power Query nem no monitor de um ERP. A página gráfica de linhagem não foi aberta em navegador: a prova é o HTTP 200 de dentro do contêiner e o manifesto. Antes de ligar qualquer captura num banco de verdade, leia o capítulo 18.

> Verificação: nível 3, em 2026-11-03, em Linux. Comando: `ACCEPT_EULA=Y ./rodar.sh`, com `postgres:16.15-alpine`, `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. Saídas: `lab/linhagem/saidas/`.

### 20.2 Como deixo a máquina como estava?

"Terminei. O que sobra aqui?"

Pare e pense no que apaga. Este comando remove o contêiner, a rede e o volume do projeto. Todas as tabelas do laboratório vão junto: bronze, silver, gold, snapshots e registro de carga.

```bash
docker compose --profile dbt down -v
```

```text
 Container modelagem-lab-postgres-1  Removed
 Volume modelagem-lab_postgres-db-volume  Removed
 Network modelagem-lab_default  Removed
```

Ficam as imagens, o `.env` e os arquivos da pasta. Para refazer, volte ao Lab 0. Os Labs 8 e 9 já derrubam o próprio projeto no fim do roteiro. Se você subiu o Lab 8 à mão, o `README.md` da pasta traz o comando.

> Verificação: nível 3, em 2026-11-03, em Linux. Saída: `lab/saidas/lab0_subir_do_zero.txt`, em que as imagens seguem listadas depois do `down -v`.

Com roteiro, você viu o número certo, o número dobrado e quem parou. No próximo capítulo, o roteiro some: exercícios com entregável e critério de correção, e um mini-desafio para achar sozinho a causa de cada número. O gabarito comentado fica com o mentor.

---

[Índice](../README.md#capítulos) · [Anterior: 19. Onde a regra mora: a decisão de quem gerencia](19-onde-a-regra-mora.md) · [Próximo: 21. Exercícios, entregáveis e mini-desafio](21-exercicios-entregaveis-e-mini-desafio.md)
