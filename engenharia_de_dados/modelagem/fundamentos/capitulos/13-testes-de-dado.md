---
title: "13. Testes de dado: consultas que precisam voltar vazias"
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

[Índice](../README.md#capítulos) · [Anterior: 12. Chave substituta e a venda na versão certa](12-chave-substituta-e-a-venda-na-versao-certa.md) · [Próximo: 14. Materialização, incremental e reprocesso](14-materializacao-incremental-e-reprocesso.md)

## 13. Testes de dado: consultas que precisam voltar vazias

Como saberíamos que o número dobrou? Se a resposta é "o usuário avisa", falta teste. Antes do SQL, você decidiu o que uma linha significa. Agora, escreva a consulta que desmente essa decisão, e decida o que acontece quando ela acha alguma coisa.

### 13.1 Preciso de ferramenta para ter teste?

Não. Você já escreveu alguns sem esse nome.

**O que é**

Teste de dado (data test) é uma afirmação sobre o resultado do modelo, escrita como um `SELECT` que busca as linhas que a desmentem. Zero linhas, passou. Inferência da mentoria: a ideia vale antes da ferramenta, como consultas que precisam voltar vazias.

O `HAVING count(*) > 1` dos capítulos 10 e 11 tem essa forma. A contagem de datas que falharam, do capítulo 8, também, se você pedir as linhas em vez do total. Falta um passo: tratar essas consultas como parte do modelo, ao lado da frase de grão.

**Como funciona na prática**

Escreva a regra em português. Depois, escreva o `SELECT` que acha quem a quebra. A regra aqui é: os itens de um pedido somam o valor do pedido.

```sql
-- Reconciliation: the items of an order must add up to the order value.
select o.pedido_id, o.valor, sum(i.valor_item) as soma_itens
from {{ ref('stg_pedidos') }} o
join {{ ref('stg_itens') }} i using (pedido_id)
group by 1, 2
having o.valor <> sum(i.valor_item)
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`: `docker compose --profile dbt run --rm dbt dbt build`. Código em `lab/projeto_dbt/tests/assert_itens_batem_com_pedido.sql`, saída em `lab/saidas/lab5_projeto_dbt.txt`.

O `{{ ref(...) }}` é do dbt. O resto é SQL. Este é um teste singular (singular test): uma consulta escrita para uma regra só. Se você está no SQL à mão, troque o `ref` pelo nome da sua tabela.

### 13.2 Quais testes vêm prontos, e o que cada um não pega?

"Escrevo uma consulta dessas para cada coluna?" Para as regras comuns, não. O dbt traz quatro testes genéricos (generic tests): você informa a tabela e a coluna, e ele monta a consulta.

| Teste | Regra | No laboratório | O que ele não pega |
|---|---|---|---|
| `unique` (único) | A chave não repete | `pedido_id` em `stg_pedidos` | Nulo: a consulta filtra `is not null` |
| `not_null` (não nulo) | A coluna vem preenchida | `custo` em `stg_produtos` | Valor preenchido que esconde o problema, como o membro `'-1'` |
| `accepted_values` (valores aceitos) | Só valores da lista | `status` em `stg_pedidos` | Nulo, e o `'desconhecido'`, porque ele está na lista |
| `relationships` (relacionamentos) | Todo filho tem pai: a integridade referencial | `pedido_id` de `stg_itens` em `stg_pedidos` | Nulo no filho, e o `'-1'`, porque ele é chave válida |

**Como inspecionar**

Não confie no nome do teste. Abra o SQL que ele virou. Depois de um `dbt build`, esse SQL fica em `lab/projeto_dbt/target/compiled/`, e a saída aponta o arquivo quando o teste não passa. Este é o teste do grão de `stg_itens`, o `unique` sobre a expressão que o capítulo 5 mostrou:

```sql
select
    (pedido_id || '-' || item_seq) as unique_field,
    count(*) as n_records

from "dw"."dbt_silver"."stg_itens"
where (pedido_id || '-' || item_seq) is not null
group by (pedido_id || '-' || item_seq)
having count(*) > 1
```

> Verificação: nível 2 pelo SQL compilado e nível 3 pela execução, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`: `docker compose --profile dbt run --rm dbt dbt build`. Arquivo gerado em `lab/projeto_dbt/target/compiled/rede_de_lojas/models/silver/_silver.yml/unique_stg_itens__pedido_id_item_seq_.sql`, sem as linhas em branco do início e do fim. Saída em `lab/saidas/lab6_testes_que_param.txt`.

Tem a forma da consulta de prova do capítulo 5, com um filtro a mais. Repare no `where`: é aí que mora o limite.

**O equívoco comum**

"Passou no `unique`, então a chave não repete." Repete, se tiver nulo. No código do `dbt-adapters`, `unique`, `accepted_values` e `relationships` ignoram nulo. Rodamos as formas compiladas à mão: status nulo e loja nula passaram em `accepted_values` e `relationships`. O par `(2, nulo)` repetido escapou do `unique` sobre a chave concatenada. Só o `not_null` ao lado pega. Isso vale para o dbt v1. A implementação no v2 não foi conferida.

> Verificação: nível 3, com `postgres:16.15-alpine`, em 2026-11-03. Formas compiladas à mão, fora dos scripts do laboratório: não há arquivo em `lab/saidas/` para elas.

Então, escreva `not_null` ao lado dos outros três. O laboratório deixa um caso à vista: `stg_itens` testa o grão pela expressão, sem `not_null` em `item_seq`. Na gold, `venda_sk` sai dessa coluna e tem `not_null`, então o nulo apareceria um passo depois. É inferência pela leitura do código: esse caso não foi executado. Na sua tabela, escreva o `not_null` já na silver.

Os limites também se somam. `CASE` sem `ELSE` devolve nulo quando nenhuma condição casa, e `accepted_values` não olha nulo. Inferência: um status novo, sem `ELSE`, quebra a regra e passa no teste. Com `ELSE` nomeado, o valor continua visível e um teste que conta pega. O membro `'-1'` do capítulo 12 esconde por outro caminho: com ele, `not_null` e `relationships` passam. Com vendas sintéticas, só o teste que conta acusou (`WARN 2`).

> Verificação do `WARN 2`: nível 3, em 2026-11-04, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Saída em `lab/saidas/lab9_dbt_venda_sem_versao.txt`.

### 13.3 O que para a carga e o que só avisa?

"Todo teste que não passa deve parar tudo?" Não. Essa é uma decisão de modelagem, e ela é sua.

**Como funciona na prática**

No `dbt build`, falha de teste faz os dependentes serem pulados. Para não pular, ajusta-se a severidade (severity) ou os limites do teste. Sem configuração nenhuma, o teste falha: a saída diz `configured to fail if != 0`. O aviso precisa ser escrito:

```yaml
      - name: custo
        description: Null means unknown. Warns instead of becoming zero.
        data_tests:
          - not_null:
              config:
                severity: warn
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`: `docker compose --profile dbt run --rm dbt dbt build`, com `WARN 1 not_null_stg_produtos_custo`. Trecho de `lab/projeto_dbt/models/silver/_silver.yml`. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

Critério da mentoria: pergunte se publicar com essa linha deixa o número errado para quem decide. Se deixa, para. Se o número segue valendo com a ressalva à vista, avisa. No laboratório, ficou assim:

| Regra | Teste | Se voltar linha | Motivo |
|---|---|---|---|
| Uma linha por item | `unique` na chave do grão | Para | A soma sai dobrada |
| Itens somam o pedido | `assert_itens_batem_com_pedido` | Para | O dinheiro não fecha |
| Custo preenchido | `not_null` em `custo` | Avisa | A receita não depende dele, e custo nulo fica nulo |
| Status reconhecido | `assert_status_desconhecido` | Avisa | O pedido fica fora da receita, e a contagem fica à vista |
| Venda com versão | `assert_vendas_sem_versao` | Avisa | A receita fica, no membro `'-1'` |

Escreva essa tabela junto da frase de grão, antes do SQL. E, também como critério da mentoria, dê dono ao aviso: combine quem olha e quando, porque aviso sem dono vira ruído.

### 13.4 Como saberíamos que o número dobrou?

É a quebra que a seção 5.5 adiantou, agora lida linha a linha. No Lab 6, o script carrega os itens do pedido 104 duas vezes. Depois, rodamos os dois fluxos. O `dbt build` responde assim:

```text
20:39:03  15 of 46 FAIL 2 unique_stg_itens__pedido_id_item_seq_ .......................... [FAIL 2 in 0.19s]
20:39:03  17 of 46 FAIL 1 assert_itens_batem_com_pedido .................................. [FAIL 1 in 0.03s]
20:39:04  32 of 46 SKIP relation dbt_gold.fct_vendas ..................................... [SKIP]
20:39:04  43 of 46 SKIP relation dbt_gold.vendas_por_dia ................................. [SKIP]
20:39:04  Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
```

| | SQL à mão | `dbt build` |
|---|---|---|
| Código de saída | 0 | 1 |
| Receita do dia 20 na gold | 741,80 | 430,90 |
| O que acusou | Nada | `FAIL 2` no grão e `FAIL 1` na soma |

Quem dobrou foi o pedido 104. O dia 20 foi de 430,90 para 741,80, e a diferença são os 310,90 desse pedido. `FAIL 2` são duas chaves repetidas. `FAIL 1` é um pedido cuja soma não fecha. Dois testes, duas perguntas.

O `dbt build` também não para tudo. Ele pula o que depende do teste: três modelos da gold e 12 testes. A `dim_produto` rodou, porque não depende dos itens.

O fluxo à mão também deu a pista, na saída do próprio script:

```text
 linhas_fct | chaves_fct | itens_silver | linhas_obt | receita_obt 
------------+------------+--------------+------------+-------------
         15 |         13 |           15 |         15 |     1147.00
(1 row)
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Carga dupla: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql`. À mão: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql -f /sql/30_gold.sql`. No dbt: `docker compose --profile dbt run --rm dbt dbt build`. Trechos copiados de `lab/saidas/lab6_testes_que_param.txt`.

São 15 linhas para 13 chaves, e o script seguiu. À mão, quem para é você. O laboratório não traz um script que transforme linha devolvida em parada, então não vamos prometer um aqui. Critério da mentoria: rode as consultas depois da silver e antes da gold, leia a saída e só siga com todas vazias. Quando isso depender de uma pessoa só, volte à decisão de degrau, no capítulo 19.

Para consertar, refaça a bronze com `10_bronze_carga.sql` e rode de novo: o `dbt build` volta a `PASS=44`. Pelo orquestrador, a sequência foi a mesma, em `lab/saidas/lab7_orquestrador_roda_dbt.txt`.

### 13.5 O teste barrou. Então ninguém viu o número errado?

Depende de onde a pessoa lê.

**O equívoco comum**

Teste com falha protege só o que vem depois dele. A silver do dbt é view, e a documentação avisa: "views on top of source data will always have the latest records in them". Quem lê `stg_itens` vê a duplicata na hora, 15 linhas para 13 chaves. A fato é tabela, e ficou com o número antigo.

Daí saem dois cuidados, e os dois são critério da mentoria. O relatório lê a gold, não a silver. E número antigo não é número de hoje: quem usa a gold precisa saber que a carga parou.

Inferência: zero linhas diz que nenhuma linha desmente aquela regra, não que o número está certo. Teste só responde o que você perguntou. Contratos e integração contínua (CI) ficam para o conceito de Qualidade e governança.

Tudo neste capítulo rodou em Postgres, em Linux. A silver e a gold em SQL Server estão no capítulo 17.

Os testes dizem quando não publicar. Falta decidir como guardar o resultado e como reprocessar sem duplicar. É o próximo capítulo.

---

[Índice](../README.md#capítulos) · [Anterior: 12. Chave substituta e a venda na versão certa](12-chave-substituta-e-a-venda-na-versao-certa.md) · [Próximo: 14. Materialização, incremental e reprocesso](14-materializacao-incremental-e-reprocesso.md)
