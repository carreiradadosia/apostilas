---
title: "15. O mesmo SQL como projeto dbt"
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

[Índice](../README.md#capítulos) · [Anterior: 14. Materialização, incremental e reprocesso](14-materializacao-incremental-e-reprocesso.md) · [Próximo: 16. dbt hoje: geração, licença, adaptador e preço](16-dbt-hoje.md)

## 15. O mesmo SQL como projeto dbt

Até aqui, tudo rodou em SQL à mão. Esse caminho é válido, e este capítulo não pede que você o abandone. Ele mostra o que muda quando o mesmo fluxo vira projeto no dbt, a ferramenta que usamos como exemplo. O que uma linha significa, o dbt não decide por você.

### 15.1 O SELECT sai do script e vira modelo

"Vou ter de reescrever o SQL que já escrevi?"

**O que é**

Não. No dbt, um modelo é principalmente um `SELECT` salvo num arquivo `.sql`. Rodar o modelo transforma o dado sem tirá-lo do armazém: é o T do ELT. A dbt Labs mostra o caminho num guia de migração: o `INSERT ... SELECT` vira modelo quando o `SELECT` sai da procedure e vai para o arquivo do modelo.

**Como funciona na prática**

Vamos ver a mesma tabela dos dois jeitos. Primeiro, o script do Lab 1:

```sql
CREATE TABLE silver.pedidos AS
WITH ultima_carga AS (
    SELECT *, row_number() OVER (PARTITION BY id ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.pedidos
)
SELECT id AS pedido_id,
       loja_id,
       COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado') AS cliente,
       valor,
       lower(trim(status)) AS status_origem,
       CASE lower(trim(status))
           WHEN 'pago' THEN 'pago'
           WHEN 'cancelado' THEN 'cancelado'
           WHEN 'pendente' THEN 'pendente'
           ELSE 'desconhecido'
       END AS status,
       to_date(emissao_texto, 'DD/MM/YYYY') AS dia_emissao,
       criado_em AT TIME ZONE 'America/Sao_Paulo' AS criado_em_utc,
       criado_em::date AS dia_local
FROM ultima_carga
WHERE ordem = 1;
```

Agora, o modelo do Lab 5, em `models/silver/stg_pedidos.sql`:

```sql
with ultima_carga as (
    select
        *,
        row_number() over (partition by id order by _carregado_em desc) as ordem
    from {{ source('bronze', 'pedidos') }}
)

select
    id as pedido_id,
    loja_id,
    coalesce(nullif(initcap(trim(cliente)), ''), 'Não informado') as cliente,
    valor,
    lower(trim(status)) as status_origem,
    case lower(trim(status))
        when 'pago' then 'pago'
        when 'cancelado' then 'cancelado'
        when 'pendente' then 'pendente'
        else 'desconhecido'
    end as status,
    to_date(emissao_texto, 'DD/MM/YYYY') as dia_emissao,
    criado_em at time zone 'America/Sao_Paulo' as criado_em_utc,
    criado_em::date as dia_local
from ultima_carga
where ordem = 1
```

> Verificação: script em nível 3, com `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`, saída em `lab/saidas/lab1_silver_a_mao.txt`. Modelo em nível 3 pela execução com `docker compose --profile dbt run --rm dbt dbt build`, e em nível 2 por `dbt parse` e pelo SQL compilado, saída em `lab/saidas/lab5_projeto_dbt.txt`. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03.

Compare os dois. Saiu o `CREATE TABLE silver.pedidos AS`. A leitura de `bronze.pedidos` virou `{{ source('bronze', 'pedidos') }}`. A caixa das palavras mudou, e isso é estilo. O `COALESCE`, o `CASE` com `ELSE`, o `to_date`, o fuso e a última carga são os mesmos.

**O equívoco comum**

"Então é copiar e colar e está pronto." O `SELECT` vem junto. O modo de pensar, não. A própria dbt Labs reconhece que migrar procedures é uma mudança grande de paradigma, do procedural para o declarativo. Leitura da mentoria: o SQL escrito à mão não se perde. Você para de escrever cada passo na ordem e passa a declarar o resultado e de quem ele depende.

### 15.2 O que mais mora na pasta

"Além dos SELECT, o que eu passo a manter?"

**Como funciona na prática**

Vamos abrir o projeto do Lab 5. O resumo abaixo diz o papel de cada item neste laboratório.

```text
projeto_dbt/
  dbt_project.yml           nome do projeto e como guardar cada camada
  profiles.yml              a conexão, com a senha vinda de variável de ambiente
  models/_sources.yml       as tabelas da bronze, carregadas pela ingestão
  models/silver/            stg_*.sql, foto_do_dia.sql e _silver.yml, com os testes
  models/gold/              dim_*.sql, fct_vendas.sql, obt_vendas.sql, vendas_por_dia.sql e _gold.yml
  models/experimentos/      os casos de erro do Lab 6, desligados por padrão
  seeds/                    de_para_categoria.csv
  snapshots/_snapshots.yml  o histórico do preço
  tests/                    assert_*.sql, os testes escritos à mão
```

Cada camada diz como guardar o resultado. Trecho do `dbt_project.yml`:

```yaml
models:
  rede_de_lojas:
    silver:
      +schema: silver
      +materialized: view
    gold:
      +schema: gold
      +materialized: table
    experimentos:
      +schema: experimentos
      +enabled: "{{ var('experimentos', false) }}"
      +tags: ["experimento"]
```

Materialização é a estratégia para guardar o resultado do modelo. A silver fica em view, o padrão do dbt, que não guarda dado. A gold fica em table, a indicada para o que o BI consulta, com uma exceção: `obt_vendas`, view sobre a estrela, configurada no próprio modelo. O script da silver grava tabela, e o projeto grava view. A seção 15.4 compara o conteúdo dos dois, e o capítulo 14 trata da escolha.

O `var('experimentos', false)` tem um detalhe que custa tempo. Um `var()` no `dbt_project.yml` não enxerga o bloco `vars` do próprio arquivo. Sem o valor padrão, o `dbt debug` para em `Required var 'experimentos' not found in config`.

> Verificação: trecho em nível 3 pela execução do Lab 5, e em nível 2 por `dbt parse`. A falha sem valor padrão: nível 3, `dbt-core` 1.12.6, 2026-11-04, numa cópia que só tira o valor padrão (`lab/checagens/var_sem_padrao/dbt_project.yml`), com `dbt debug`; saída em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`. A mensagem inteira: `Could not render {{ var('experimentos') }}: Required var 'experimentos' not found in config`.

Agora o elo entre os modelos. No código de `fct_vendas`, ele está escrito assim:

```sql
from {{ ref('stg_itens') }} i
join {{ ref('stg_pedidos') }} o using (pedido_id)
```

No SQL compilado, o que chega ao banco é SQL comum:

```sql
from "dw"."dbt_silver"."stg_itens" i
join "dw"."dbt_silver"."stg_pedidos" o using (pedido_id)
```

O `dbt` de `dbt_silver` vem do `schema` do `profiles.yml`, e o `silver`, do `+schema`.

O mesmo `ref` alimenta o grafo do projeto. O `dbt docs generate` roda local, sem conta, e escreve `index.html`, `catalog.json` e `manifest.json` em `target/`. O manifesto guarda os pais de cada modelo, no `parent_map` (mapa de pais):

```text
pais de fct_vendas: ['model.rede_de_lojas.dim_loja', 'model.rede_de_lojas.dim_produto', 'model.rede_de_lojas.stg_itens', 'model.rede_de_lojas.stg_pedidos']
```

> Verificação: nível 3. `docker compose --profile dbt run --rm dbt dbt docs generate`, `dbt-core` 1.12.6, 2026-11-03. SQL compilado e pais em `lab/saidas/lab5_projeto_dbt.txt`.

**O equívoco comum**

"Se está no dbt, a linhagem está completa." Não está. O grafo só vê o que o projeto declara com `ref`, `source`, `function` ou `metric`. No Lab 9, um modelo com a tabela escrita à mão roda e fica sem pai nenhum: `pais de model.linhagem.copia_sem_ref: []`. Saída em `lab/linhagem/saidas/dbt_01_linhagem.txt`. Inferência, sem teste com esses produtos: o cálculo de um ERP e o Power Query só entram se alguém os declarar. O capítulo 18 volta a isso.

### 15.3 Snapshot em YAML

"O capítulo 11 montou a vigência à mão. O dbt faz isso por mim?"

**O que é**

Faz. No dbt, snapshot é a implementação de SCD tipo 2. A forma atual é em YAML, com `relation` e `config`. `strategy` e `unique_key` são obrigatórios. O bloco abaixo traz duas estratégias de propósito, lendo a mesma foto:

```yaml
snapshots:
  - name: snap_produtos_preco
    description: Type 2 history of the price. check compares the column, and the photo day dates the version.
    relation: ref('foto_do_dia')
    config:
      schema: snapshots
      unique_key: id
      strategy: check
      check_cols: [preco]
      updated_at: foto_em

  - name: snap_produtos_por_timestamp
    description: The wrong choice on purpose. The nightly job touches atualizado_em on every row, so every night looks like a change.
    relation: ref('foto_do_dia')
    config:
      schema: snapshots
      unique_key: id
      strategy: timestamp
      updated_at: atualizado_em
```

O modelo `foto_do_dia` lê da bronze a foto do dia escolhido pela variável `dia_foto`. A foto crua fica na bronze, como critério da mentoria desde o capítulo 11.

**Como funciona na prática**

Rode os três dias, um por vez:

```bash
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-21"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-22"}'
```

O `check` guarda 7 versões para 5 produtos:

```text
 id | preco |   dbt_valid_from    |    dbt_valid_to     
----+-------+---------------------+---------------------
 10 | 60.00 | 2026-10-20 00:00:00 | 
 20 | 33.30 | 2026-10-20 00:00:00 | 
 30 | 15.00 | 2026-10-20 00:00:00 | 2026-10-22 00:00:00
 30 | 17.00 | 2026-10-22 00:00:00 | 
 40 | 20.50 | 2026-10-20 00:00:00 | 2026-10-22 00:00:00
 40 | 20.00 | 2026-10-22 00:00:00 | 
 50 | 12.00 | 2026-10-20 00:00:00 | 
(7 rows)
```

O `timestamp` guarda 15, três por produto. Veja o produto 10, com o preço sempre igual:

```text
 id | preco |   dbt_valid_from    |    dbt_valid_to     
----+-------+---------------------+---------------------
 10 | 60.00 | 2026-10-20 03:00:00 | 2026-10-21 03:00:00
 10 | 60.00 | 2026-10-21 03:00:00 | 2026-10-22 03:00:00
 10 | 60.00 | 2026-10-22 03:00:00 | 
(3 rows)
```

> Verificação: nível 3 pela execução, nível 2 por `dbt parse`. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

Vamos ver por que 15. O capítulo 11 mostrou a rotina que toca a data de alteração de todas as linhas toda noite. O `timestamp` cria versão quando essa data é mais recente que a última execução. Toda noite parece mudança, e nascem versões falsas. O `check` compara só o preço. A documentação indica esse uso: "The check strategy is useful for tables which do not have a reliable updated_at column".

Três detalhes da saída:

- Com `updated_at: foto_em`, a versão nasce no dia da foto, sem aviso.
- A vigência já nasce meio aberta. Nas versões fechadas, `dbt_valid_to` é igual ao `dbt_valid_from` da seguinte, o que combina com `>=` e `<`. Aqui, só as 2 fechadas provam isso, as dos produtos 30 e 40. As outras 5 estão abertas. `hard_deletes` em `invalidate` não testamos.
- O snapshot acrescenta `dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from` e `dbt_valid_to`. A documentação trata o `dbt_scd_id` como chave de uso interno. O capítulo 12 explica por que a chave da dimensão é outra.

**O equívoco comum**

"É mais um modelo. Se der errado, refaço." Não é. "Snapshots can't be rebuilt", diz a documentação. Ela sugere schema separado e pede chave realmente única. O snapshot também trabalha em lote: só registra mudança quando roda, e por isso precisa de agenda, entre uma vez por hora e uma por dia.

Recarga completa (full refresh) não resolve. A documentação diz que snapshot ignora tanto a configuração `full_refresh` quanto a flag `--full-refresh`. O que refaz é a foto crua. Só faça isto no laboratório: o `DROP` apaga o histórico.

```bash
docker compose exec -T postgres psql -U dw -d dw -c "drop table dbt_snapshots.snap_produtos_preco, dbt_snapshots.snap_produtos_por_timestamp"
```

Repita os três dias e confira:

```text
 linhas_check | linhas_timestamp 
--------------+------------------
            7 |               15
(1 row)
```

> Verificação: nível 3, `dbt-core` 1.12.6, 2026-11-03, saída em `lab/saidas/lab5_projeto_dbt.txt`. Em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`, nível 3, 2026-11-04: `dbt snapshot --full-refresh` é recusado com `No such option`, e `dbt build --full-refresh --select` no snapshot manteve as 7 linhas.

Inferência: sem a foto, snapshot apagado é histórico perdido. E o `updated_at` protege também a chave interna. Num teste à parte, sem arquivo publicado, com `updated_at` no dia da foto, refazer os três dias devolveu as mesmas 7 chaves. Sem ele, o hash leva a hora da execução, e nenhuma voltou.

> Verificação: nível 3, num teste à parte, sem arquivo publicado. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, PostgreSQL 16.15, 2026-11-03.

### 15.4 A prova: o mesmo número

"Como sei que o dbt não mudou o meu número?"

**Como inspecionar**

Rode o projeto inteiro e compare com o SQL à mão, que grava em `silver` e `gold`. O dbt grava em `dbt_silver` e `dbt_gold`, então os dois convivem.

```bash
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/50_comparar_a_mao_e_dbt.sql
```

```text
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
```

São 46 nós: 1 seed (o CSV de categorias), 2 snapshots, 5 modelos em table, 6 em view e 32 testes de dado. O dbt acha 12 modelos e roda 11, porque `foto_do_dia` é ephemeral (efêmero) e não aparece na saída como objeto. Os 2 avisos são de propósito: `assert_status_desconhecido` e `not_null_stg_produtos_custo`. O `assert_vendas_sem_versao` passa, porque nenhuma venda real cai no membro desconhecido.

A comparação usa `EXCEPT` nos dois sentidos. Cada coluna conta as linhas que só existem de um lado. Trecho de `50_comparar_a_mao_e_dbt.sql`:

```sql
SELECT 'pedidos da silver',
       (SELECT count(*) FROM (SELECT * FROM silver.pedidos EXCEPT SELECT * FROM dbt_silver.stg_pedidos) x),
       (SELECT count(*) FROM (SELECT * FROM dbt_silver.stg_pedidos EXCEPT SELECT * FROM silver.pedidos) x)
```

```text
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

> Verificação: nível 3. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03, com os dois comandos acima. Saída em `lab/saidas/lab5_projeto_dbt.txt`, sem os carimbos de hora na linha `Done`.

Zero nas duas colunas. Mudou quem organiza. O tratamento não mudou.

A chave está na comparação: `produto_sk` entra na lista de colunas de `dim_produto` e de `fct_vendas`. A fórmula de hash é a mesma nos dois fluxos, critério da mentoria que o capítulo 12 explicou. Os dois lados têm 8 linhas e 8 chaves: 7 versões e o membro `'-1'`. A receita paga segue em 836,10, com 430,90, 111,90 e 293,30 nos dias 20, 21 e 22. É o número que a apostila de Orquestração publicou, e o teste `assert_receita_igual_a_do_piloto` passa a vigiá-lo.

**O equívoco comum**

"Deu zero, então a ferramenta garante." Não garante. Inferência: o zero vale para estes dados e estas cinco comparações. Critério da mentoria para a sua migração: rode script e modelo lado a lado, escreva o seu `EXCEPT` nos dois sentidos e só desligue o script quando voltar zero. Se a chave não entrar na comparação, ela pode divergir sem ninguém ver.

### 15.5 Sintaxe atual contra material antigo

"Achei um tutorial com `tests:`, e ele roda. Posso seguir?"

**Como inspecionar**

Pode rodar. Não copie para projeto novo. Compare com esta tabela, que mostra o que aconteceu ao rodar a forma antiga em cada geração:

| No material antigo | Na sintaxe atual | No dbt v1 | No dbt v2 |
|---|---|---|---|
| `tests:` | `data_tests:` | Roda sem aviso | Roda sem aviso |
| `values:` direto em `accepted_values` | `values:` sob `arguments:` | Só aviso, com `WARN=0` no resumo | Erro `dbt1159` |
| `meta` fora de `config` | `meta` dentro de `config` | Passa em silêncio | Erro `dbt1060` |
| Chave própria direto em `config` | A chave dentro de `meta` | Passa em silêncio | Erro `dbt1060` |
| `materialized` sem `+` no `dbt_project.yml` | `+materialized` | Passa em silêncio | Erro `dbt1013` |
| Snapshot em bloco SQL, com `target_schema` | YAML com `relation` e `config` | Roda sem aviso | Roda sem aviso |

> Verificação: nível 3 num teste à parte da mentoria, sem arquivo publicado, com um projeto em cada sintaxe. `dbt-core` 1.12.6 e `dbt-oss` 2.0.11, os dois com DuckDB, 2026-11-03. Esta tabela não testa o v2 com Postgres, e o capítulo 16 conta por quê. Entrada de cada forma, pela documentação (nível 1): `data_tests` na 1.8, snapshot em YAML na 1.9, `arguments` na 1.10.5.

Leia as duas últimas colunas juntas. Passar no v1 não prova que passa no v2. Parte desses avisos, diz a documentação, vale só para Snowflake, Databricks, BigQuery e Redshift. Inferência: silêncio em outro banco não é aprovação. O `tests:` não quebra hoje, mas está fora da sintaxe documentada. O snapshot em bloco SQL segue disponível, e a documentação recomenda YAML para os novos. O laboratório já nasce na sintaxe atual, para você não aprender duas vezes.

**O equívoco comum**

"Migrar o snapshot para YAML é só trocar a forma." Não é: a tabela muda de lugar. Num teste à parte, sem arquivo publicado, `target_schema='snapshots'` gravou em `snapshots`. Com `schema: snapshots`, o dbt gravou em `main_snapshots`, porque juntou o schema da conexão, `main` naquele teste. No nosso laboratório, o mesmo arranjo dá `dbt_snapshots`. Como snapshot não se reconstrói, a documentação orienta criar antes uma tabela de backup ("create a backup snapshot table"). Faça a cópia e confira onde a tabela nova nasce antes de agendar.

### 15.6 O dbt como passo de uma Dag

"E quem roda isso às 6h, sem mim?"

**O que é**

A apostila de Orquestração deixou a frase: o orquestrador não é o código de limpeza, é quem roda o código. Aqui ela fica literal. A Dag do Lab 7 não limpa nada. Ela roda o `dbt build`, diz qual é o dia e lê o código de saída.

**Como funciona na prática**

O dbt entra na imagem do Airflow num ambiente virtual do Python (virtualenv), criado na construção da imagem. Critério da mentoria: ambiente próprio, para os pacotes fixados dele não disputarem com os do Airflow.

```dockerfile
FROM apache/airflow:3.3.2-python3.13
# dbt gets its own virtualenv, so its pinned packages never fight the Airflow constraints.
COPY runner/requirements.lock /tmp/dbt-requirements.lock
RUN python -m venv /opt/airflow/dbt-venv \
    && /opt/airflow/dbt-venv/bin/pip install --no-cache-dir -r /tmp/dbt-requirements.lock
```

A tarefa é um `BashOperator`. Dois trechos da Dag, que está inteira em `lab/orquestrador/dags/dbt_rede_de_lojas.py`:

```python
DBT = "/opt/airflow/dbt-venv/bin/dbt"
# target and logs go to /tmp so the run never writes into the mounted project.
FLAGS = "--project-dir /lab/projeto_dbt --target-path /tmp/dbt-target --log-path /tmp/dbt-logs"
```

```python
    BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT} build {FLAGS} --exclude test_type:unit --vars '{{dia_foto: \"{{{{ ds }}}}\"}}'",
    )
```

O `--exclude test_type:unit` segue a recomendação da dbt Labs de rodar teste unitário só em desenvolvimento ou CI. Este projeto não tem teste unitário, e o dbt avisou `does not match any enabled nodes` no Lab 7.

O contrato é o código de saída. A documentação do operador diz: "a non-zero exit code produces an AirflowException and thus a task failure". Vamos provar em três rodadas, com a mesma Dag:

| Rodada | O que aconteceu | Resumo do dbt | Código de saída | DagRun |
|---|---|---|---|---|
| 1 | Dados normais | `PASS=44 WARN=2 ERROR=0 SKIP=0` | 0 | Sucesso |
| 2 | A ingestão duplica os itens do pedido 104 | `PASS=27 WARN=2 ERROR=2 SKIP=15` | 1 | Falha |
| 3 | Bronze refeita | `PASS=44 WARN=2 ERROR=0 SKIP=0` | 0 | Sucesso |

Linhas da segunda rodada:

```text
Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
Command exited with return code 1
airflow.sdk.exceptions.AirflowException: Bash command failed. The command returned a non-zero exit code 1.
DagRun failed
```

> Verificação: nível 3 pela execução, com `docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"`, nível 2 por `dbt parse`. Airflow 3.3.2, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03, em Linux. Saídas em `lab/saidas/lab7_orquestrador_construir_imagem.txt` e `lab/saidas/lab7_orquestrador_roda_dbt.txt`. Linhas filtradas, sem carimbo de hora e sem os campos de log.

Repare em duas coisas. Aviso não derruba a Dag: a rodada 1 tem `WARN=2` e sai com 0. Erro derruba: os testes `unique_stg_itens__pedido_id_item_seq_` e `assert_itens_batem_com_pedido` falham, e 15 nós são pulados. O efeito está medido no Lab 6, com a mesma carga dupla: a gold do dbt mantém 430,90 no dia 20, e o SQL à mão sai com 0 e publica 741,80. O capítulo 13 trata dessa decisão.

**O equívoco comum**

"Se a tarefa falhar, o orquestrador repete, e está resolvido." Repetir só é seguro se der o mesmo resultado, como o Airflow pede da tarefa (seção 14.2). Neste projeto, as tabelas são refeitas, e o snapshot do mesmo dia não cria versão: o `dbt build` do Lab 5, com a foto do dia 22 já registrada, mostra `INSERT 0 0` nos dois snapshots. Modelo incremental pede mais cuidado, e o capítulo 14 mostra por quê.

**O limite desta prova**

Foi `airflow dags test`: uma execução da Dag, sem agendador de pé. A agenda das 6h não foi exercitada. O dia chegou ao comando, que saiu renderizado com `--vars '{dia_foto: "2026-10-22"}'`. Nada rodou em Windows. E, como o snapshot só registra quando roda, a agenda da Dag define o que o histórico enxerga (inferência).

O número é o mesmo, e o orquestrador já sabe rodar. Falta a pergunta que vem antes de instalar qualquer coisa: qual dbt, para o seu banco? O próximo capítulo responde.

---

[Índice](../README.md#capítulos) · [Anterior: 14. Materialização, incremental e reprocesso](14-materializacao-incremental-e-reprocesso.md) · [Próximo: 16. dbt hoje: geração, licença, adaptador e preço](16-dbt-hoje.md)
