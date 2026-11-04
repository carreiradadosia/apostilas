---
title: "7. Silver: nulo com critério e CASE WHEN"
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

[Índice](../README.md#capítulos) · [Anterior: 6. Silver: texto, coluna redundante e duplicata](06-silver.md) · [Próximo: 8. Silver: datas e fuso horário](08-silver.md)

## 7. Silver: nulo com critério e CASE WHEN

"Coloco `COALESCE` em tudo, para não sobrar nulo?" É a dúvida de quem abre a silver pela primeira vez. A nossa resposta é não. Nulo que deve alertar não vira zero.

`COALESCE` devolve o primeiro argumento que não é nulo. Ele é útil, e também é a forma mais rápida de apagar um problema. A frase guia desta apostila vale aqui, uma escala abaixo: antes do `COALESCE`, decida o que o vazio significa.

### 7.1 O que fazer com cada nulo?

"Existe uma regra, ou decido coluna por coluna?" Existe um critério, e ele olha para o lugar em que o nulo está.

**O que é**

O critério é do Kimball, e tem três casos.

| Onde o nulo está | O que fazer | Motivo |
|---|---|---|
| Medida, a coluna numérica da fato que se resume | Fica nulo | `SUM`, `COUNT`, `MIN`, `MAX` e `AVG` tratam o nulo corretamente |
| Chave estrangeira na fato, a coluna que aponta para a dimensão | Vira uma linha padrão na dimensão, de desconhecido ou não aplicável, com chave substituta própria | Chave estrangeira nula na fato deve ser evitada |
| Atributo descritivo na dimensão | Vira texto, como "Unknown" ou "Not Applicable" | Bancos diferentes agrupam e filtram nulo de forma inconsistente |

A chave estrangeira volta no capítulo 12, com o membro desconhecido. Aqui ficamos com os outros dois casos.

**O equívoco comum**

O `COALESCE(valor, 0)` parece inofensivo, porque a soma não muda. Vamos ver numa conta de 6 itens, 1 deles sem valor.

| Conta | Valor nulo | Trocado por zero |
|---|---|---|
| Soma | 220,00 | 220,00 |
| Média | 44,00 | 36,67 |

A soma igual é o que engana. O número parece completo, e o item sem valor some do radar. Sem a troca, `count(valor)` dá 5 e `count(*)` dá 6. Essa diferença é o sinal da falha, e o zero apaga o sinal.

> Verificação: nível 3, `postgres:16.15-alpine`, em 2026-11-03. Conta avulsa, fora dos scripts do laboratório: não há arquivo em `lab/saidas/` para ela. Para refazer: uma tabela de 6 itens com 1 valor nulo, e `sum`, `avg` e `count` com e sem `COALESCE`.

Outro detalhe: soma de zero linhas é nulo, não zero. Critério da mentoria: nesse caso, o nulo diz que não houve linha, não que faltou dado. Mostrar zero no relatório final pode fazer sentido. Trocar o valor do item, na silver, não faz.

### 7.2 Como decido na tabela de verdade?

"Entendi os casos, mas e na minha tabela?" Vamos aos três nulos da rede de lojas. Escreva a regra e o motivo antes do SQL.

| Coluna | Regra | Motivo |
|---|---|---|
| `custo` do produto | Fica nulo e avisa | Custo desconhecido não é custo zero |
| `status` do pedido | Vira `'desconhecido'` e é contado | Pedido fora de `pago` sai da receita, e alguém precisa ver |
| `cliente` do pedido | Vira `'Não informado'` | Critério da mentoria: nenhuma conta depende dele, e nulo e vazio viram um rótulo só |

O Kimball fala de medida na fato e de atributo na dimensão. Aqui, as três colunas estão na silver. Levar o critério para lá, e tratar `custo` como medida porque ele entra em conta, é critério da mentoria.

**Como funciona na prática**

No produto, o custo passa sem tratamento nenhum, de propósito.

```sql
       u.preco,
       u.custo  -- stays null on purpose: unknown cost is not zero cost
```

No pedido, o cliente e o status ganham regra.

```sql
       COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado') AS cliente,
       valor,
       lower(trim(status)) AS status_origem,
       CASE lower(trim(status))
           WHEN 'pago' THEN 'pago'
           WHEN 'cancelado' THEN 'cancelado'
           WHEN 'pendente' THEN 'pendente'
           ELSE 'desconhecido'
       END AS status,
```

> Verificação: nível 3. Trechos de `lab/sql/20_silver.sql`, executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`. Saída em `lab/saidas/lab1_silver_a_mao.txt`.

**O custo: fica nulo e avisa**

O lápis, produto 50, veio sem custo, e vendemos 12,00 dele. Compare as duas colunas da direita.

```text
 produto_id | custo_silver | venda  | margem_com_nulo | margem_com_zero 
------------+--------------+--------+-----------------+-----------------
         10 |        30.00 | 600.00 |          300.00 |          300.00
         20 |        20.00 | 133.20 |           53.20 |           53.20
         30 |         7.00 |  10.90 |            3.90 |            3.90
         40 |        10.00 |  80.00 |           40.00 |           40.00
         50 |              |  12.00 |                 |           12.00
(5 rows)

 margem_soma_ignora_nulo | margem_com_zero | itens_sem_custo 
-------------------------+-----------------+-----------------
                  397.10 |          409.10 |               1
(1 row)
```

Com zero, o lápis teria 100% de margem, a maior da rede. O total iria para 409,10, como se ele saísse de graça. E 397,10 também não é a margem completa: é a margem dos itens com custo, porque a soma ignora o nulo. A margem completa depende de um custo que a origem não mandou. Por isso o nulo vem com aviso, e `itens_sem_custo` fica ao lado do total.

**O cliente: vira rótulo**

Dois pedidos vieram sem cliente. O 105 veio nulo, e aparece em branco na coluna `antes`. O 110 veio com texto vazio, e aparece como `[]`.

```text
 id  |     antes      |    depois     
-----+----------------+---------------
 101 | [  Cliente A ] | Cliente A
 103 | [cliente c]    | Cliente C
 105 |                | Não informado
 107 | [cliente f ]   | Cliente F
 110 | []             | Não informado
(5 rows)
```

Para quem lê o relatório, os dois são a mesma coisa. O `NULLIF` devolve nulo quando o texto é igual a vazio, e o `COALESCE` troca o nulo pelo rótulo.

Aqui não contamos, e isso também é uma decisão. Critério da mentoria: nenhuma conta depende do nome do cliente. Se a área cobrar cadastro completo, conte também.

> Verificação: nível 3. Saídas do `lab/sql/21_silver_antes_depois.sql`, em 2026-11-03, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql`. Arquivo `lab/saidas/lab1_silver_a_mao.txt`, o mesmo do Lab 1.

### 7.3 E quando a origem manda um status novo?

"O sistema criou `estornado` e ninguém me avisou. O que a silver faz?" Depende de uma palavra.

**O que é**

A documentação do Postgres é direta: "If the ELSE clause is omitted and no condition is true, the result is null." Sem `ELSE`, se nenhuma condição casa, o resultado é nulo.

**Como funciona na prática**

```sql
SELECT status_novo,
       CASE status_novo WHEN 'pago' THEN 'pago' WHEN 'cancelado' THEN 'cancelado' END AS sem_else,
       CASE status_novo WHEN 'pago' THEN 'pago' WHEN 'cancelado' THEN 'cancelado' ELSE 'desconhecido' END AS com_else
FROM (VALUES ('pago'), ('estornado')) AS t(status_novo);
```

```text
 status_novo | sem_else |   com_else   
-------------+----------+--------------
 pago        | pago     | pago
 estornado   |          | desconhecido
(2 rows)
```

> Verificação: nível 3. Saída do `lab/sql/21_silver_antes_depois.sql`, em 2026-11-03, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql`. Arquivo `lab/saidas/lab1_silver_a_mao.txt`.

Sem `ELSE`, o estorno vira nulo em silêncio. A consulta roda, e nada reclama. Com `ELSE` nomeado, o valor continua visível. O nome é escolha sua: `'desconhecido'` ou `'nao_mapeado'`, por exemplo.

No `CASE` da silver, status nulo e status novo caem no mesmo `ELSE`. Critério da mentoria: a silver guarda também o `status_origem`. O `status` diz que não reconhecemos. O `status_origem` diz o que chegou.

**O equívoco comum**

Achar que a lista de `WHEN` está completa. Ela descreve o que a origem mandava no dia em que você escreveu. O `ELSE` é para o dia seguinte.

### 7.4 `'desconhecido'` na tabela resolve?

"Agora não tem mais nulo. Terminei?" Ainda não. Inferência: rótulo que ninguém conta é o nulo com outro nome.

A apostila de Orquestração trocou o status nulo por `'desconhecido'` com `COALESCE`. Continua certo, porque atributo descritivo vira texto. O `CASE` com `ELSE` faz o mesmo e cobre também o valor novo. O que faltava é contar.

**Como inspecionar**

Comece à mão. Rode esta consulta depois de cada carga e olhe a linha `desconhecido`.

```sql
SELECT status, count(*) AS pedidos, sum(valor) AS valor FROM silver.pedidos GROUP BY 1 ORDER BY 1;
```

```text
    status    | pedidos | valor  
--------------+---------+--------
 cancelado    |       1 |  45.00
 desconhecido |       1 |  80.50
 pago         |       7 | 836.10
 pendente     |       1 |  15.00
(4 rows)
```

> Verificação: nível 3. Consulta e saída do `lab/sql/21_silver_antes_depois.sql`, em 2026-11-03, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql`. Arquivo `lab/saidas/lab1_silver_a_mao.txt`.

É o pedido 102, que veio com status nulo. Os 80,50 dele ficam fora dos 836,10 da receita paga. Se ele foi pago, ninguém sabe olhando só para o total.

A mesma pergunta vira teste de dado quando o fluxo vira projeto dbt, no capítulo 15. Teste de dado é a consulta que busca as linhas que desmentem a regra: zero linhas, passou. Por ora, leia só o `SELECT`.

```sql
{{ config(severity='warn') }}

-- Warns when the source sends a status nobody mapped, so the else branch does not hide it.
select pedido_id, status_origem
from {{ ref('stg_pedidos') }}
where status = 'desconhecido'
```

```text
20:38:12  18 of 46 WARN 1 assert_status_desconhecido ..................................... [WARN 1 in 0.04s]
20:38:12  24 of 46 WARN 1 not_null_stg_produtos_custo .................................... [WARN 1 in 0.07s]
20:38:13  Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
```

> Verificação: nível 3 pela execução, com `docker compose --profile dbt run --rm dbt dbt build`, e nível 2 por `dbt parse` e SQL compilado, em 2026-11-03, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Código em `lab/projeto_dbt/tests/assert_status_desconhecido.sql`, saída em `lab/saidas/lab5_projeto_dbt.txt`, o arquivo do Lab 5.

`WARN 1` é aviso com uma linha encontrada: o pedido 102. Com `severity='warn'` (severidade de aviso), o aviso aparece e a contagem fica registrada na saída. O outro `WARN 1` é o custo do lápis, num teste `not_null` (não nulo) também em aviso. Os dois estão ali de propósito. Um `WARN 2` amanhã diz que mais um pedido ficou sem status reconhecido.

Um `accepted_values` (valores aceitos) também pega o `ELSE` nomeado, se a lista deixar esse nome de fora. No laboratório, a lista inclui `desconhecido`, então esse teste passa. Quem conta é o teste acima. O que para a carga e o que só avisa é outra decisão, no capítulo 13.

Tudo aqui rodou em Postgres, em Linux. O critério não muda de banco, e a sintaxe muda. No SQL Server, `ISNULL` usa o tipo do primeiro argumento e pode truncar o rótulo: veja o capítulo 17.

Nulo decidido, rótulo contado. Falta a coluna que vem preenchida e mesmo assim engana: a data gravada em UTC e lida como horário local. É o próximo capítulo.

---

[Índice](../README.md#capítulos) · [Anterior: 6. Silver: texto, coluna redundante e duplicata](06-silver.md) · [Próximo: 8. Silver: datas e fuso horário](08-silver.md)
