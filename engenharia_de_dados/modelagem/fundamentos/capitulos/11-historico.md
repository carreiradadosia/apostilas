---
title: "11. Histórico: o preço que o UPDATE apaga"
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

[Índice](../README.md#capítulos) · [Anterior: 10. Fan-out: quando o JOIN dobra o número](10-fan-out.md) · [Próximo: 12. Chave substituta e a venda na versão certa](12-chave-substituta-e-a-venda-na-versao-certa.md)

## 11. Histórico: o preço que o UPDATE apaga

"O sistema troca o preço toda noite e não guarda o anterior. Como eu respondo qual era o preço no dia da venda?" A pergunta veio de um gerente de TI, numa sessão de mentoria. Ela vale para qualquer sistema que grava por cima.

Aqui, decidir o que uma linha significa é escolher: uma linha é um produto, ou um produto num período de preço? Este capítulo dá um caminho para decidir e mostra como consultar a versão da data certa.

### 11.1 O que sobra depois do UPDATE

"Não dá para pedir o preço de ontem ao sistema?" Se ele grava por cima, não dá. Vamos ver isso acontecer.

**Como funciona na prática**

Na segunda noite do Lab 4, a origem roda isto:

```sql
-- Second night: the job touches every row and two prices are overwritten in place.
UPDATE produtos SET atualizado_em = '2026-10-22 03:00';
UPDATE produtos SET preco = 20.00 WHERE id = 40;
UPDATE produtos SET preco = 17.00 WHERE id = 30;
```

Depois, perguntamos pelo caderno vendido no pedido 102, do dia 20:

```sql
SELECT i.pedido_id, i.preco_unitario, p.preco AS preco_na_origem_hoje
FROM replica.itens_pedido i JOIN replica.produtos p ON p.id = i.produto_id
WHERE i.pedido_id = 102 AND i.produto_id = 40;
```

```text
 pedido_id | preco_unitario | preco_na_origem_hoje
-----------+----------------+----------------------
       102 |          20.50 |                20.00
(1 row)
```

A venda foi a 20,50. Dois dias depois, a origem só mostra 20,00. Nenhum erro, nenhum aviso. O valor só sobrevive porque o item do pedido guardou o próprio preço.

**O equívoco comum**

Medir a mudança pela data de alteração. O primeiro `UPDATE` tocou as 5 linhas, e o preço mudou em 2. Na noite anterior, a rotina tocou as 5 e não mudou preço nenhum. Guarde esse detalhe: ele volta na árvore do preço, e o capítulo 15 mostra o que ele faz com o snapshot do dbt.

> Verificação: nível 3. `docker compose exec -T postgres psql -U erp -d erp -v ON_ERROR_STOP=1 -f /sql/erp_noite_22.sql` e `docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Saída em `lab/saidas/lab4_preco_update_e_scd2.txt`.

### 11.2 Tipo 1 e tipo 2: quadro branco e caderno

"Qual é a diferença entre esses tipos de que todo mundo fala?" Dimensão de mudança lenta (SCD, slowly changing dimension) é a técnica para tratar o atributo que muda. Dois tipos cobrem a nossa decisão. Vigência é o período em que uma versão vale.

**O que é**

- **Tipo 1** sobrescreve o valor antigo e destrói o histórico. Agregados e cubos afetados precisam ser recalculados.
- **Tipo 2** cria uma linha nova na dimensão a cada mudança, com chave substituta nova. Pede no mínimo três colunas: início de vigência, fim de vigência e indicador de linha vigente.

O tipo 1 é um quadro branco: você apaga e escreve por cima. Ele sempre mostra o valor de hoje, e só o de hoje. O tipo 2 é um caderno: você escreve na linha de baixo, com data, e pode voltar a página. Nenhum dos dois é errado por si só. Muita coisa pede só o quadro branco.

No laboratório, a vigência tem início e fim. A terceira coluna não existe: `valido_ate` nulo faz o papel do indicador. A chave substituta fica para o capítulo 12.

**O equívoco comum**

"Eu não uso SCD." Usa, sim. Uma atualização não incremental de uma tabela de dimensão no Power BI produz o efeito de um tipo 1. Quem atualiza a dimensão do BI assim toda noite já faz tipo 1 sem saber.

**O BI resolve?**

Não, quando a origem não guarda versões. A Microsoft diz que, nesse caso, é preciso um sistema intermediário, como um armazém de dados (data warehouse), para detectar e guardar as mudanças. A fato busca a chave da versão vigente na data do fato. O modelo semântico do Power BI usa Power Query e não consegue produzir essa carga, mas pode carregar uma dimensão tipo 2 já pronta. A mesma página avisa que transformar no Power Query pode ser difícil com grande volume ou com SCD, e recomenda desenvolver antes um armazém com carga periódica.

Isso é o que a documentação diz. Nada aqui rodou em Power Query. Critério da mentoria: o histórico mora antes do BI, em SQL, no banco.

### 11.3 A árvore do preço

"Então preciso de tipo 2 em tudo?" Não. Vamos decidir por perguntas, nesta ordem. A árvore é critério da mentoria: nenhuma documentação a escreve assim. Os fatos sobre cada técnica têm fonte na seção Fontes verificadas, no fim da apostila.

**As cinco perguntas**

1. **A venda já registra o preço praticado?** Se sim, leve esse preço para a fato, e a receita está salva. Siga só se alguém pede o preço de tabela do dia, por exemplo para medir desconto. Ninguém pede? Pare: tipo 1 na dimensão serve. Se a venda não registra o preço, siga: a versão virou necessária até para a receita.
2. **A origem já guarda versão?** Se sim, leia de lá, sem copiar o histórico. Se não, alguém precisa guardar. Siga.
3. **Quanto muda de fato?** Meça no valor, não na data de alteração. Se muda pouco, o tipo 2 economiza linhas. Se tudo muda toda noite, a aritmética é simples: o tipo 2 tem o volume da foto. Para atributo que muda muito, a Microsoft recomenda guardar o valor como medida na fato.
4. **Precisa do valor em qualquer instante, ou o do fechamento serve?** Se o fechamento do dia serve, a foto diária resolve. Se precisa de qualquer instante, a foto não alcança. Sobra a tabela temporal na origem ou a captura de mudanças (change data capture, CDC), que é assunto de ingestão.
5. **Dá para refazer se errar?** Com a foto crua guardada, a vigência se refaz. Sem ela, o tipo 2 é o único registro da história, e pode não se reconstruir. Nesse caso, proteja essa tabela como dado de origem.

**As saídas, com custo e risco**

Custo, risco e quando escolher também são critério da mentoria.

| Saída | O que guarda | Custo | Risco | Quando escolher |
|---|---|---|---|---|
| Nada (tipo 1) | Só o valor de hoje | Nenhum | O passado some, e agregados afetados pedem recálculo | Ninguém pergunta pelo valor antigo |
| Preço na fato de venda | O preço praticado, por item | Uma coluna na fato | Só conhece o que foi vendido. O preço de tabela segue perdido | A venda registra o preço e a pergunta é receita |
| Foto diária por produto e dia | O estado de cada dia | Uma linha por produto, por dia | Não vê o que mudou e voltou. A foto que falhou não volta | O fechamento serve e você quer poder refazer |
| Tipo 2 | Uma linha por período de preço | Lógica de vigência, chave substituta e busca por data | Intervalo errado duplica venda. Pode não se reconstruir | Muda pouco e a consulta pede a versão por data |
| Tabela temporal (temporal table) no SQL Server | Uma linha de histórico por modificação | Mexer na tabela que recebe o `UPDATE` (inferência) | Grava mesmo sem mudança de valor. Vigência em UTC | Precisa de qualquer instante e quem cuida do banco aceita |

Nas páginas que conferimos, a tabela temporal aparece em todas as edições do SQL Server, inclusive Express. Ela não aceita `TRUNCATE` com versionamento ligado. Só que ela grava uma linha a cada modificação. Com a rotina do nosso laboratório, que toca todas as linhas toda noite, o histórico cresceria sem preço nenhum mudar (inferência). Essa saída fica em nível 1: a mentoria não a testou. O capítulo 17 volta a ela.

**A árvore na rede de lojas**

Vamos percorrer. A venda registra `preco_unitario`, então a receita está salva. Só que queremos o preço de tabela, para medir desconto. A origem não guarda versão. Em três dias, 5 produtos, dois preços mudaram uma vez. O fechamento do dia serve. E queremos poder refazer.

A saída é uma combinação: foto diária crua, tipo 2 derivado dela, e o preço praticado na fato. O resultado aparece aqui:

```text
 pedido_id | item_seq |  data_id   | produto_id | preco_unitario | preco_tabela | desconto
-----------+----------+------------+------------+----------------+--------------+----------
       102 |        2 | 2026-10-20 |         40 |          20.50 |        20.50 |     0.00
       103 |        1 | 2026-10-20 |         30 |          15.00 |        15.00 |     0.00
       104 |        2 | 2026-10-20 |         30 |          10.90 |        15.00 |    -4.10
       107 |        1 | 2026-10-21 |         30 |          15.00 |        15.00 |     0.00
       108 |        2 | 2026-10-22 |         40 |          20.00 |        20.00 |     0.00
(5 rows)
```

O item do pedido 104 saiu 4,10 abaixo de um preço de tabela que a origem não mostra mais. Se foi desconto, o dado não diz: não há coluna de desconto nem de promoção, e o capítulo 12 volta a isso. A diferença só aparece porque alguém guardou a versão.

> Verificação: nível 3. `docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Saída em `lab/saidas/lab4_preco_update_e_scd2.txt`.

### 11.4 Foto crua na bronze, vigência na silver

"Em que camada isso mora?" Nenhuma fonte diz. Critério da mentoria: a foto fica crua na bronze, e a silver monta a vigência. A foto é o que foi observado. A vigência é uma regra sobre isso, e regra se refaz.

**Como funciona na prática**

Uma foto é cópia agendada do estado da tabela num dia:

```sql
-- Daily photo of the product table, raw. Run with: psql -v dia=2026-10-20 -f ...
DELETE FROM bronze.produtos_foto WHERE _dia_referencia = :'dia'::date;
INSERT INTO bronze.produtos_foto SELECT *, :'dia'::date FROM replica.produtos;
```

O `DELETE` antes do `INSERT` deixa rodar de novo o mesmo dia sem dobrar a foto. A silver lê as fotos e fica com uma linha por período de preço:

```sql
-- Type 2 history derived from the photos: one row per price period, half-open interval.
CREATE TABLE silver.produtos_vigencia AS
WITH fotos AS (
    SELECT id AS produto_id, preco, _dia_referencia AS dia,
           lag(preco) OVER (PARTITION BY id ORDER BY _dia_referencia) AS preco_anterior,
           row_number() OVER (PARTITION BY id ORDER BY _dia_referencia) AS ordem
    FROM bronze.produtos_foto
), mudancas AS (
    SELECT produto_id, preco, dia AS valido_de
    FROM fotos
    WHERE ordem = 1 OR preco IS DISTINCT FROM preco_anterior
)
SELECT produto_id, preco, valido_de,
       lead(valido_de) OVER (PARTITION BY produto_id ORDER BY valido_de) AS valido_ate
FROM mudancas;
```

O passo a passo:

1. `lag` traz o preço da foto anterior do mesmo produto.
2. O `WHERE` fica com a primeira foto e com as fotos em que o preço mudou.
3. `lead` usa o início da versão seguinte como fim desta. O fim de uma é o início da outra.

```text
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

 linhas_nas_fotos | linhas_no_tipo_2
------------------+------------------
               15 |                7
(1 row)
```

As fotos guardam 15 linhas: 5 produtos em 3 dias. O tipo 2 guarda 7: os 5 produtos e as 2 trocas. Se os 5 mudassem em cada foto, o tipo 2 também teria 15. A pergunta 3 da árvore é essa conta.

Tudo isso é SQL à mão, e é um começo válido. Você não precisa de ferramenta para ter histórico. Precisa de agenda.

> Verificação: nível 3. Foto: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-21 -f /sql/11_bronze_foto_precos.sql`, repetido com o dia 22; a do dia 20 vem do Lab 1. Vigência: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql`. Consulta: `docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Saída em `lab/saidas/lab4_preco_update_e_scd2.txt`.

**Por que guardar a foto, se o tipo 2 é menor?**

Porque o tipo 2 pode não se reconstruir. A Microsoft manda nunca truncar e recarregar uma dimensão com chave substituta gerada automaticamente, porque isso invalida as fatos. E avisa que, com tipo 2, pode não ser possível regenerar as versões históricas.

A foto é o seguro. No Lab 5, o snapshot do dbt foi apagado e refeito dia a dia, com as fotos dos dias 20, 21 e 22. Deu as mesmas 7 linhas.

> Verificação: nível 3. `docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'`, repetido para os dias 21 e 22. dbt-core 1.12.6, dbt-postgres 1.11.0, Postgres 16.15, executado em 2026-11-03. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

**A última foto de cada produto**

`silver.produtos` usa a última foto de cada produto, não a última foto geral. O motivo: produto que sai da última foto não pode perder as versões na dimensão. A Microsoft recomenda não sincronizar exclusão com a dimensão, salvo membro criado por engano e sem fato relacionada.

Nos dados do laboratório, os 5 produtos estão nas 3 fotos, e essa regra não muda nenhum número. O efeito só aparece numa simulação: uma consulta só de leitura tira o produto 50 de uma foto do dia 23. Pela última foto geral, a dimensão ficaria com 6 versões. Por produto, um join de conferência com a mesma regra dá 7, igual à vigência.

> Verificação: nível 3. `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/41_produto_fora_da_ultima_foto.sql`. Postgres 16.15, executado em 2026-11-03. Saída em `lab/saidas/produto_fora_da_ultima_foto.txt`.

### 11.5 A versão da data certa: intervalo meio aberto

"Tenho as versões. Como pego a do dia da venda sem duplicar?"

**O equívoco comum**

Escrever com `BETWEEN`. Ele usa intervalo fechado: inclui as duas pontas. Na vigência, o fim de uma versão é o início da seguinte. O dia da troca cai nas duas.

```sql
SELECT i.pedido_id, i.item_seq, o.dia_local, count(*) AS versoes_casadas, sum(i.valor_item) AS valor_somado
FROM silver.itens i JOIN silver.pedidos o USING (pedido_id)
JOIN silver.produtos_vigencia v
  ON v.produto_id = i.produto_id
 AND o.dia_local BETWEEN v.valido_de AND COALESCE(v.valido_ate, DATE '9999-12-31')
GROUP BY 1, 2, 3 HAVING count(*) > 1 ORDER BY 1, 2;
```

```text
 pedido_id | item_seq | dia_local  | versoes_casadas | valor_somado
-----------+----------+------------+-----------------+--------------
       108 |        2 | 2026-10-22 |               2 |       160.00
(1 row)
```

O item vale 80,00: 4 cadernos a 20,00. O `BETWEEN` soma 160,00. É o fan-out do capítulo 10 com outra roupa, e também sem erro de sintaxe.

Com timestamp, piora: o evento da meia-noite conta em dois dias. Numa prova curta, 3 eventos sintéticos viraram 2 + 2 com `BETWEEN` e 1 + 2 com `>=` e `<`. A wiki do projeto Postgres tem uma seção só para isso: "Don't use BETWEEN (especially with timestamps)".

**Como funciona na prática**

Intervalo meio aberto (half-open) vale do início, inclusive, até o fim, exclusive: `>=` e `<`. Trecho da fato do laboratório:

```sql
LEFT JOIN gold.dim_produto dp
       ON dp.produto_id = i.produto_id
      AND o.dia_local >= dp.valido_de
      AND (dp.valido_ate IS NULL OR o.dia_local < dp.valido_ate);
```

No dia 22, a versão que termina em 22 não casa, e a que começa em 22 casa. Com `valido_ate` nulo, a versão aberta segue valendo.

No estado do Lab 4, as formas se comparam assim, sobre os 13 itens reais:

| Forma | Linhas | Receita paga | Leitura |
|---|---|---|---|
| `>=` e `<`, com fim nulo | 13 | 836,10 | A do laboratório, igual ao Lab 3 |
| `BETWEEN` com fim em 9999-12-31 | 14 | 916,10 | Dobra a venda do dia da troca: 80,00 a mais |
| `BETWEEN` com fim menos 1 dia, sobre `date` | 13 | 836,10 | Funciona, enquanto a coluna for `date` |
| `BETWEEN` com fim menos 1 dia, sobre `timestamp` | 12 | 836,10 | Perde o item 1 do pedido 107. Está pendente, e a receita paga não denuncia |
| `daterange` com `'[)'` | 13 | 836,10 | O mesmo intervalo, como tipo do Postgres |

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -X -v ON_ERROR_STOP=1 -q -f /sql/72_ligacao_com_a_versao.sql`, com o estado do Lab 4. A tabela e a contagem dos 3 eventos saem de `lab/saidas/lab9_ligacao_com_a_versao.txt`.

**Como inspecionar**

Rode o seu join de vigência com `GROUP BY` na chave do item e `HAVING count(*) > 1`, como na consulta acima. Zero linhas: cada venda achou uma versão só. O capítulo 13 transforma esse tipo de consulta em teste de dado.

**O que a vigência não sabe**

Venda anterior à primeira foto fica sem preço de tabela:

```text
 produto_id |    dia     | preco_tabela
------------+------------+--------------
         10 | 2026-10-19 |
(1 row)
```

O preço daquele dia não existe em lugar nenhum. O capítulo 12 decide o que fazer com essa venda.

> Verificação: nível 3. Consultas do pedido 108 e da venda anterior à primeira foto: `docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql`. Trecho da fato: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/30_gold.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Saída em `lab/saidas/lab4_preco_update_e_scd2.txt`.

### 11.6 O que a foto não vê

"Com foto todo dia, estou coberto?" Quase. Sobram três limites.

- **O que mudou e voltou.** Preço trocado e desfeito entre duas fotos nunca existiu para elas.
- **O instante da troca.** `valido_de` é o dia da foto, não o momento em que o preço mudou.
- **A foto que falhou.** A apostila de Orquestração, na seção 10.3, deixou a lição: o dia em que a foto falha não volta. Por isso ela é forte candidata a primeiro passo agendado, com nova tentativa e alerta.

Se algum desses limites dói no seu negócio, volte à pergunta 4 da árvore.

### 11.7 Três sentidos de "snapshot"

"Alguém do time sugeriu usar snapshot. De qual deles está falando?" A palavra engana, porque muda de sentido conforme quem fala.

| Onde | O que significa |
|---|---|
| Kimball | Fato periódica: resume eventos de um período, e o grão é o período |
| dbt | Implementa SCD tipo 2 |
| CDC, no Debezium | Por padrão (modo `initial`, configurável), cópia consistente das tabelas na primeira conexão |

Por isso esta apostila diz "foto" para a cópia crua do dia. Pergunte qual dos três a pessoa quer antes de discutir.

Sobre o dbt, uma frase por enquanto: o snapshot registra mudança só quando roda, precisa de agenda, não se reconstrói, e por isso a documentação sugere schema separado e pede chave realmente única. O capítulo 15 mostra como ele fica no projeto.

As versões estão guardadas, e a consulta acha a da data certa. Falta a fato apontar para ela por uma chave que sobreviva a uma reconstrução da dimensão. Esse é o capítulo 12.

---

[Índice](../README.md#capítulos) · [Anterior: 10. Fan-out: quando o JOIN dobra o número](10-fan-out.md) · [Próximo: 12. Chave substituta e a venda na versão certa](12-chave-substituta-e-a-venda-na-versao-certa.md)
