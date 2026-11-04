---
title: "10. Fan-out: quando o JOIN dobra o número"
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

[Índice](../README.md#capítulos) · [Anterior: 9. Fato, dimensão e esquema estrela](09-fato-dimensao-e-esquema-estrela.md) · [Próximo: 11. Histórico: o preço que o UPDATE apaga](11-historico.md)

## 10. Fan-out: quando o JOIN dobra o número

A consulta rodou. Não deu erro. O número veio alto demais. Este capítulo é para esse momento: reconhecer o JOIN no grão errado, medir e corrigir sem `DISTINCT`. Aqui, decidir o que uma linha significa vale para os dois lados do JOIN.

### 10.1 O JOIN certo que dá número errado

"Se o SQL estivesse errado, o banco não avisava?"

**O que é**

Não avisa, porque para o banco o SQL está certo. A documentação do Postgres descreve o JOIN assim: para cada linha da primeira tabela, o resultado tem uma linha para cada linha da segunda que atende à condição. Se a chave se repete na segunda, a linha se repete no resultado.

Fan-out (abrir em leque, em tradução livre) é o nome que o mercado usa para isso, sem definição nas fontes desta apostila: o JOIN que multiplica linhas porque uma das tabelas tem mais de uma linha por chave. O que tem fonte é uma regra vizinha, e a ligação é leitura da mentoria: o Kimball pede que a dimensão tenha, sempre que possível, um único valor para cada linha da fato.

**Como funciona na prática**

Vamos à menor prova. Três itens de 50,00, 30,00 e 50,00 somam 130,00. Os dois de 50,00 são de um produto com dois fornecedores. Junte os itens com a tabela de fornecedores: 5 linhas e 230,00. Nenhum erro.

> Verificação: nível 3, 2026-11-04, Postgres 16.15, tabelas temporárias com esses dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -v ON_ERROR_STOP=1 -q -f /sql/77_provas_curtas_do_join.sql`, saída em `lab/saidas/lab9_provas_curtas_do_join.txt`. A consulta: `SELECT count(*) AS linhas, sum(i.valor) AS receita FROM itens i JOIN produto_fornecedor pf USING (produto_id);`.

### 10.2 A receita do dia 20

"Como isso aparece num número que a diretoria lê?"

**Como funciona na prática**

No Lab 3, um produto tem dois fornecedores. Rode as duas consultas. A primeira fica no grão do item. A segunda junta a tabela de fornecedores.

```sql
SELECT sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga_dia_20
FROM gold.fct_vendas WHERE data_id = '2026-10-20';

SELECT count(*) AS linhas,
       sum(f.valor_item) FILTER (WHERE f.status = 'pago') AS receita_dobrada
FROM gold.fct_vendas f
JOIN gold.dim_produto p USING (produto_sk)
JOIN bronze.produto_fornecedor pf USING (produto_id)
WHERE f.data_id = '2026-10-20';
```

```text
 receita_paga_dia_20 
---------------------
              430.90
(1 row)
```

```text
 linhas | receita_dobrada 
--------+-----------------
      9 |          850.90
(1 row)
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03: `docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql`. Saída copiada de `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. As 6 linhas e os valores por item, abaixo, estão em `lab/saidas/lab9_fatos_da_carga.txt` (2026-11-04), com a mesma consulta: `SELECT f.pedido_id, f.item_seq, f.data_id, f.status, f.valor_item, p.produto_id FROM gold.fct_vendas f JOIN gold.dim_produto p USING (produto_sk) ORDER BY 3, 1, 2;`.

Vamos ver por que quase dobrou. O dia 20 tem 6 linhas na fato, uma por item de pedido. O produto de dois fornecedores está em 3 delas. Cada uma vira duas, e 6 linhas viram 9. As 9 contam todos os status; a receita soma só o pago. Dois desses 3 itens estão pagos, de 120,00 e 300,00. São 420,00 a mais, e 430,90 vira 850,90. Só os 10,90 de outro produto escapam. Fornecedor, neste conjunto de dados, não tem valor único por produto.

**O equívoco comum**

"O Power BI não me avisaria?" Às vezes, e só na relação. A documentação da Microsoft, vista na seção 9.3, diz que duplicata no lado "um" faz a atualização inteira falhar. Inferência: uma tabela já juntada no SQL chega inflada, sem relação nenhuma para barrar. Não rodamos isso no Power BI.

### 10.3 Dois lados "muitos": itens e pagamentos

"Preciso dos itens e dos pagamentos na mesma consulta. E agora?"

**Como funciona na prática**

Um pedido tem vários itens e pode ter várias parcelas. Nenhum dos dois lados tem uma linha por pedido. Junte direto e veja:

```sql
SELECT f.pedido_id, count(*) AS linhas,
       sum(f.valor_item) AS soma_itens,
       sum(pg.valor) AS soma_pagamentos
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg USING (pedido_id)
WHERE f.data_id = '2026-10-20' AND f.status = 'pago'
GROUP BY 1 ORDER BY 1;
```

```text
 pedido_id | linhas | soma_itens | soma_pagamentos 
-----------+--------+------------+-----------------
       101 |      1 |     120.00 |          120.00
       104 |      4 |     621.80 |          621.80
(2 rows)
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03, mesmo comando. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

O pedido 104 tem 2 itens e 2 parcelas. São 2 vezes 2, 4 linhas. O certo é 310,90 em cada lado, e os dois saem 621,80. Repare: dobraram juntos e seguem iguais. Comparar um total com o outro não acusa nada aqui.

**O equívoco comum**

A primeira reação é `DISTINCT`. Mas `SELECT DISTINCT` só remove linhas idênticas, como o capítulo 6 mostrou. Se a consulta trouxer a coluna da outra tabela, as cópias do fan-out não são idênticas e o `DISTINCT` não as remove. Tire essa coluna e o risco troca de lado: na prova curta de `lab/sql/77_provas_curtas_do_join.sql` (nível 3, 2026-11-04, saída em `lab/saidas/lab9_provas_curtas_do_join.txt`), `DISTINCT produto_id, valor` juntou 3 itens reais numa linha.

A segunda reação é `SUM(DISTINCT)`. Confira:

```sql
SELECT sum(f.valor_item) AS receita_com_join,
       sum(DISTINCT f.valor_item) AS receita_com_sum_distinct
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg USING (pedido_id)
WHERE f.status = 'pago';
```

```text
 receita_com_join | receita_com_sum_distinct 
------------------+--------------------------
          1347.00 |                   716.10
(1 row)
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03, mesmo comando. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

O certo, nos três dias, é 836,10. O `SUM(DISTINCT)` dá 716,10, ou seja, 120,00 a menos. Dois itens legítimos, de pedidos diferentes, valem 120,00 cada, e ele conta esse valor uma vez só. Você trocou um erro para cima por um erro para baixo.

**Como corrigir**

Leve cada lado ao grão comum antes do JOIN. Aqui, o pedido.

```sql
WITH itens AS (
    SELECT pedido_id, sum(valor_item) AS total_itens FROM gold.fct_vendas WHERE status = 'pago' GROUP BY 1
), pagos AS (
    SELECT pedido_id, sum(valor) AS total_pago FROM bronze.pagamentos GROUP BY 1
)
SELECT sum(total_itens) AS receita, sum(total_pago) AS pago, sum(total_itens) - sum(total_pago) AS diferenca
FROM itens JOIN pagos USING (pedido_id);
```

```text
 receita |  pago  | diferenca 
---------+--------+-----------
  836.10 | 836.10 |      0.00
(1 row)
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03, mesmo comando. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

Com uma linha por pedido de cada lado, o JOIN não tem o que multiplicar. O Kimball diz o mesmo para fatos: o BI nunca deve juntar duas fatos pelas chaves estrangeiras. A saída dele é o drilling across (atravessar as fatos, em tradução livre): respostas separadas, juntadas pelos atributos comuns.

Leia o 0,00 com cuidado. Esse JOIN só guarda pedido presente nos dois lados. Um pedido pago sem pagamento sai das duas somas, e a diferença segue 0,00. Numa prova curta, com itens de 100,00, 50,00 e 30,00 e pagamento só dos dois primeiros, o `JOIN` dá 150,00, 150,00 e 0,00. O `LEFT JOIN` dá 180,00, 150,00 e 30,00, com 1 pedido sem pagamento.

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -X -v ON_ERROR_STOP=1 -q -f /sql/77_provas_curtas_do_join.sql`, saída em `lab/saidas/lab9_provas_curtas_do_join.txt`.

E o fornecedor? O princípio é o mesmo: leve a tabela ao grão do produto antes de juntar. Critério da mentoria: se o relatório não usa fornecedor, não junte. Se usa, decida com o dono do número: contar fornecedores por produto ou eleger um principal. O laboratório não executa esse caso.

### 10.4 Medir antes de publicar

"Como descubro isso antes de a diretoria reclamar?"

**Como inspecionar**

Pergunte à tabela se a chave se repete. O teste é `GROUP BY chave HAVING count(*) > 1`, a mesma prova do grão da seção 5.5. No Lab 3, ele olha o grão do item na fato e no JOIN de itens com fornecedores:

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

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03, mesmo comando. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

A subconsulta devolve cada chave repetida, e a externa conta. A fato tem 0: o grão do item está de pé. Com fornecedores, 5 itens se repetem nos três dias, os 3 do dia 20 e mais 2.

Critério da mentoria, em três passos:

1. Escreva o grão do resultado antes do SQL: "uma linha é um item de pedido".
2. Rode o teste na tabela que deveria ter uma linha por chave, pela chave do JOIN, e depois no resultado, pela chave do grão.
3. Compare `count(*)` e a soma antes e depois. Se o JOIN não multiplicou nem descartou linha, nenhum dos dois muda. Mudou? Descubra qual dos dois aconteceu.

O capítulo 13 transforma esses passos em teste de dado.

### 10.5 Isso só acontece em relatório?

"Fan-out é problema de analista ou pode derrubar sistema?"

Um caso público ajuda a pensar. No postmortem de 2025-11-18, a Cloudflare conta que uma consulta de metadados filtrava só pela tabela, sem o banco. Depois de uma mudança de permissão, ela passou a devolver colunas duplicadas. O arquivo gerado dobrou de tamanho e derrubou o proxy. A remediação inclui tratar arquivo gerado internamente como entrada de usuário.

A leitura como fan-out é da mentoria, não da Cloudflare: a consulta supunha um grão que nada garantia.

Leitura complementar, no site da mentoria: [Text-to-SQL: o SQL certo e o número errado](https://carreiradados.com.br/sql-certo-numero-errado/).

Até aqui, chave repetida no JOIN virou número errado. No próximo capítulo, o mesmo produto ganha mais de uma linha de propósito, uma por preço, e é o grão escrito que separa histórico de fan-out.

---

[Índice](../README.md#capítulos) · [Anterior: 9. Fato, dimensão e esquema estrela](09-fato-dimensao-e-esquema-estrela.md) · [Próximo: 11. Histórico: o preço que o UPDATE apaga](11-historico.md)
