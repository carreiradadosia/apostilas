---
title: "12. Chave substituta e a venda na versão certa"
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

[Índice](../README.md#capítulos) · [Anterior: 11. Histórico: o preço que o UPDATE apaga](11-historico.md) · [Próximo: 13. Testes de dado: consultas que precisam voltar vazias](13-testes-de-dado.md)

## 12. Chave substituta e a venda na versão certa

Duas perguntas abrem este capítulo. "Se eu reconstruo a dimensão hoje, a venda de ontem ainda aponta para o produto certo?" Depois: "Qual foi a receita?" A primeira decide a forma da chave. A segunda tem três respostas certas, para três perguntas diferentes.

O que uma linha significa já está decidido. Na `dim_produto`, uma linha é um produto num período de preço.

### 12.1 Por que a chave natural não serve

"O produto já tem id na origem. Para que outra chave?"

**O que é**

Chave natural (natural key) é o identificador que vem do sistema de origem. Chave substituta (surrogate key) é a chave própria da dimensão, sem significado de negócio, que identifica uma versão da linha.

O Kimball dá dois motivos contra a chave natural como chave primária da dimensão. Ela se repete quando o histórico é guardado. E origens diferentes geram chaves incompatíveis. O primeiro você viu no capítulo 11: o produto 30 tem duas versões, então `30` não identifica mais uma linha.

**O que as fontes mandam**

O Kimball recomenda inteiros sem significado, em sequência a partir de 1, e isenta a dimensão de data. A Microsoft recomenda o menor tipo inteiro possível, tipicamente `IDENTITY` em ambiente SQL Server, sem significado, salvo data e hora.

O motivo do inteiro é largura. Em fato de 1 bilhão de linhas, cada byte por linha é um gigabyte, e 4 bytes representam mais de 2 bilhões de valores. O ganho em join é outra conversa. Em 1998, o Kimball o chama de "one that I strongly suspect but have never proven". Em 2003, afirma melhora por fatos e índices menores.

### 12.2 Reconstruir pode mudar o que a chave significa

"Se eu reconstruo a dimensão hoje, a venda de ontem ainda aponta para o produto certo?"

**Como funciona na prática**

Vamos ver com inteiro gerado pelo banco, nos dados do laboratório. A dimensão do dia 21 tinha 5 versões, com chaves de 1 a 5. A fato guardou 9 itens, total de 683,30. Surgiram duas versões novas, e a reconstrução com `TRUNCATE` e `RESTART IDENTITY` recomeçou a numeração do 1:

| Chave guardada na fato | Antes | Depois da reconstrução |
|---|---|---|
| 3 | Caneca, 15,00 | Caneca, 15,00 |
| 4 | Caderno, 20,50 | Caneca, 17,00 |
| 5 | Lápis, 12,00 | Caderno, 20,50 |

Resultado: 2 de 9 itens lidos errado. O lápis some do relatório. O total segue em 683,30. A busca por órfãs e a busca por nulos voltam com 0. Nenhum erro.

É o que a Microsoft evita ao mandar nunca truncar e recarregar dimensão com chave substituta gerada automaticamente, porque isso invalida as fatos. Ela avisa também que, com tipo 2, as versões históricas podem não se reconstruir.

**O equívoco comum**

"Reconstruir com identidade sempre quebra em silêncio." Nem sempre. O `TRUNCATE` padrão (`CONTINUE IDENTITY`) continua de 6 a 12 e deixa 9 órfãs, que o `relationships` acusa. Com chave estrangeira declarada, o banco recusa o `TRUNCATE`. O silêncio vem de reiniciar a sequência. Com os mesmos dados em ordem inversa de carga, são 9 de 9 itens lidos errado.

> Verificação: nível 3, em 2026-11-04, em Linux, com `postgres:16.15-alpine` e o estado do Lab 4: `docker compose exec -T postgres psql -U dw -d dw -X -q -f /sql/73_chave_identidade_reconstrucao.sql`. Saída em `lab/saidas/lab9_chave_identidade.txt`, com os nomes completos, que a tabela abrevia. Órfãs e nulos contados à mão, com o mesmo SQL da macro, não pelo teste do dbt.

No SQL Server o efeito é o mesmo com `IDENTITY`, e a gold em T-SQL usa `HASHBYTES` com `SHA2_256`, então o valor da chave difere do `md5` do Postgres: veja o capítulo 17.

### 12.3 Inteiro, hash ou mapa persistente

"Então qual forma de chave eu escolho?"

**O que é**

Há três caminhos. Hash, aqui, é um valor calculado a partir das colunas de negócio.

| Forma | A mesma versão volta com a mesma chave? | Custo | De onde vem |
|---|---|---|---|
| Inteiro gerado pelo banco | Sem truncar, sim. Truncando, não | 4 bytes, e a dimensão não pode ser apagada | Kimball e Microsoft |
| Hash das colunas de negócio | Sim: 5 de 5 versões antigas, 0 de 9 itens errados | 33 bytes gravado como texto, e cuidado com a entrada | Blog da dbt Labs, fonte de fornecedor |
| Inteiro num mapa persistente (`produto_id`, `valido_de`), fora da reconstrução | Sim: 0 de 9 itens errados | 4 bytes, mais uma tabela com estado | Variação da mentoria, num teste à parte, sem arquivo publicado |

Com hash, quando a chave muda de verdade, ela vira órfã, em vez de virar outro produto. Perder a primeira foto deixou 9 órfãs, a fato toda, porque a prova removeu a foto inteira. A falha fica visível. No mapa, `ON CONFLICT DO NOTHING` queima números: as versões novas ficaram com 9 e 11. Sequência não garante ausência de buraco.

**Quem defende o hash**

Um blog da dbt Labs: é determinístico e torna as transformações idempotentes. O mesmo texto admite armazenamento maior, texto (string) sem particionamento fácil e 50% de chance de colisão em 2^64 registros com MD5, e condiciona a escolha ao caso de cada empresa. Nas páginas da Microsoft e do Kimball que abrimos, nada trata de hash como chave, e a ausência vale só para essas páginas.

**O equívoco comum**

"O hash dispensa o join com a dimensão." Esse argumento vem de um texto cujas dimensões não têm versão. **Inferência:** com tipo 2, a fato precisa achar a versão pela data antes de saber o que entra no hash. O join por intervalo continua, com hash ou com inteiro.

**Número real: o custo da largura**

Medição só daquela prova, e nenhum número aqui vira regra. Fato sintética de 1 milhão de linhas sobre 10 mil chaves, sem compressão de coluna:

| Medida | `integer` | md5 em texto | Diferença |
|---|---|---|---|
| Chave gravada | 4 bytes | 33 bytes | |
| Tabela de fato com 3 colunas | 43 MB | 74 MB | +73% |
| Índice de chave repetida | 6,6 MB | 7,2 MB | +10% |
| Índice de chave única | 21 MB | 56 MB | +163% |

A diferença é de 32,5 bytes por linha, e com 200 bytes a mais de atributos o +73% cai para +14% (245 MB contra 280 MB). O que se transfere é o absoluto, não a porcentagem. Gravado como `uuid`, o md5 fica em 16 bytes e 58 MB (+35%). A distância entre os índices vem da deduplicação do B-tree (árvore B): com `deduplicate_items = off`, o índice repetido também dá 21 MB contra 56 MB. O tempo de join não reproduziu entre rodadas, então não publicamos tempo.

No Power BI, o motor usa value encoding (codificação por valor) em número e hash encoding (codificação por hash) em texto. Trocar texto de alta cardinalidade por número pode reduzir bastante o modelo em tabela grande, mas a doc fala de número de pedido, não de chave substituta. **Inferência:** chave de 32 caracteres tende a custar mais no modelo que um inteiro. Nada foi medido em Power BI.

> Verificação: tabela em nível 3, num teste à parte, sem arquivo publicado, em 2026-11-03, em Linux, com `psql -v ON_ERROR_STOP=1` e `postgres:16.15-alpine`. Power BI em nível 1, conferido na doc na mesma data.

### 12.4 Critério da mentoria: hash neste laboratório

"Se o Kimball manda inteiro, por que o laboratório usa hash?"

**O critério, e o que ele não é**

**Critério da mentoria.** O laboratório usa hash nos dois fluxos, com a mesma fórmula no SQL à mão e no dbt. **Não é o que o Kimball manda.** Ele manda inteiro sem significado, e a Microsoft recomenda o menor inteiro possível. Dois motivos do nosso cenário pesam mais aqui:

1. A gold é apagada e refeita a cada execução, e a foto na bronze permite refazer as versões. A mesma versão volta com a mesma chave.
2. A chave vale igual nos dois executores, então a comparação entre SQL à mão e dbt inclui a chave.

O custo fica escrito na tabela acima, medido só naquela prova e sem virar regra. O critério tem fronteira: **dimensão persistente com carga incremental pede inteiro gerado pelo banco, sem truncar.** Numa revisão de arquitetura, a primeira pergunta não é "hash ou inteiro". É "esta dimensão é refeita ou persiste?".

**Como funciona na prática**

```sql
CREATE TABLE gold.dim_produto AS
SELECT md5(v.produto_id::text || '|' || to_char(v.valido_de, 'YYYY-MM-DD')) AS produto_sk,
       v.produto_id, p.nome, p.categoria, p.custo, v.preco AS preco_tabela,
       v.valido_de, v.valido_ate
FROM silver.produtos_vigencia v
JOIN silver.produtos p USING (produto_id)
UNION ALL
-- A sale with no version points here: the revenue stays and a test counts it.
SELECT '-1', NULL, 'Desconhecido', 'desconhecido', NULL, NULL, NULL, NULL;
```

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql`, executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql`. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

No dbt, a fórmula é a mesma, sobre o início da versão no snapshot:

```sql
    md5(s.id::text || '|' || to_char(s.dbt_valid_from, 'YYYY-MM-DD')) as produto_sk,
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse` e pelo SQL compilado, em 2026-11-03, em Linux, com `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0: `docker compose --profile dbt run --rm dbt dbt build`, e a comparação com `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/50_comparar_a_mao_e_dbt.sql`. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

**Como inspecionar**

Confira a dimensão. No Lab 3, com uma foto só, são 6 linhas: 5 produtos e o membro desconhecido. Depois das três fotos, são 8: 7 versões e o membro. Rode a comparação do Lab 5: o `EXCEPT` nos dois sentidos dá zero em `vendas_por_dia`, `fct_vendas`, `dim_produto`, pedidos e atendimentos, com `produto_sk` na comparação. Nada disso pede ferramenta: o SQL à mão chega à mesma chave.

**As armadilhas do hash**

| Armadilha | O que acontece | O que fazer |
|---|---|---|
| Nulo | `md5(NULL)` dá nulo, e hash nulo passa no `unique`, que filtra nulo | `not_null` ao lado da chave |
| `concat` e `concat_ws` | `concat` faz nulo e vazio colidirem. `concat_ws` pula valor e separador: `('a', NULL, 'b')` colide com `('a', 'b', NULL)` | Não conte com eles para distinguir nulo |
| Separador | Sem ele, `'1'\|\|'12'` e `'11'\|\|'2'` colidem | Sempre um separador entre os campos |
| `DateStyle` | `date::text` obedece à sessão: a mesma versão deu três chaves em ISO, SQL e German | `to_char(dia, 'YYYY-MM-DD')` |
| Número | `20.5` e `20.50` geram textos e chaves diferentes | A fórmula daqui leva só id e data |

O risco do `DateStyle` é do SQL à mão e de outros clientes, porque a sessão do dbt fica em ISO. O `generate_surrogate_key`, do `dbt_utils`, troca nulo por um marcador, separa os campos com `'-'` e aplica md5. Fica como referência, porque o laboratório não usa pacote externo.

> Verificação: tabela em nível 3, num teste à parte, sem arquivo publicado, em 2026-11-03, com `postgres:16.15-alpine`. `generate_surrogate_key` em nível 1, lido na tag 1.4.1 do `dbt_utils`.

**Por que não o `dbt_scd_id`**

O snapshot do dbt já traz um hash, o `dbt_scd_id`. Três motivos para não usar:

1. A doc diz que ele é chave única por linha, de uso interno, e não o trata como chave de dimensão.
2. A doc diverge do código. No pacote, a fórmula combina `unique_key` e `updated_at`, e o exemplo da página bate com ela. A frase sobre `check`, que fala em chave e `check_cols`, casou com 0 de 7 linhas.
3. Ele depende do relógio. Com `updated_at` no dia da foto, apagar o snapshot e refazer os três dias devolve as mesmas 7 chaves. Sem `updated_at`, o hash leva `now()`, e nenhuma volta.

> Verificação: nível 3, num teste à parte, sem arquivo publicado, em 2026-11-03, com `dbt-core` 1.12.6, `dbt-adapters` 1.24.5 e `dbt-postgres` 1.11.0. Fórmula lida no pacote instalado e conferida no banco. Outras versões e o dbt v2 não foram testados.

### 12.5 A venda na versão vigente na data

"Tenho as versões. Como a venda acha a dela?"

**Como funciona na prática**

```sql
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

> Verificação: nível 3. Trecho de `lab/sql/30_gold.sql`, com o comando e as versões da seção 12.4, em 2026-11-03. Com as três fotos, `lab/saidas/lab4_preco_update_e_scd2.txt` traz 13 itens, 13 chaves e 836,10.

Três decisões moram nesse `JOIN`.

**1. `>=` e `<`.** É o intervalo meio aberto do capítulo 11: 13 linhas e 836,10. `BETWEEN` com fim em 9999-12-31 dá 14 linhas e 916,10, porque o dia da troca casa com duas versões. Guardar 9999-12-31 na versão aberta tira o `OR` e mantém 836,10, mas não salva o `BETWEEN`.

**2. A data local.** **Critério da mentoria, com prova:** a data da venda entra no mesmo calendário da foto, o local. Em UTC, os pedidos 104 e 110 mudam de dia, e uma venda sintética do dia 21 às 22h30 sai com a versão de 20,00 em vez da de 20,50. A foto diária tem limite: venda sintética à 1h do dia em que a rotina das 3h trocou o preço casa com o preço novo e mostra diferença de 0,50 que não houve.

**3. A busca na validade, não a versão aberta.** A Microsoft pede a versão corrente ao descrever o processamento da fato e a busca dentro da validade ao falar de recarga. A página de Power BI pede busca por tempo relevante à data do fato. O laboratório refaz a fato inteira, então busca na validade. Pedir só a versão aberta deixa 4 itens com o preço de tabela de hoje, sem mudar a receita. A Microsoft trata truncar e recarregar fato grande como último recurso. **Critério da mentoria:** em fato grande, repense essa recarga.

> Verificação: 916,10, as vendas sintéticas e os 4 itens em nível 3, em 2026-11-04, com `postgres:16.15-alpine` e o estado do Lab 4. Saídas em `lab/saidas/lab9_ligacao_com_a_versao.txt` e `lab/saidas/lab9_venda_sem_versao.txt`.

### 12.6 A venda que não acha versão nenhuma

"E a venda anterior à primeira foto? E o produto que nenhuma foto viu?"

**Como funciona na prática**

Agora somamos 4 vendas sintéticas às 13 reais, num schema à parte. A receita paga certa é 946,10, e duas vendas ficam sem versão:

| Saída | Linhas | Receita paga | O que os testes de chave dizem |
|---|---|---|---|
| `JOIN`: a venda some | 15 | 877,10 | Nada acusa |
| `LEFT JOIN`: chave nula | 17 | 946,10 | `not_null` acusa 2 |
| Primeira versão recuada | 17 | 946,10 | Resolve só o produto conhecido, 1 fica nula |
| Versão zero, com preço nulo | 17 | 946,10 | Resolve só o produto conhecido, 1 fica nula |
| Membro desconhecido | 17 | 946,10 | `not_null` e `relationships` passam |

Recuar a primeira versão vem de uma sugestão da Microsoft: guardar a menor data da dimensão de data no início da primeira versão, "to represent the initial version". **Inferência:** isso evita fato anterior à primeira versão. Aplicada a preço, atribui valor que nenhuma foto viu: a venda sintética de 19/10 ganhou tabela de 60,00.

> Verificação: a tabela e a venda de 19/10 em nível 3, em 2026-11-04, com `postgres:16.15-alpine` e o estado do Lab 4: `docker compose exec -T postgres psql -U dw -d dw -X -v ON_ERROR_STOP=1 -q -f /sql/75_venda_sem_versao.sql`. Saída em `lab/saidas/lab9_venda_sem_versao.txt`.

O membro desconhecido (unknown member) tem fonte. Na falha da busca, a Microsoft manda inserir a linha da fato com chave válida e avisa que isso requer atualização posterior. Sugere, como exemplo, membro especial com -1 para `Unknown`, e chama de boa prática a chave `NOT NULL`. O Kimball pede linha padrão e, para fato que chega antes, linha provisória com a chave natural como atributo. A Microsoft chama isso de inferred member (membro inferido).

**Critério da mentoria:** venda sem versão vai para o membro `'-1'`, com um teste que conta. A receita fica e o problema continua à vista.

**O equívoco comum**

"Passou no `not_null` e no `relationships`, então está tudo ligado." Com o membro, os dois passam, porque `'-1'` é chave válida. O `relationships` também exclui nulo: com duas vendas sem versão e chave nula, ele passa e o `not_null` falha com 2. Na chave natural, ele acusa só o produto que nenhuma foto viu (1), não a venda anterior à primeira foto. Só um teste que conta acusa (`WARN 2`).

```sql
{{ config(severity='warn') }}

-- Warns when a sale found no product version, so the unknown member does not hide it.
select f.pedido_id, f.item_seq, f.data_id, i.produto_id, f.valor_item
from {{ ref('fct_vendas') }} f
join {{ ref('stg_itens') }} i using (pedido_id, item_seq)
where f.produto_sk = '-1'
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0: `docker compose --profile dbt run --rm dbt dbt build`, com `PASS=44 WARN=2 ERROR=0 SKIP=0 TOTAL=46` em `lab/saidas/lab5_projeto_dbt.txt`. O `WARN 2` está em `lab/saidas/lab9_dbt_venda_sem_versao.txt`, com as vendas sintéticas de `lab/sql/75b_vendas_sinteticas_na_bronze.sql`, em 2026-11-04.

**Como inspecionar**

Nos dados do laboratório, `assert_vendas_sem_versao` passa: nenhuma venda real cai no membro. Os dois avisos do `dbt build` são outros. Fica um limite: a reconciliação de receita que pegaria a venda perdida pelo `JOIN` não foi executada nesse cenário.

### 12.7 Qual foi a receita? Três respostas certas

"Afinal, a receita paga é 836,10, 840,20 ou 842,20?"

**O que é**

| Receita paga | Conta | Pergunta que responde |
|---|---|---|
| 836,10 | Quantidade por `preco_unitario` do item | Quanto vendemos ao preço praticado? Confere com `pedidos.valor` |
| 840,20 | Quantidade pelo `preco_tabela` da versão na data | Quanto daria a tabela do dia da venda? |
| 842,20 | Quantidade pelo preço da versão aberta | Quanto daria a tabela de hoje? |

A diferença toda vem de um item pago, o 104/2: vendido a 10,90, com tabela de 15,00 no dia e 17,00 hoje. Daí saem os 4,10 e os 2,00.

**O equívoco comum**

"Então houve desconto de 4,10." Os dados não dizem isso. Não há coluna de desconto nem de promoção, e o motivo da diferença não está no dado. O Lab 4 apelida a conta de `desconto`, e isso é só o nome da coluna calculada. Antes de afirmar, pergunte a quem vende.

Outro erro é somar preço, que é não aditivo. Microsoft: "rates, like unit prices" são não aditivos, e "unit price multiplied by order quantity produces sales revenue, which is additive". Power BI: "It should never be summed". Kimball: "you don't need to store the unit price", porque ele sai do valor dividido pela quantidade. Na caneca, a média simples dá 13,63 e a ponderada, 14,18. Para atributo numérico que muda muito, a Microsoft admite levar à fato como medida.

Quando pedirem "a receita", escreva junto qual das três é.

> Verificação: 836,10 e o item 104/2 em nível 3, em `lab/saidas/lab3_gold_estrela_e_fan_out.txt` e `lab/saidas/lab4_preco_update_e_scd2.txt`, em 2026-11-03, com `postgres:16.15-alpine`. 840,20, 842,20 e as médias em nível 3, em 2026-11-04, em `lab/saidas/lab9_receita_tres_precos.txt`.

A chave se sustenta e a receita tem nome. Falta quem avise quando isso deixar de ser verdade: no próximo capítulo, os testes viram consultas que precisam voltar vazias.

---

[Índice](../README.md#capítulos) · [Anterior: 11. Histórico: o preço que o UPDATE apaga](11-historico.md) · [Próximo: 13. Testes de dado: consultas que precisam voltar vazias](13-testes-de-dado.md)
