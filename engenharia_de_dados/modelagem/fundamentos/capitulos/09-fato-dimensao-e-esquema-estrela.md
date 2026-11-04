---
title: "9. Fato, dimensão e esquema estrela"
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

[Índice](../README.md#capítulos) · [Anterior: 8. Silver: datas e fuso horário](08-silver.md) · [Próximo: 10. Fan-out: quando o JOIN dobra o número](10-fan-out.md)

## 9. Fato, dimensão e esquema estrela

Seu BI lê uma planilha hoje, e você quer que ele leia o banco. A dúvida é o formato da entrega. Uma tabela só, com tudo? Quatro tabelas? Qual delas recebe o quê?

O capítulo 5 escreveu o grão. Agora vamos montar a estrela a partir dele, provar o resultado com a receita da rede de lojas e comparar a estrela com as duas alternativas que você vai ouvir no mercado.

### 9.1 Como saber se uma coluna é fato ou dimensão?

Você abre uma planilha cheia de colunas. Qual é medição e qual é contexto?

**O que é**

Fato é a medição de um evento de negócio, quase sempre numérica. A tabela de fato corresponde a um evento físico observável, não às exigências de um relatório. Ela só aceita medidas coerentes com o grão declarado.

Dimensão é o contexto do evento: quem, o quê, onde, quando, por quê e como. Os atributos dela servem para filtrar e agrupar. Sempre que possível, a dimensão tem um único valor para cada linha da fato.

Medida é a coluna numérica da fato que se resume.

**Como funciona na prática**

Na rede de lojas, o evento é o item vendido. O grão da fato é um item de pedido. Agora passe cada coluna por uma pergunta: você resume ou filtra? A pergunta é critério da mentoria, um jeito de começar, não uma regra de autor.

| Coluna | O que você faz com ela | Onde mora |
|---|---|---|
| `valor_item`, `quantidade` | resume | `fct_vendas` |
| `nome` e `cidade` da loja | filtra e agrupa | `dim_loja` |
| `nome` e `categoria` do produto | filtra e agrupa | `dim_produto` |
| `mes`, `fim_de_semana` | filtra e agrupa | `dim_data` |

**O equívoco comum**

O equívoco é desenhar a fato a partir do relatório. "Receita por dia" é um relatório. O evento é o item vendido. Por isso `fct_vendas` guarda um item por linha, e `vendas_por_dia` é uma tabela lida da estrela, fora dela.

O grão também barra a medida errada. O valor total do pedido não cabe numa fato por item. Ele se repetiria em cada item do mesmo pedido, e a soma viria inflada.

### 9.2 Já tenho o grão. Como monto a estrela?

**O que é**

Esquema estrela (star schema) é o modelo dimensional instanciado em banco relacional: tabelas de fato ligadas às dimensões por chave primária e estrangeira.

**Como funciona na prática**

Escreva uma frase de grão por tabela, antes de qualquer `SELECT`.

| Tabela | Uma linha é | Linhas no Lab 3 |
|---|---|---|
| `fct_vendas` | um item de pedido | 13 |
| `dim_produto` | um produto por período de preço, mais o membro desconhecido | 6 |
| `dim_loja` | uma loja | 3 |
| `dim_data` | um dia do calendário | 92 |

As frases entram como comentário no topo do SQL. Repare que não há ferramenta de transformação aqui: é SQL rodado à mão.

```sql
-- Gold star. Grain written before the SQL:
--   fct_vendas: one row per order item.
--   dim_produto: one row per product and price period (type 2), plus one row for the unknown member.
--   dim_loja: one row per store. dim_data: one row per calendar day.
DROP TABLE IF EXISTS gold.fct_vendas, gold.dim_produto, gold.dim_loja, gold.dim_data, gold.vendas_por_dia CASCADE;

CREATE TABLE gold.dim_data AS
SELECT d::date AS data_id,
       EXTRACT(year FROM d)::int AS ano,
       EXTRACT(month FROM d)::int AS mes,
       EXTRACT(isodow FROM d)::int AS dia_da_semana,
       EXTRACT(isodow FROM d) IN (6, 7) AS fim_de_semana
FROM generate_series(DATE '2026-10-01', DATE '2026-12-31', INTERVAL '1 day') AS d;

CREATE TABLE gold.dim_loja AS
SELECT md5(loja_id::text) AS loja_sk, loja_id, nome, cidade FROM silver.lojas;

CREATE TABLE gold.dim_produto AS
SELECT md5(v.produto_id::text || '|' || to_char(v.valido_de, 'YYYY-MM-DD')) AS produto_sk,
       v.produto_id, p.nome, p.categoria, p.custo, v.preco AS preco_tabela,
       v.valido_de, v.valido_ate
FROM silver.produtos_vigencia v
JOIN silver.produtos p USING (produto_id)
UNION ALL
-- A sale with no version points here: the revenue stays and a test counts it.
SELECT '-1', NULL, 'Desconhecido', 'desconhecido', NULL, NULL, NULL, NULL;

-- The day goes in the half-open interval: from valido_de, up to but not including valido_ate.
CREATE TABLE gold.fct_vendas AS
SELECT md5(i.pedido_id::text || '|' || i.item_seq::text) AS venda_sk,
       i.pedido_id, i.item_seq,
       l.loja_sk, COALESCE(dp.produto_sk, '-1') AS produto_sk, o.dia_local AS data_id,
       o.status,
       i.quantidade, i.preco_unitario, i.valor_item,
       dp.preco_tabela
FROM silver.itens i
JOIN silver.pedidos o USING (pedido_id)
JOIN gold.dim_loja l USING (loja_id)
LEFT JOIN gold.dim_produto dp
       ON dp.produto_id = i.produto_id
      AND o.dia_local >= dp.valido_de
      AND (dp.valido_ate IS NULL OR o.dia_local < dp.valido_ate);
```

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql`, sem mudança, executado em 2026-11-03, em Linux, em ambiente descartável, com a imagem `postgres:16.15-alpine`. Comando que provou: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql`. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

Vamos ler o código em quatro pontos.

1. **A fato guarda a chave, não o contexto.** `fct_vendas` tem `loja_sk`, não o nome da loja. Quem quer o nome vai à dimensão. Ela também traz `status` e `preco_tabela`, que a seção 9.3 e o capítulo 11 usam.
2. **Duas chaves, dois papéis.** Chave natural (natural key) é o identificador que vem do sistema de origem, como `produto_id`. Chave substituta (surrogate key) é a chave própria da dimensão, sem significado de negócio, que identifica uma versão da linha, como `produto_sk`. O Kimball diz que a chave primária da dimensão não deve ser a natural. Ela se repete quando o histórico é guardado, e origens diferentes geram chaves incompatíveis.
3. **O `md5` é critério da mentoria.** O Kimball recomenda inteiro sem significado, em sequência a partir de 1, e isenta a dimensão de data dessa regra. Em `dim_data`, a chave é a própria data. Nas outras dimensões, o laboratório usa hash, o `md5` do código. O capítulo 12 mostra o motivo, o custo e quando ele não serve.
4. **A venda sem versão não some.** O `LEFT JOIN` com `COALESCE` manda essa venda para o membro desconhecido: a linha da dimensão, aqui com chave `'-1'`, que recebe o fato sem versão correspondente. A receita fica, e um teste conta esses casos. A vigência no `JOIN` é assunto dos capítulos 11 e 12.

**A prova: a estrela devolve a receita?**

A rede de lojas já tem número publicado: a receita da apostila de Orquestração, onde ela começou. Se a estrela não devolver esse número, o erro está na estrela. Vamos conferir, com a tabela diária lida da fato.

```sql
-- Same daily table of the orchestration lab, now read from the star.
CREATE TABLE gold.vendas_por_dia AS
SELECT data_id AS dia,
       count(DISTINCT pedido_id)::int AS pedidos,
       count(DISTINCT pedido_id) FILTER (WHERE status = 'pago')::int AS pedidos_pagos,
       COALESCE(sum(valor_item) FILTER (WHERE status = 'pago'), 0)::numeric(14, 2) AS receita_paga
FROM gold.fct_vendas
GROUP BY data_id;
```

```text
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       430.90
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
(3 rows)
```

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql` e saída de `lab/saidas/lab3_gold_estrela_e_fan_out.txt`, sem mudança, da mesma execução de 2026-11-03, com `postgres:16.15-alpine` e o comando do bloco anterior.

Os três dias dão 430,90, 111,90 e 293,30, total de 836,10. É a receita da apostila de Orquestração, agora lida da estrela.

**Como inspecionar**

Rode o Lab 3, descrito no capítulo 20. A mesma execução confere o grão.

```sql
SELECT count(*) AS linhas_fct, count(DISTINCT venda_sk) AS chaves_fct,
       (SELECT count(*) FROM silver.itens) AS itens_silver,
       (SELECT count(*) FROM gold.obt_vendas) AS linhas_obt,
       (SELECT sum(valor_item) FILTER (WHERE status = 'pago') FROM gold.obt_vendas) AS receita_obt
FROM gold.fct_vendas;
```

```text
 linhas_fct | chaves_fct | itens_silver | linhas_obt | receita_obt 
------------+------------+--------------+------------+-------------
         13 |         13 |           13 |         13 |      836.10
(1 row)
```

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql` e saída de `lab/saidas/lab3_gold_estrela_e_fan_out.txt`, sem mudança, da mesma execução de 2026-11-03, com `postgres:16.15-alpine` e o mesmo comando.

Leia assim: 13 itens na silver, 13 linhas na fato, 13 chaves distintas. Nenhum item se perdeu e nenhum duplicou. As duas últimas colunas voltam na seção 9.4.

A dimensão de produto tem 6 linhas porque o Lab 3 usa uma foto só de preço: 5 produtos e o membro. Com as fotos dos três dias, ela chega a 8 linhas: 7 versões e o membro. A receita continua em 836,10. O capítulo 15 devolve os mesmos números em dbt.

### 9.3 Meu Power BI já funciona com a planilha. Por que mudar o formato?

**Como funciona na prática**

A documentação do Power BI responde pelo mecanismo. Cada visual gera uma consulta que filtra, agrupa e resume. Dimensões servem para filtrar e agrupar. Fatos servem para resumir. O lado "um" da relação é sempre dimensão, e o lado "muitos" é sempre fato.

A estrela entrega essas peças separadas. O BI hoje alimentado por planilha passa a ler quatro tabelas, com três relações.

| Relação | Lado "um" (dimensão) | Lado "muitos" (fato) |
|---|---|---|
| Loja | `dim_loja.loja_sk` | `fct_vendas.loja_sk` |
| Produto | `dim_produto.produto_sk` | `fct_vendas.produto_sk` |
| Data | `dim_data.data_id` | `fct_vendas.data_id` |

Um visual de receita por cidade agrupa por `cidade`, em `dim_loja`, e resume `valor_item`, em `fct_vendas`. Para chegar à receita paga, ele também filtra `status = 'pago'`, que está na fato.

A mesma documentação traz duas recomendações. Classifique cada tabela como dimensão ou fato, sem misturar: "Avoid mixing the two types together for a single table" (evite misturar os dois tipos numa tabela só). E carregue a fato sempre num grão consistente: "fact tables always load data at a consistent grain" (tabelas de fato sempre carregam num grão consistente).

Se a sua planilha traz na mesma linha o item vendido, a cidade da loja e o nome do produto, ela já mistura os dois tipos.

**A barreira que vem junto**

No Power BI, duplicata no lado "um" de uma relação faz a atualização inteira falhar: "the entire data refresh will fail" (a atualização inteira vai falhar). Parece castigo. É proteção: você vê o erro em vez de um número inflado.

Daí sai um cuidado, e isto é inferência: ligue a relação em `produto_sk`, não em `produto_id`. Com o histórico do capítulo 11, `produto_id` se repete, e a chave substituta continua única.

**O equívoco comum**

O equívoco é achar que o Power BI avisa de toda duplicata. A checagem só existe na coluna do lado "um". Por isso, e também é inferência, uma tabela já juntada no SQL chega inflada sem relação nenhuma para barrar. O número sai errado, sem erro nenhum.

**O limite do que mostramos**

O laboratório roda em Postgres, em Linux, e não abre o Power BI. A prova deste capítulo é do SQL. O comportamento do Power BI vem da documentação da Microsoft, não de execução nossa. Antes de trocar a fonte do seu relatório, confira num modelo de teste.

### 9.4 Estrela, tabela larga ou one big table?

"O guia do dbt recomenda tabela larga. A Microsoft recomenda estrela. Quem está certo?" Vamos separar o que cada fonte diz, porque elas partem de cenários diferentes.

**O que cada fonte diz**

A Microsoft fala do Power BI, pelo mecanismo da seção anterior.

O dbt chama de mart a tabela que serve de fonte da verdade de um conceito. O guia de marts recomenda tabela larga e desnormalizada ("Wide and denormalized"). O argumento é que, no armazém de dados moderno, armazenamento é barato e processamento é caro. O próprio guia abre exceção: com camada semântica, a camada das métricas, o mart deve ficar o mais normalizado possível.

O vocabulário não é uniforme nem dentro do dbt. A página de terminologia chama o mart de "relatively normalized" (relativamente normalizado). Ela descreve a camada semântica como "denormalization engine" (motor de desnormalização).

A mesma página chama de one big table (uma tabela só, grande) o sistema mais desnormalizado: todas as colunas de interesse de um conceito numa tabela só, para o analista só precisar de um `select`. O termo não tem autor de referência. Tratamos como uso de mercado.

**O que o benchmark mede, e o que não mede**

O benchmark (teste comparativo de desempenho) da Fivetran, de Michael Kaminsky, publicado em 2022-08-16, testou Redshift, Snowflake e BigQuery com consultas de estilo BI. Concluiu melhora de 25% a 50% com a tabela desnormalizada. No Snowflake, o resultado foi misto, com a estrela mais rápida em algumas consultas simples. No Redshift, a tabela materializada triplicou o disco usado.

Ele não mediu Postgres, SQL Server nem Power BI. É fonte de fornecedor. Não generalize para banco com armazenamento em linha.

**A comparação**

As linhas de custo e de quando considerar são critério da mentoria, salvo onde a célula cita a fonte.

| Critério | Estrela | Tabela larga | One big table |
|---|---|---|---|
| O que é | Fato ligada às dimensões por chave | Tabela final desnormalizada, com o contexto na mesma linha | O extremo: todas as colunas de interesse de um conceito numa tabela só |
| Quem recomenda | Microsoft, para o Power BI. A definição é do Kimball | Guia de marts do dbt, salvo com camada semântica | Sem autor de referência: uso de mercado |
| Argumento | Cada visual filtra, agrupa e resume | Armazenamento barato, processamento caro | O analista só precisa de um `select` |
| Custo | Mais tabelas e relações para manter | Junta os dois tipos que a documentação do Power BI pede para separar | O mesmo da larga. Materializada, ocupa disco: o triplo, no Redshift do benchmark |
| Duplicata no BI | A atualização falha no lado "um" | Sem relação para barrar (inferência) | Sem relação para barrar (inferência) |
| Desempenho | Sem medição nossa | Benchmark de fornecedor, em três armazéns, sem Postgres, SQL Server nem Power BI | O mesmo benchmark, com a mesma ressalva |
| No laboratório | `fct_vendas` e três dimensões: 836,10 | Não construímos | View sobre a estrela: 836,10 |
| Quando considerar | Fonte de verdade da gold, e consumidor Power BI | Consumidor em SQL, sem camada semântica, com medição no seu banco | Quem quer um `select` só, como view sobre a estrela |

**Como fica no laboratório**

```sql
-- One big table: a consumption view over the star, not a second source of truth.
CREATE VIEW gold.obt_vendas AS
SELECT f.venda_sk, f.pedido_id, f.item_seq, f.data_id, d.mes, d.fim_de_semana,
       l.nome AS loja, l.cidade, p.nome AS produto, p.categoria, f.status,
       f.quantidade, f.preco_unitario, f.valor_item, f.preco_tabela
FROM gold.fct_vendas f
JOIN gold.dim_data d USING (data_id)
JOIN gold.dim_loja l USING (loja_sk)
LEFT JOIN gold.dim_produto p USING (produto_sk);
```

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql`, sem mudança, da mesma execução de 2026-11-03, com `postgres:16.15-alpine` e o comando da seção 9.2. A saída de 13 linhas e 836,10 está naquela seção e em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

A view não guarda dado e roda a cada uso. Então ela oferece conveniência, não velocidade. Em compensação, não tem regra própria: só lê a estrela. Por isso devolve as mesmas 13 linhas e os mesmos 836,10. É camada de consumo, não segunda fonte de verdade.

**Como decidir (critério da mentoria)**

1. Mantenha a estrela como fonte de verdade da gold.
2. Se o consumidor é o Power BI, entregue a estrela. A one big table junta os dois tipos, e a documentação pede o contrário.
3. Se o consumidor quer um `select` só, entregue a view sobre a estrela.
4. Materialize só com lentidão medida no seu banco. O guia do dbt lembra que materializar o mart como tabela evita recalcular cadeias inteiras de modelos a cada atualização de painel. O capítulo 14 trata dessa escolha.

A estrela só devolve esses números enquanto cada `JOIN` respeita o grão. No capítulo 10, vamos ver o fan-out (multiplicação de linhas): um produto com dois fornecedores quase dobra a receita do dia 20, sem nenhum erro de sintaxe.

---

[Índice](../README.md#capítulos) · [Anterior: 8. Silver: datas e fuso horário](08-silver.md) · [Próximo: 10. Fan-out: quando o JOIN dobra o número](10-fan-out.md)
