---
title: "21. Exercícios, entregáveis e mini-desafio"
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

[Índice](../README.md#capítulos) · [Anterior: 20. Laboratório](20-laboratorio.md) · [Próximo: 22. Rubrica de validação da aprendizagem](22-rubrica-de-validacao-da-aprendizagem.md)

## 21. Exercícios, entregáveis e mini-desafio

"Li tudo e rodei o laboratório. Como sei que consigo fazer sozinho?"

Fazendo, sem roteiro. São três níveis. O conceitual pede uma decisão, o cenário pede um diagnóstico e o prático pede prova na tela. O mini-desafio leva três números a uma reunião, e você descobre qual está certo e por que os outros erram.

Cada exercício traz objetivo, contexto, entregável e critério de correção. O critério diz o que o mentor confere, não a resposta. O gabarito comentado existe, foi executado no mesmo laboratório e fica com o mentor: ele abre na call, depois de ver o seu entregável. Tente sem ele. Leve o entregável: o mentor vai pedir para ver, não para ouvir.

Tudo roda no laboratório do capítulo 20, com o estado dos Labs 1 a 4. O Exercício 6 e o mini-desafio têm uma parte opcional em dbt, que pede o Lab 5. Os arquivos de entrada novos estão em `lab/sql/`, do `60` ao `63`.

### 21.1 Nível conceitual

"Antes de abrir o editor, sei decidir?"

**Exercício 1: Qual é o grão?**

Objetivo: escrever o que uma linha significa e provar a frase com uma consulta.

Contexto: oito tabelas do laboratório, depois do Lab 4: `bronze.pedidos`, `silver.pedidos`, `bronze.pagamentos`, `bronze.produtos_foto`, `silver.produtos_vigencia`, `gold.fct_vendas`, `gold.dim_produto` e `gold.vendas_por_dia`.

Entregável:

1. Para cada tabela, a frase "uma linha é..." e a chave que essa frase promete.
2. Para cada chave, a consulta `GROUP BY chave HAVING count(*) > 1`, com o resultado.
3. Para toda tabela em que a chave mais óbvia repete, a explicação de por que ela repete sem que o dado esteja errado.

Critério de correção:

- A frase vem antes da consulta. Quem roda a consulta primeiro e escreve a frase para caber no resultado inverteu o caminho.
- A chave é a menor que torna a frase verdadeira, e a consulta volta vazia para ela.
- Quando a chave natural repete, a resposta diz o que mais entra na chave e o que a repetição significa no negócio.
- Grãos diferentes não aparecem misturados numa mesma fato. O capítulo 5 explica por quê.

**Exercício 2: Silver ou gold?**

Objetivo: aplicar o critério da mentoria do capítulo 4 a regras que você ainda não viu classificadas.

Contexto: oito regras. Algumas são da tabela nova do Exercício 10.

1. Converter para hora local a data de registro de cada devolução, gravada em UTC.
2. Ficar com a última carga de cada devolução que chegou duas vezes.
3. Traduzir o motivo da devolução para uma lista fechada, com um valor para o que ninguém mapeou.
4. Somar o valor devolvido por dia.
5. Pôr, na linha de cada venda, o preço de tabela que valia no dia.
6. Trocar por zero o custo que veio nulo.
7. Mostrar o fornecedor ao lado de cada venda, para um relatório de compras.
8. Montar o período de cada preço a partir das fotos diárias.

Entregável: uma tabela com a regra, a camada e a resposta às duas perguntas do capítulo 4. A regra resume várias linhas num número de negócio? Ela traz para a linha outro assunto do negócio? Para cada regra que você acha que não deveria existir do jeito que está escrita, diga por quê.

Critério de correção:

- Cada regra tem um lugar só, e a resposta chega a ele pelas duas perguntas, não pela intuição.
- Se uma regra muda o grão e mesmo assim fica na silver, a resposta diz por que fica.
- Pelo menos uma regra pede mais do que uma camada: um cuidado de modelagem antes do JOIN, ou um teste. A resposta aponta qual.
- A resposta diz o que fazer com a regra que esconde falha de origem, em vez de só escolher a camada dela.

**Exercício 3: Qual degrau?**

Objetivo: escolher o degrau pelo sinal, não pela ferramenta.

Contexto: a escada do capítulo 19, do degrau 0 (planilha e Power Query) ao 4 (plataforma paga). Cinco situações:

1. Você está descobrindo, sozinho, de onde vem o número de faturamento do ERP.
2. Dois painéis mostram receita paga diferente para o mesmo mês. Cada um tem a regra no próprio Power Query.
3. Um script SQL guardado no Git roda toda noite. A segunda pessoa do time vai começar a rodá-lo, e a diretoria recebe o número toda segunda.
4. Há views encadeadas no banco. A ordem de execução vive num documento, e ninguém responde o que quebra se uma coluna mudar.
5. O diretor pede o preço de ontem de um produto, e a origem sobrescreve o preço toda noite.

Entregável: uma tabela com a situação, o degrau em que ela está, o degrau que você indicaria e o sinal que decidiu. Em uma linha, diga o que faria você não subir.

Critério de correção:

- O sinal citado está na situação descrita, não no nome de uma ferramenta.
- Ficar no mesmo degrau é resposta aceita, quando o sinal não apareceu.
- Pelo menos uma situação pede uma mudança de modelagem antes de qualquer troca de degrau. A resposta diz qual e que mudança.

### 21.2 Nível cenário

"Deu número errado e ninguém viu erro. Por onde começo?"

Os seis cenários aconteceram no laboratório, com dados sintéticos. A pergunta é sempre a mesma: o que o SQL fez, e o que ninguém testou.

**Exercício 4: O número subiu, e o conserto do colega**

Objetivo: reconhecer o fan-out entre dois lados "muitos" do mesmo pedido e recusar o `DISTINCT` como conserto.

Contexto: para mostrar a forma de pagamento ao lado da receita, um colega juntou a fato de vendas aos pagamentos. O total saiu acima dos 836,10 da gold. Ele trocou a soma por `SUM(DISTINCT)`, e o total caiu para 716,10. A consulta dele é a do Lab 3:

```sql
SELECT sum(f.valor_item) AS receita_com_join,
       sum(DISTINCT f.valor_item) AS receita_com_sum_distinct
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg USING (pedido_id)
WHERE f.status = 'pago';
```

> Verificação: nível 3. `docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Trecho de `lab/sql/31_fan_out.sql`. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

Entregável:

1. Por que o total subiu, com a consulta que mostra quantas linhas cada pedido ganhou no JOIN.
2. Que venda legítima o `SUM(DISTINCT)` descartou, com a consulta que prova.
3. A consulta certa, que devolve a receita e o valor pago lado a lado, e as duas somas.
4. Um teste que volta vazio na consulta certa e com linhas na do colega.

Critério de correção:

- A causa é dita em termos de grão: itens e pagamentos são dois lados "muitos" do mesmo pedido.
- A venda descartada aparece por chave, com pedido e item, não por palpite.
- A consulta certa não multiplica linha nenhuma, e as duas somas batem com a gold.
- O teste aparece com o resultado nas duas consultas. Nenhuma parte da resposta usa `DISTINCT` para fechar o número.
- Excelente: a resposta liga o caso à recomendação do Kimball de não juntar duas fatos pelas chaves, e sim responder cada lado numa passada separada e juntar pelos atributos comuns.

**Exercício 5: O atendimento depois do fechamento**

Objetivo: provar o sentido da conversão de fuso e escrever o teste que pega o erro.

Contexto: o painel de atendimentos mostra um atendimento à 00h25 numa loja que fecha às 22h. O sistema de atendimento grava UTC numa coluna sem fuso, `bronze.atendimentos.criado_em_utc`. O horário de fechamento de cada loja está em `silver.lojas.fecha_as`. Alguém propõe um teste: "nenhum atendimento depois do horário de fechamento", comparando a hora do atendimento com `fecha_as`.

Entregável:

1. A explicação do 00h25, em duas frases.
2. A conversão certa, escrita num lugar só.
3. A contagem de atendimentos por dia, lida como está e convertida.
4. O teste proposto, rodado sobre a hora lida como está e sobre a hora convertida, com o resultado dos dois.
5. Se o teste proposto não pegar o erro, um teste que pegue, com toda suposição que ele faz escrita ao lado.

Critério de correção:

- A conversão declara a origem em UTC antes de levar para `America/Sao_Paulo`, e acontece uma vez só.
- A resposta diz quantas horas separam a leitura errada da certa e em que sentido.
- O teste final volta com linhas na leitura errada e vazio na certa.
- Toda informação que não está no dado aparece escrita como suposição, com quem pode confirmá-la.

**Exercício 6: Um valor novo de status**

Objetivo: decidir o que fazer com o valor que ninguém mapeou.

Contexto: a silver de pedidos traduz o status assim, no Lab 1:

```sql
       lower(trim(status)) AS status_origem,
       CASE lower(trim(status))
           WHEN 'pago' THEN 'pago'
           WHEN 'cancelado' THEN 'cancelado'
           WHEN 'pendente' THEN 'pendente'
           ELSE 'desconhecido'
       END AS status,
```

> Verificação: nível 3. `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Trecho de `lab/sql/20_silver.sql`. Saída em `lab/saidas/lab1_silver_a_mao.txt`.

Na semana que vem, a origem começa a mandar `estornado`. No projeto dbt, o teste `assert_status_desconhecido` já avisa uma linha em todo `dbt build`.

> Verificação: nível 3, em 2026-11-03, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`: `docker compose --profile dbt run --rm dbt dbt build`, com `WARN 1 assert_status_desconhecido` e `WARN=2` no resumo. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

Entregável:

1. O que acontece com `estornado` com esse `CASE`, e o que aconteceria sem o `ELSE`, com a consulta que mostra os dois.
2. O pedido que hoje cai em `desconhecido` e o valor que veio da origem.
3. A decisão: o teste para a carga ou só avisa? E quem decide para onde vai `estornado`?
4. O que muda na receita paga em cada escolha.

Critério de correção:

- A resposta não apaga o `ELSE` nem traduz `estornado` por conta própria para outro valor.
- O pedido em `desconhecido` aparece com o valor de origem ao lado.
- A decisão de parar ou avisar usa a pergunta do capítulo 13: publicar com essa linha deixa o número errado para quem decide?
- O aviso tem dono, com nome do papel e quando ele olha.
- Opcional, com o Lab 5: a resposta mostra o mesmo valor novo no modelo `stg_pedidos` e o teste que pega.

**Exercício 7: O preço de ontem**

Objetivo: responder a pergunta de histórico pela vigência, não pela origem.

Contexto: o diretor pergunta por quanto estava o caderno no dia 20. A origem, hoje, mostra 20,00. Depois dos Labs 1 e 4, a silver tem `silver.produtos_vigencia`, montada a partir das fotos diárias da bronze.

Entregável:

1. A consulta que devolve o preço de tabela do caderno no dia 20, com o filtro de vigência que você escolheu.
2. A mesma consulta para o dia 22, o dia da troca, e a prova de que ela devolve uma versão só.
3. A resposta para o dia 19, e por quê.
4. Em uma frase, por que a origem não responde essa pergunta.

Critério de correção:

- O filtro devolve uma versão só em qualquer dia, inclusive no dia da troca, e trata a versão sem fim.
- A resposta do dia 22 mostra a contagem de versões casadas, não só o preço.
- A resposta do dia 19 sai da consulta, não de suposição, e explica o resultado.
- A origem aparece como fonte do preço de hoje, nunca do de ontem.

**Exercício 8: O script que saiu com 0**

Objetivo: fazer a falha aparecer e proteger a carga anterior.

Contexto: a recarga noturna apaga a tabela e insere a carga nova. A carga de ontem deixou uma linha, de id 0. Hoje, o segundo `INSERT` manda texto onde vai número. O arquivo `lab/sql/62_exercicio_recarga_que_falha.sql`:

```sql
-- Exercise input: a reload that breaks in the middle, the second insert sends text where a number belongs.
DELETE FROM silver.recarga_exemplo;
INSERT INTO silver.recarga_exemplo VALUES (1, 10.00);
INSERT INTO silver.recarga_exemplo VALUES (2, 'dez');
INSERT INTO silver.recarga_exemplo VALUES (3, 30.00);
```

O `61` prepara a carga de ontem. Rode-o antes de cada tentativa:

```bash
docker compose exec -T postgres psql -U dw -d dw -q -v ON_ERROR_STOP=1 -f /sql/61_exercicio_recarga_preparar.sql
```

O `63` mostra que ids a tabela guarda. Logo depois do `61`, só o da carga de ontem:

```bash
docker compose exec -T postgres psql -U dw -d dw -At -f /sql/63_exercicio_recarga_estado.sql
```

```text
0
[exit 0, 2026-11-04]
```

Do jeito padrão, sem opção nenhuma:

```bash
docker compose exec -T postgres psql -U dw -d dw -f /sql/62_exercicio_recarga_que_falha.sql
```

```text
DELETE 1
INSERT 0 1
psql:/sql/62_exercicio_recarga_que_falha.sql:4: ERROR:  invalid input syntax for type numeric: "dez"
LINE 1: INSERT INTO silver.recarga_exemplo VALUES (2, 'dez');
                                                      ^
INSERT 0 1
[exit 0, 2026-11-04]
```

E o `63`, depois:

```text
1,3
[exit 0, 2026-11-04]
```

> Verificação: nível 3. `postgres:16.15-alpine`, com `psql` 16.15, executado em 2026-11-04, em Linux. Saída em `lab/saidas/exercicios_enunciados.txt`, que roda o `60` do Exercício 10 e depois o `61`, o `63`, o `62` e o `63` de novo, nessa ordem.

Entregável:

1. O que a tabela guarda depois, e o que sumiu.
2. O comando que sai com código diferente de zero e deixa a carga de ontem intacta, provado pelo `63`.
3. Uma tabela com cada combinação de opções que você testou, o código de saída e o que ficou na tabela.
4. Em duas frases, por que o código de saída importa quando quem roda o script é um orquestrador.
5. Opcional, se o seu banco é SQL Server: por que `SET XACT_ABORT ON` com `sqlcmd -b` não é o mesmo par, com o caso do capítulo 17 em que a carga parcial fica.

Critério de correção:

- Cada linha da tabela vem de uma rodada capturada, depois do `61`, e não da lembrança do capítulo 19.
- A resposta separa duas coisas: o erro aparecer e o estado ficar protegido. Uma opção dá a primeira, outra dá a segunda.
- A frase sobre o orquestrador diz o que ele faz com a tarefa quando o código de saída não é zero.

**Exercício 9: Dois relatórios, três números**

Objetivo: achar onde a regra diverge, dar nome a cada número e registrar qual vale.

Contexto: o relatório A soma a receita paga com `status = 'pago'`. O relatório B soma com `lower(trim(status)) = 'pago'`. Os dois leem `replica.pedidos`, nos mesmos dias. Na mesma reunião, aparecem mais três números com o mesmo nome. Sobre os dados do laboratório, três consultas chamadas "receita paga" devolveram 836,10, 840,20 e 842,20, somados os três dias.

> Verificação: nível 3, com `postgres:16.15-alpine`, em 2026-11-04, sobre a gold do laboratório. Os três números valem como resultado esperado. A consulta de cada um é parte do exercício.

Entregável:

1. Os totais de A e de B e os pedidos que explicam a diferença, com o status como veio da origem.
2. Que pergunta cada um dos três números responde, com a consulta de cada um sobre a gold e a silver.
3. O motivo da diferença entre o primeiro e o segundo, ou a frase que diz por que o dado não traz esse motivo.
4. O registro mínimo do capítulo 18 para "receita paga", com dono.

Critério de correção:

- A diferença entre A e B aparece pedido a pedido.
- A resposta não escolhe sozinha a regra que vale: diz quem arbitra e onde a regra passa a morar.
- Os três números ganham três nomes diferentes, cada um com a sua pergunta.
- Se o dado não explica uma diferença, a resposta diz isso e não inventa o motivo.
- Excelente: a resposta diz onde a regra deixa de morar. Do lado do Power BI, a Microsoft recomenda tirar a preparação do Power Query de cada arquivo e centralizá-la num dataflow, para chegar a uma fonte única da verdade. A página trata do Dataflow Gen1, legado, e indica o Gen2.

### 21.3 Nível prático

"Consigo levar uma tabela nova do cru até o número, sozinho?"

**Exercício 10: A silver das devoluções**

Objetivo: levar uma tabela nova da bronze à silver, com o grão declarado, testes e o número registrado.

Contexto: a rede de lojas passou a receber devoluções. O arquivo `lab/sql/60_exercicio_devolucoes_bronze.sql` cria `bronze.devolucoes` do jeito que a origem entregou e mostra o conteúdo:

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/60_exercicio_devolucoes_bronze.sql
```

```text
 id | pedido_id | item_seq |     motivo      | valor_devolvido | valor_texto |  registrada_em_utc  |   carregado_local   
----+-----------+----------+-----------------+-----------------+-------------+---------------------+---------------------
  1 |       101 |        1 |  DEFEITO        |           60.00 | 60,00       | 2026-10-21 14:10:00 | 2026-10-22 06:00:00
  2 |       104 |        2 | troca           |           10.90 | 10,90       | 2026-10-21 00:30:00 | 2026-10-22 06:00:00
  3 |       106 |        1 | em analise      |           33.30 | 33,30       | 2026-10-22 00:40:00 | 2026-10-22 06:00:00
  3 |       106 |        1 | Defeito         |           33.30 | 33,30       | 2026-10-22 00:40:00 | 2026-10-23 06:00:00
  4 |       108 |        2 | arrependimento  |                 |             | 2026-10-22 16:00:00 | 2026-10-23 06:00:00
  5 |       109 |        1 | Extraviado      |           60.00 | 60,00       | 2026-10-22 18:20:00 | 2026-10-23 06:00:00
(6 rows)
```

> Verificação: nível 3. O comando acima, com `postgres:16.15-alpine`, executado em 2026-11-04, em Linux. Trecho da saída em `lab/saidas/exercicios_enunciados.txt`: só a consulta final, sem o aviso do `DROP` e as linhas de `CREATE` e `INSERT`.

A coluna `registrada_em_utc` é UTC gravado numa coluna sem fuso, como nos atendimentos. A `_carregado_em`, que a consulta mostra em hora local como `carregado_local`, diz quando cada linha chegou à bronze.

Entregável, levado à call:

1. A frase do grão, escrita antes do SQL, e a chave que ela promete.
2. O SQL que cria `silver.devolucoes`, com um comentário em inglês em cada decisão que não é óbvia.
3. Pelo menos três testes que precisam voltar vazios. Um deles na chave do grão e um na ligação com `silver.itens`.
4. Dois avisos que voltam linha de propósito, cada um com o que conta, por que avisa em vez de parar e quem olha.
5. O número: valor devolvido por dia local, com o registro mínimo do capítulo 18.
6. O mesmo número calculado direto da bronze, sem os tratamentos, e a diferença explicada linha a linha.

Critério de correção:

- O grão vem antes do SQL, e a diferença de contagem entre bronze e silver está explicada.
- Fica uma linha por devolução, escolhida por uma regra escrita sobre qual carga vale. Nada de `DISTINCT`.
- O texto do motivo é padronizado, o `CASE` tem `ELSE` e o valor original continua visível numa coluna.
- O valor que não veio fica nulo, não vira zero, e um aviso conta quantos são.
- A hora é convertida de UTC uma vez, e o dia local sai da hora convertida.
- A coluna redundante sai, com o motivo escrito.
- Os testes voltam vazios, e os avisos voltam exatamente o que você previu antes de rodar.
- O registro tem os oito campos, e o campo dono está preenchido.

Esse é o entregável que a rubrica do próximo capítulo usa na call.

### 21.4 Mini-desafio: três números, uma reunião

"Três números para a mesma receita. Qual está certo, e por que os outros erram?"

**Enunciado**

Segunda de manhã. Três números chegam à reunião, todos de consultas que rodaram sem erro sobre os dados do laboratório:

1. Receita paga do dia 20: 430,90, no painel da gold.
2. Receita paga do dia 20: 850,90, numa planilha que mostra o fornecedor de cada venda.
3. Valor do item 2 do pedido 108, vendido no dia 22: 160,00, numa conferência que liga cada item ao preço de tabela vigente. O item vale 80,00.

> Verificação: nível 3. Os três números saem de `docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql` e de `docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql`. Postgres 16.15, executado em 2026-11-03, em Linux. Saídas em `lab/saidas/lab3_gold_estrela_e_fan_out.txt` e `lab/saidas/lab4_preco_update_e_scd2.txt`.

Tente sem abrir esses dois scripts. A verificação está aqui para você saber de onde os números vieram, não para servir de cola. Faça o mini-desafio antes de abrir o capítulo 23.

Entregável:

1. A causa de cada número, em uma frase.
2. A consulta que prova cada causa. Para o 430,90, a prova de que ele está certo por pelo menos dois caminhos independentes.
3. A correção de cada consulta errada, com o número que ela devolve depois.
4. Um teste, em SQL puro, que volta com linhas nas duas consultas erradas e vazio nas duas corrigidas.
5. Opcional, com o Lab 5: repita o erro do número 3 no modelo `fct_vendas` do projeto dbt e rode `dbt build`. Anote que teste parou, se algum parou, e o que aconteceu com `vendas_por_dia`. Guarde uma cópia do modelo antes de editar e volte o arquivo ao original no fim.

**Dicas**

1. Comece pelo grão. Uma linha da fato é um item de pedido. Conte quantas linhas cada consulta devolve por item.
2. Para o 430,90, some o mesmo dia por um caminho que não passe pela fato.
3. O número 3 envolve o dia em que o preço trocou. Olhe os limites do filtro de vigência.
4. Um mesmo tipo de teste pega os dois erros.

**Como o mentor confere**

- Cada causa é dita em termos de grão ou de intervalo, não de ferramenta.
- A prova do 430,90 não depende da fato.
- As correções devolvem 430,90 no dia 20 e 80,00 no item.
- O teste é um só, e você mostra o resultado dele nas quatro consultas.
- Na parte em dbt, a resposta separa o que parou do que continuou publicado, e diz se o número da gold mudou.

A solução comentada fica com o mentor. Leve o mini-desafio resolvido para a call, junto do Exercício 10.

### 21.5 Como o código deste capítulo foi verificado

- Entradas dos Exercícios 8 e 10: nível 3. Arquivos `lab/sql/60_exercicio_devolucoes_bronze.sql` a `lab/sql/63_exercicio_recarga_estado.sql`, executados em 2026-11-04, em Linux, com `postgres:16.15-alpine` e `psql` 16.15, pelos comandos citados nos exercícios. Saída em `lab/saidas/exercicios_enunciados.txt`.
- Trechos e números dos Exercícios 4 e 6 e do mini-desafio: nível 3, em 2026-11-03, com os mesmos comandos dos Labs 1, 3, 4 e 5. Saídas em `lab/saidas/lab1_silver_a_mao.txt`, `lab/saidas/lab3_gold_estrela_e_fan_out.txt`, `lab/saidas/lab4_preco_update_e_scd2.txt` e `lab/saidas/lab5_projeto_dbt.txt`.
- Números do Exercício 9: nível 3, em 2026-11-04, sobre a gold do laboratório, citados como resultado esperado.
- Gabaritos: todo exercício que pede consulta tem gabarito executado em nível 3, em 2026-11-04, num projeto Docker isolado com o mesmo laboratório, `postgres:16.15-alpine`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. Os Exercícios 2 e 3 têm gabarito em prosa. Os gabaritos ficam com o mentor.
- Nada deste capítulo rodou em Windows, em Power Query ou em SQL Server. A parte opcional de SQL Server do Exercício 8 se apoia no Lab 8, do capítulo 17.

Com o entregável na mão, falta saber como o mentor vai ler o que você trouxe. O próximo capítulo é a rubrica da call.

---

[Índice](../README.md#capítulos) · [Anterior: 20. Laboratório](20-laboratorio.md) · [Próximo: 22. Rubrica de validação da aprendizagem](22-rubrica-de-validacao-da-aprendizagem.md)
