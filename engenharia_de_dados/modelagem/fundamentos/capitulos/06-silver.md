---
title: "6. Silver: texto, coluna redundante e duplicata"
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

[Índice](../README.md#capítulos) · [Anterior: 5. Grão: o que uma linha significa](05-grao.md) · [Próximo: 7. Silver: nulo com critério e CASE WHEN](07-silver.md)

## 6. Silver: texto, coluna redundante e duplicata

"Tenho o dado na bronze. Por onde começo a limpar sem estragar nada?" É o medo de quem escreve a primeira silver em SQL, e o do gerente de TI do nosso caso.

O caminho é curto: um tratamento por vez, com o antes e o depois lado a lado. Aqui vamos tratar texto, coluna redundante e duplicata. Nulo e `CASE WHEN` ficam para o capítulo 7. Datas e fuso, para o 8.

### 6.1 O que entra na silver?

**O que é**

Na documentação da Databricks, a bronze recebe o dado cru, com validação mínima. A silver limpa e valida: nulos, duplicatas, conversão de tipo, junções. E guarda ao menos uma representação validada e não agregada de cada registro.

**Critério da mentoria**, o mesmo do capítulo 4: na silver, a regra que conserta registro a registro sem mudar o grão.

**Como funciona na prática**

Acompanhe pelo Lab 1 do capítulo 20, com dois arquivos. `20_silver.sql` guarda as regras. `21_silver_antes_depois.sql` guarda a prova. É SQL à mão. O capítulo 15 monta o mesmo fluxo como projeto dbt.

Repita o mesmo ritual em cada tratamento: mostre o antes, escreva a regra, mostre o depois, conte as linhas.

### 6.2 Texto: `TRIM`, caixa e acento

"Se eu passar `TRIM` e `LOWER` em tudo, o texto fica certo?" Fica limpo. Certo é outra coisa.

**Como funciona na prática**

Os colchetes abaixo existem para você enxergar o espaço sobrando.

```sql
SELECT '[' || categoria || ']' AS antes,
       '[' || lower(unaccent(trim(categoria))) || ']' AS so_limpeza
FROM bronze.produtos_foto
WHERE _dia_referencia = (SELECT min(_dia_referencia) FROM bronze.produtos_foto) ORDER BY id;
```

```text
    antes     |  so_limpeza  
--------------+--------------
 [Vestuário]  | [vestuario]
 [mercearia]  | [mercearia]
 [UTILIDADES] | [utilidades]
 [Papelaria]  | [papelaria]
 [Papelria ]  | [papelria]
(5 rows)
```

`trim` tirou o espaço das pontas, `lower` uniformizou a caixa e `unaccent` tirou o acento. `unaccent` é extensão do Postgres, marcada como "trusted" (confiável): instala quem tem `CREATE` no banco. O laboratório já a cria.

> Verificação: nível 3. Trechos de `lab/sql/21_silver_antes_depois.sql`, executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql`. Saídas copiadas de `lab/saidas/lab1_silver_a_mao.txt`. Vale para os blocos de antes e depois deste capítulo.

**O equívoco comum**

Achar que limpar corrige. Olhe a última linha: `'Papelria '` virou `'papelria'`. Limpo e ainda errado. `TRIM`, caixa e `unaccent` não corrigem erro de digitação.

Limpar também tem custo. A cidade passa por `initcap(unaccent(trim(cidade)))`:

```text
 id |     antes     |   depois    
----+---------------+-------------
  1 | [São Paulo]   | Sao Paulo
  2 | [SAO PAULO ]  | Sao Paulo
  3 | [Santo André] | Santo Andre
(3 rows)
```

As duas grafias de São Paulo viraram uma, ao custo do acento. `Santo André` virou `Santo Andre`. Decida se o relatório aceita isso. O que não pode é acontecer sem ninguém ver.

### 6.3 De-para: a correção que tem dono

"Então quem corrige `papelria`?" Uma tabela de de-para: cada valor de origem aponta para o valor certo. Só ela leva a `papelaria`.

**Como funciona na prática**

```sql
-- TRIM, case and accent do not fix a typo: that takes a mapping someone owns.
CREATE TABLE silver.de_para_categoria (categoria_origem text PRIMARY KEY, categoria text NOT NULL);
INSERT INTO silver.de_para_categoria VALUES ('papelria', 'papelaria');

-- Latest photo of each product, not the latest global one: a product that leaves
-- the last photo keeps its name and category, so its versions stay in the dimension.
CREATE TABLE silver.produtos AS
WITH ultima_foto AS (
    SELECT DISTINCT ON (id) *
    FROM bronze.produtos_foto
    ORDER BY id, _dia_referencia DESC
)
SELECT u.id AS produto_id,
       initcap(trim(u.nome)) AS nome,
       COALESCE(d.categoria, lower(unaccent(trim(u.categoria)))) AS categoria,
       u.preco,
       u.custo  -- stays null on purpose: unknown cost is not zero cost
FROM ultima_foto u
LEFT JOIN silver.de_para_categoria d
       ON d.categoria_origem = lower(unaccent(trim(u.categoria)));
```

```text
 produto_id |        nome        | categoria  
------------+--------------------+------------
         10 | Camiseta Básica    | vestuario
         20 | Café Torrado 500g  | mercearia
         30 | Caneca De Cerâmica | utilidades
         40 | Caderno            | papelaria
         50 | Lápis              | papelaria
(5 rows)
```

> Verificação: nível 3. Trecho de `lab/sql/20_silver.sql`, executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`. Saída em `lab/saidas/lab1_silver_a_mao.txt`.

Vamos ler o bloco na ordem:

1. `ultima_foto` pega a foto mais recente de cada produto.
2. O `LEFT JOIN` procura no de-para o texto já limpo.
3. O `COALESCE` usa a categoria do de-para, se achou. Se não achou, fica o texto limpo.

`Lápis` chega como `papelaria`. Os cinco produtos continuam cinco. O `LEFT JOIN` não descarta produto, e a chave primária do de-para impede que uma linha se multiplique. Por isso este `JOIN` pode morar na silver: conserta um registro, sem mudar o grão.

Repare num custo pequeno: `initcap` escreveu `Caneca De Cerâmica`, com o "De" maiúsculo.

**O equívoco comum**

Achar que o de-para fica pronto. Suponha um erro novo, como `papelarai`. Ele não acha linha no de-para e passa como categoria nova, sem aviso.

**Critério da mentoria:** todo de-para tem dono. Escreva quem responde por ele e quem decide o nome certo. Quase sempre é o negócio, não quem escreve o SQL.

### 6.4 Coluna redundante: qual delas fica?

"A tabela traz `valor` e o texto `'45,00'`. Posso apagar uma?" Pode, depois de provar que as duas dizem a mesma coisa.

**Como inspecionar**

```sql
SELECT count(*) AS linhas,
       count(*) FILTER (WHERE replace(valor_texto, ',', '.')::numeric <> valor) AS divergentes
FROM bronze.pedidos;
```

```text
 linhas | divergentes 
--------+-------------
     11 |           0
(1 row)
```

Zero divergentes em 11 linhas. Só agora `valor_texto` pode ficar fora da silver. Nada se perde: a bronze continua com ela.

**Como decidir**

Critério da mentoria:

| Situação | O que fazer |
|---|---|
| As duas concordam, e uma tem o tipo certo | Mantenha a de tipo certo: `valor`, numérico |
| O fato só existe em texto | Converta e mantenha a convertida: `emissao_texto` vira `dia_emissao` (capítulo 8) |
| As duas divergem | Não escolha sozinho. Divergência é achado: leve a quem conhece a origem |

**O equívoco comum**

Decidir pelo nome, ou pela coincidência. `dia_emissao` e `dia_local` ficam as duas na silver. Emissão e criação podem ser fatos diferentes, mesmo quando caem no mesmo dia (inferência pelo nome das colunas, confirme com quem conhece a origem). Antes de apagar, pergunte o que cada coluna significa.

### 6.5 Duplicata: por que o `DISTINCT` não resolve?

"Tem linha repetida. Não é só pôr `DISTINCT`?" Primeiro, o que uma linha significa. Na silver de pedidos, pelo critério da mentoria do capítulo 5, uma linha é um pedido. A bronze não cumpre isso: ela guarda uma linha por carga. Deduplicar faz a tabela cumprir o grão combinado. Por isso é o único tratamento deste capítulo que muda a contagem.

**Como funciona na prática**

O pedido 103 entrou na bronze às 18h30, como `pendente`. Depois foi cancelado, e a carga seguinte trouxe a versão nova. As duas linhas ficam lá. Vamos ver o que cada caminho faz com elas.

```sql
SELECT count(*) AS bronze, (SELECT count(*) FROM (SELECT DISTINCT * FROM bronze.pedidos) d) AS com_distinct,
       (SELECT count(*) FROM (SELECT DISTINCT id FROM bronze.pedidos) d) AS ids_distintos,
       (SELECT count(*) FROM silver.pedidos) AS silver_row_number
FROM bronze.pedidos;
SELECT id, status, atualizado_em, to_char(_carregado_em AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS carregado_utc
FROM bronze.pedidos WHERE id = 103 ORDER BY _carregado_em;
SELECT pedido_id, status FROM silver.pedidos WHERE pedido_id = 103;
```

```text
 bronze | com_distinct | ids_distintos | silver_row_number 
--------+--------------+---------------+-------------------
     11 |           11 |            10 |                10
(1 row)

 id  |  status   |    atualizado_em    | carregado_utc 
-----+-----------+---------------------+---------------
 103 | pendente  | 2026-10-20 18:05:00 | 2026-10-20
 103 | cancelado | 2026-10-20 19:00:00 | 2026-11-03
(2 rows)

 pedido_id |  status   
-----------+-----------
       103 | cancelado
(1 row)
```

A data da segunda linha muda na sua execução, porque a carga usa `now()`.

`SELECT DISTINCT` só remove linhas idênticas. As versões do 103 diferem no status e nas datas, então 11 continuam 11. O `DISTINCT` guarda as duas, e um relatório por status contaria o mesmo pedido duas vezes. `DISTINCT id` acerta a conta, mas não diz qual versão vale.

A silver escolhe pela chave, e a carga mais recente fica. No bloco abaixo, olhe por enquanto só a CTE (expressão de tabela comum) `ultima_carga` e o `WHERE`:

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

> Verificação: nível 3. Trecho de `lab/sql/20_silver.sql`, com a versão, o comando e o arquivo de saída da seção 6.3.

1. `PARTITION BY id` separa as linhas por pedido.
2. `ORDER BY _carregado_em DESC` põe a carga mais recente primeiro. Esse é o desempate, escrito no código.
3. `row_number()` numera as linhas dentro de cada pedido.
4. `WHERE ordem = 1` guarda a primeira. O 103 fica um só, `cancelado`.

**O equívoco comum**

Achar que `DISTINCT`, no máximo, não ajuda. Ele pode apagar venda. Numa prova curta, com dados sintéticos, `DISTINCT produto_id, valor` juntou 3 itens reais numa linha. Na mesma prova, um pedido carregado como `pendente` e depois como `pago` continuou duas vezes. Nenhum dos dois casos deu erro.

> Verificação: nível 3, `postgres:16.15-alpine`, em 2026-11-04: `docker compose exec -T postgres psql -U dw -d dw -X -v ON_ERROR_STOP=1 -q -f /sql/77_provas_curtas_do_join.sql`. Saída em `lab/saidas/lab9_provas_curtas_do_join.txt`.

**Como decidir**

A coluna "Use" é critério da mentoria:

| Forma | O que faz | Use |
|---|---|---|
| `SELECT DISTINCT *` | Remove só linha idêntica | Não use para deduplicar por chave |
| `SELECT DISTINCT id` | Lista as chaves, sem as outras colunas | Só para contar chaves |
| `DISTINCT ON (id)` sem `ORDER BY` | Uma linha por chave; qual delas, a documentação diz que é imprevisível | Não use |
| `DISTINCT ON (id)` com `ORDER BY` | Uma linha por chave, com desempate, como em `ultima_foto` | No Postgres |
| `row_number()` com `ordem = 1` | Uma linha por chave, com desempate | No Postgres e no SQL Server |

**Como inspecionar**

Confira se o desempate desempata. Milissegundos não evitam empate dentro de uma carga: na bronze do laboratório, as 13 linhas de `itens_pedido`, gravadas num só `INSERT`, têm um só `_carregado_em`, porque `now()` devolve o início da transação (`lab/saidas/lab9_fatos_da_carga.txt`, 2026-11-04). Chave repetida dentro do mesmo lote empataria, e a carga mais recente não decidiria nada. A carga dupla do laboratório tem dois instantes distintos, como mostra a coluna `carregado_utc` da saída acima, então esse empate não foi exercitado.

Se o seu dado pode repetir chave no mesmo lote, acrescente uma segunda coluna ao `ORDER BY`, como `atualizado_em` (critério da mentoria).

No SQL Server, `DISTINCT ON` dá erro, e a documentação avisa que `ROW_NUMBER` é não determinístico quando o `ORDER BY` empata: o capítulo 17 mostra a versão em T-SQL.

### 6.6 Posso deixar a regra no Power Query e repetir no SQL?

Pode, e os números vão divergir sem erro nenhum.

**Como funciona na prática**

Numa simulação em SQL, a mesma regra de "pago" foi escrita de dois jeitos, sobre os mesmos dados:

| Regra | Soma |
|---|---|
| `status = 'pago'` | 130,00 |
| `lower(trim(status)) = 'pago'` | 170,00 |

A primeira não enxerga grafias como `PAGO` e ` Pago `, que a bronze da nossa rede também tem.

> Verificação: nível 3 como simulação, `postgres:16.15-alpine`, em 2026-11-03, fora dos scripts do laboratório. As duas regras estão em SQL. Não executamos Power Query.

**O equívoco comum**

Esperar uma regra pronta do fabricante. Não achamos página do Microsoft Learn sobre regra duplicada entre Power Query e SQL. O que ele recomenda, em outro cenário, segue o mesmo princípio: tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow (fluxo de dados), em Power Query Online, para chegar a uma fonte única da verdade. Essa página trata do Dataflow Gen1, em estado legado, e indica o Gen2.

**Critério da mentoria:** cada regra mora num lugar só. Aqui, em SQL no banco, na silver. O relatório lê a silver pronta. O capítulo 19 ajuda a decidir isso no seu contexto.

A silver já tem texto limpo, uma coluna por fato e uma linha por pedido. Falta o que veio vazio: no próximo capítulo, vamos decidir o que fazer com cada nulo.

---

[Índice](../README.md#capítulos) · [Anterior: 5. Grão: o que uma linha significa](05-grao.md) · [Próximo: 7. Silver: nulo com critério e CASE WHEN](07-silver.md)
