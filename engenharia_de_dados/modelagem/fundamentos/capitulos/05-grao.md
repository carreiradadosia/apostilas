---
title: "5. Grão: o que uma linha significa"
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

[Índice](../README.md#capítulos) · [Anterior: 4. Camadas: onde cada regra mora](04-camadas.md) · [Próximo: 6. Silver: texto, coluna redundante e duplicata](06-silver.md)

## 5. Grão: o que uma linha significa

Você já sabe qual relatório precisa. Por que não começar pelo `SELECT`? Porque falta uma resposta anterior a ele. A frase guia desta apostila diz qual: antes do SQL, decida o que uma linha significa.

### 5.1 O que é o grão, e por que ele vem antes

O que é uma linha da fato de vendas? Responda antes de seguir. No laboratório, é um item de pedido, não um pedido.

**O que é**

Grão (grain) é o que uma linha da tabela significa. No Kimball, ele diz exatamente o que uma linha da tabela de fato representa. Fato é a medição de um evento de negócio, quase sempre numérica. Dimensão é o contexto do evento, com os atributos usados para filtrar e agrupar.

Modelo mental: a nota fiscal. A nota inteira é o pedido. Cada linha dela traz um produto, uma quantidade e um valor. Essa linha é o item. A fato de vendas guarda linhas da nota, não notas.

**Como funciona na prática**

O desenho dimensional do Kimball tem quatro decisões, nesta ordem. Aplicadas à rede de lojas:

| Passo | Decisão | Na rede de lojas |
|---|---|---|
| 1 | Escolher o processo de negócio | A venda |
| 2 | Declarar o grão | Uma linha por item de pedido |
| 3 | Identificar as dimensões | Produto, loja e data |
| 4 | Identificar os fatos | `quantidade` e `valor_item` |

O passo 2 é o central. Toda dimensão ou fato candidato tem de ser coerente com o grão. Por isso ele vem antes dos passos 3 e 4.

Vamos testar com o pedido 104. Ele tem dois itens, de dois produtos. Sempre que possível, a dimensão deve ter um único valor para cada linha da fato. Com uma linha por pedido, qual produto entraria na linha do 104? Nenhum serve. Com uma linha por item, cada linha tem o seu.

O mesmo vale para a medida, a coluna numérica que se resume. A fato só aceita medida coerente com o grão. O total do pedido 104 não cabe na linha de item: copiado nas duas linhas, ele seria somado duas vezes.

**O equívoco comum**

Modelar pelo relatório. A diretoria pede receita por dia, e a tentação é criar só uma tabela com uma linha por dia. Só que a fato corresponde a um evento físico observável, não às exigências de um relatório. A venda aconteceu item a item.

O laboratório tem a tabela por dia, `gold.vendas_por_dia`, e ela é lida da fato. O item é o nível mais detalhado que o laboratório registra desta venda. O Kimball diz que o grão atômico resiste a pergunta imprevista, e aqui dá para ver isso. Quando alguém perguntar qual produto vendeu mais no dia 20, `vendas_por_dia` não responde: as colunas dela são dia, pedidos, pedidos pagos e receita. A `fct_vendas` responde.

### 5.2 Onde escrever o grão

Decidi o grão. Onde isso fica, para não morar só na minha cabeça?

**Como funciona na prática**

Critério da mentoria: escreva o grão como comentário no topo do SQL, com a forma "uma linha por". É assim que `lab/sql/30_gold.sql` começa:

```sql
-- Gold star. Grain written before the SQL:
--   fct_vendas: one row per order item.
--   dim_produto: one row per product and price period (type 2), plus one row for the unknown member.
--   dim_loja: one row per store. dim_data: one row per calendar day.
```

> Verificação: nível 3. Cabeçalho do arquivo executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql`. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. O comentário em si não executa: a prova dele está na seção 5.5.

Em português, com a chave que cada frase promete:

| Tabela | Uma linha significa | Chave que não pode repetir |
|---|---|---|
| `fct_vendas` | Um item de pedido | `pedido_id` e `item_seq` |
| `dim_produto` | Um produto num período de preço, mais uma linha para o membro desconhecido (unknown member) | `produto_id` e `valido_de` |
| `dim_loja` | Uma loja | `loja_id` |
| `dim_data` | Um dia do calendário | `data_id` |

Repare em `dim_produto`. O grão não é "um produto". Por isso o `JOIN` da fato com essa dimensão usa o produto e o intervalo de datas. Os capítulos 11 e 12 detalham esse encontro.

**O equívoco comum**

Escrever "dados de vendas" e achar que declarou o grão. Essa frase não diz o que conta como uma linha. Critério da mentoria: se a frase não aponta para uma chave que você consegue testar, ela ainda não é um grão.

### 5.3 Grãos não se misturam

A meta do mês e o pagamento não podem ficar na mesma tabela da venda? Fica tudo num lugar só.

**O que é**

Não podem. Grãos diferentes não se misturam na mesma fato. A documentação do Power BI pede o mesmo: a fato carrega sempre num grão consistente ("always load data at a consistent grain"). Ela também recomenda classificar cada tabela como dimensão ou fato, sem misturar os dois tipos.

No laboratório, o pedido 104 aparece em três grãos. São uma linha em `pedidos`, duas em `itens_pedido` e duas em `pagamentos`, que tem uma linha por parcela. Três significados, três tabelas. O capítulo 10 mostra o que acontece quando dois lados desses se juntam sem cuidado.

**O equívoco comum**

"Tem coluna de data, então o grão é dia." Não é. Os valores das chaves, não só as colunas, determinam o grão. Uma meta guardada no primeiro dia do mês tem grão mês, mesmo com coluna de data.

**Como inspecionar**

Olhe os valores, não o nome da coluna. Critério da mentoria: se toda data da tabela cai no dia 1, é sinal de grão mês; confirme com quem carrega a tabela.

### 5.4 O grão vale fora da gold?

Isso é só para a fato, ou serve para a silver também?

O Kimball fala da tabela de fato. Ampliar a pergunta para a silver é critério da mentoria, não dele. Ampliamos porque a limpeza depende dela. A `silver.pedidos` promete uma linha por pedido, e a `silver.itens`, uma linha por item de pedido.

No Lab 3, a bronze tem 11 linhas de pedido e a silver tem 10. Sem a frase "uma linha por pedido", nada diz que essa linha a mais é um problema.

### 5.5 Como provar que o grão vale

Escrevi o comentário. Como sei que ele é verdade? Ainda não sabe. Comentário não impede duplicata. A prova é uma consulta.

**Com consulta, à mão**

Agrupe pela chave do grão e peça as chaves com mais de uma linha: `GROUP BY chave HAVING count(*) > 1`. Zero chaves repetidas, o grão vale nesta carga. Esta é a prova do Lab 3:

```sql
SELECT 'fct_vendas' AS tabela, count(*) AS chaves_repetidas FROM (
    SELECT pedido_id, item_seq FROM gold.fct_vendas GROUP BY 1, 2 HAVING count(*) > 1) x
UNION ALL
SELECT 'itens com fornecedor', count(*) FROM (
    SELECT i.pedido_id, i.item_seq FROM silver.itens i
    JOIN bronze.produto_fornecedor pf USING (produto_id) GROUP BY 1, 2 HAVING count(*) > 1) x;
```

```text
        tabela        | chaves_repetidas 
----------------------+------------------
 fct_vendas           |                0
 itens com fornecedor |                5
(2 rows)
```

> Verificação: nível 3. Trecho de `lab/sql/31_fan_out.sql`, executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql`. Saída copiada de `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

A fato passou. A segunda linha mostra o oposto: juntar os itens com uma tabela em que um produto tem dois fornecedores repete cinco chaves. Esse `JOIN` não dá erro nenhum. No dia 20, 6 linhas viram 9, e a receita vai de 430,90 para 850,90. É o fan-out, o `JOIN` que multiplica linhas, tema do capítulo 10.

**Com teste, no dbt**

O grão também é testável sem pacote, com `unique` sobre a expressão. No projeto do laboratório, a frase de grão vira descrição, e o teste fica ao lado dela:

```yaml
  - name: stg_itens
    description: One row per order item.
    data_tests:
      - unique:
          arguments:
            column_name: "(pedido_id || '-' || item_seq)"
```

Agora vamos quebrar o grão de propósito. O Lab 6 carrega os itens do pedido 104 duas vezes e roda os dois fluxos. O `dbt build` acusa, em três linhas da saída:

```text
20:39:03  15 of 46 FAIL 2 unique_stg_itens__pedido_id_item_seq_ .......................... [FAIL 2 in 0.19s]
20:39:03  17 of 46 FAIL 1 assert_itens_batem_com_pedido .................................. [FAIL 1 in 0.03s]
20:39:04  Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
```

Depois, a comparação das duas golds:

```text
    dia     | gold_a_mao | gold_dbt 
------------+------------+----------
 2026-10-20 |     741.80 |   430.90
 2026-10-21 |     111.90 |   111.90
 2026-10-22 |     293.30 |   293.30
(3 rows)
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Trecho de `lab/projeto_dbt/models/silver/_silver.yml`. Carga dupla: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql`. À mão: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql -f /sql/30_gold.sql`. No dbt: `docker compose --profile dbt run --rm dbt dbt build`. Comparação: `docker compose exec -T postgres psql -U dw -d dw -c "select g.dia, g.receita_paga as gold_a_mao, d.receita_paga as gold_dbt from gold.vendas_por_dia g join dbt_gold.vendas_por_dia d using (dia) order by dia"`. Saídas copiadas de `lab/saidas/lab6_testes_que_param.txt`; `dbt parse` em `lab/saidas/lab5_projeto_dbt.txt`.

Mesmo erro de carga, dois resultados. O `FAIL 2` são as duas chaves repetidas. O `FAIL 1` é um segundo teste, que compara os itens com o valor do pedido. O `dbt build` sai com código 1: falha de teste faz os dependentes serem pulados, e a gold do dbt mantém 430,90. O SQL à mão sai com código 0 e publica 741,80, sem erro nenhum.

Isso não é motivo para fugir do SQL à mão. Critério da mentoria: começar assim é caminho válido, desde que você rode a consulta de prova antes de publicar e pare a carga se ela devolver chave repetida. O dbt automatiza a parada. O raciocínio é o mesmo. O capítulo 13 volta aos testes e mostra o que cada um não pega.

Com o grão escrito, a limpeza ganha critério. No próximo capítulo, vamos tratar a silver sabendo o que uma linha de pedido significa, e isso inclui aquela linha a mais.

---

[Índice](../README.md#capítulos) · [Anterior: 4. Camadas: onde cada regra mora](04-camadas.md) · [Próximo: 6. Silver: texto, coluna redundante e duplicata](06-silver.md)
