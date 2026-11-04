---
title: "3. O que é modelar e transformar, e o que não é"
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

[Índice](../README.md#capítulos) · [Anterior: 2. Contexto de negócio](02-contexto-de-negocio.md) · [Próximo: 4. Camadas: onde cada regra mora](04-camadas.md)

## 3. O que é modelar e transformar, e o que não é

"Trato o dado em Python ou em SQL?" A pergunta aparece cedo, na primeira arquitetura. O critério
da mentoria é este: em SQL, no banco. O Python só manda rodar.

Esta apostila trata desse SQL, o código que o orquestrador da apostila de Orquestração manda rodar,
do dado cru até a gold. Antes dele vem a frase guia: **antes do SQL, decida o que uma linha
significa.**

Vamos separar a decisão da escrita e ver o que fica de fora.

### 3.1 Por que modelar: o banco do sistema foi desenhado para gravar

"O dado já está no banco do sistema. Por que não tiro o relatório direto dele?"

**O que é**

O sistema grava num banco transacional (OLTP, online transaction processing). Esse banco é muito
normalizado, para gravar transações com eficiência. O custo aparece na leitura. Análise e relatório
em cima dele pedem consultas complexas, cheias de junções (JOIN), pesadas em agregados e difíceis
para quem é do negócio.

A Microsoft diz que esse banco nem sempre é o ideal para análise ("aren't always ideal"), admite
exceção com esquema bem planejado e sugere levar o histórico para um data mart ou um armazém de
dados (data warehouse).

Critério da mentoria: é essa distância entre gravar e analisar que justifica modelar.

**Como funciona na prática**

Na rede de lojas, a receita paga por categoria passa por três tabelas. O status está no pedido. A
quantidade e o preço estão no item. A categoria está no produto. Sem modelagem, cada relatório
refaz esse caminho.

> Verificação: nível 3, em 2026-11-04, com `postgres:16.15-alpine`. Tabela e tipo de cada coluna em
> `lab/saidas/lab9_fatos_da_carga.txt`, com `lab/sql/78_fatos_da_carga.sql`.

**O equívoco comum**

"Tenho réplica de leitura, então está resolvido." Se a sua réplica copia o banco como ele é, ela
herda o mesmo desenho (inferência). A réplica muda onde você lê. Não muda o que uma linha significa.

### 3.2 ELT: a transformação acontece no destino

"Por que não escrevo um script em Python que lê, trata e grava de volta?"

**O que é**

ELT é extrair, carregar e transformar (extract, load, transform). Ele difere do ETL só no lugar da
transformação: no ELT, ela acontece no destino, com o processamento dele.

No dbt, nossa ferramenta de exemplo, um modelo é principalmente um `select` salvo num arquivo
`.sql`. Rodar o modelo transforma o dado sem que ele saia do armazém. É o "T" do ELT.

**Como funciona na prática**

Este é o tratamento do pedido na silver, a camada do dado limpo e validado:

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

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com Postgres 16.15 (imagem
> `postgres:16.15-alpine`). Comando:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`.
> Trecho de `lab/sql/20_silver.sql`, sem edição; saída em `lab/saidas/lab1_silver_a_mao.txt`.

Nulo, texto, status, data: tudo em SQL, dentro do banco. Os capítulos 6 a 8 abrem cada tratamento,
e o 17 traz a versão em T-SQL.

O Python entra para mandar rodar. No Lab 7, a Dag, o grafo de tarefas do fluxo, tem uma tarefa só,
`dbt_build`, que chama o `dbt build`. Nenhuma linha dela trata dado.

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com Airflow 3.3.2 (imagem
> `apache/airflow:3.3.2-python3.13`), `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, contra Postgres
> 16.15. Comando: `docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db
> migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"`. Tarefa
> `dbt_build` em `success` na primeira execução da captura `lab/saidas/lab7_orquestrador_roda_dbt.txt`.
> Arquivo da Dag: `lab/orquestrador/dags/dbt_rede_de_lojas.py`.

E o SQL à mão vale o trabalho. A dbt Labs mostra que um `INSERT ... SELECT` vira modelo tirando o
`SELECT` da procedure, a rotina salva no banco, para o arquivo do modelo. Compare o trecho acima
com `lab/projeto_dbt/models/silver/stg_pedidos.sql`: o `SELECT` é o mesmo, com a origem escrita do
jeito do dbt. Leitura da mentoria: o SQL escrito à mão não se perde. O que muda é o modo de
pensar. A própria dbt Labs reconhece que migrar procedures é uma mudança grande de paradigma, do
procedural para o declarativo.

> Verificação: nível 3, em 2026-11-04. O `SELECT` foi conferido por `lab/checagens/comparar_select_pedidos.py`
> (74 elementos de cada lado, iguais, saída em `lab/saidas/lab9_fatos_da_carga.txt`) e pelo `EXCEPT` 0 e 0 do
> Lab 5, em `lab/saidas/lab5_projeto_dbt.txt`.

**A ressalva**

Tratar no banco é escolha de ELT, não lei. A Microsoft lista quando ETL ainda é a escolha. Um dos
casos é tirar transformação pesada de um destino com recurso limitado.

Python também não é proibido. O dbt tem modelo em Python, mas ele não roda na máquina do dbt: todo
o código é executado na plataforma de dados. Só plataformas específicas suportam. No dbt v2, são
Snowflake, BigQuery e Databricks; Postgres e SQL Server não aparecem nessa lista (leitura da
mentoria).

Critério da mentoria: comece em SQL, no banco. Saia dele quando puder apontar o motivo.

### 3.3 Modelar é decidir, transformar é escrever

"Se o SQL já trata o dado, onde entra a modelagem?"

**O que é**

Critério da mentoria: modelar é decidir o que cada tabela representa. Transformar é escrever o SQL
que entrega essa decisão. Cuidado com a palavra: no dbt, "modelo" é o arquivo com o `SELECT`. Aqui,
modelar é o que vem antes do arquivo.

A decisão central tem nome: grão (grain), o que uma linha da tabela significa. O Kimball coloca a
declaração do grão no centro do desenho dimensional. Ela diz exatamente o que uma linha da fato
representa. E vem antes de escolher dimensões e fatos, porque todo candidato tem de ser coerente
com ela.

**Como funciona na prática**

Volte ao trecho da seção 3.2. `PARTITION BY id` com `WHERE ordem = 1` parece detalhe de SQL. É
consequência de uma decisão: na silver, uma linha por pedido. A bronze, camada do dado cru, guarda
11 linhas de pedido, porque o pedido 103 chegou em duas cargas. A silver fica com 10. Isso não
muda o que a linha significa: tira a cópia que a carga repetida trouxe, e devolve uma linha por
pedido. O capítulo 4 volta a esse ponto. Levar o grão até a silver é critério da mentoria, e o 5.4
explica por quê.

| Aspecto | Modelar | Transformar |
|---|---|---|
| Pergunta | O que uma linha significa? | Como chego nessa linha? |
| Resultado | Uma frase escrita | Um `SELECT` que roda |
| Na silver | Uma linha por pedido | `row_number()` e `WHERE ordem = 1` |
| Na fato de vendas | Uma linha por item de pedido, não por pedido | O SQL do capítulo 9 |

**O equívoco comum**

Escrever o SQL primeiro e descobrir o grão quando o número não bate. O SQL roda sem erro e o número
sai errado. O capítulo 10 mostra um JOIN que quase dobra a receita assim, e o 5 ensina a escrever
o grão antes.

### 3.4 Os vizinhos que não são modelagem

"Apareceram Airflow, CDC, Power BI, camada semântica e teste de qualidade na mesma conversa. É tudo
a mesma coisa?"

**O que é**

Não. Cada vizinho cuida de outra parte. A divisão abaixo é critério da mentoria.

| Vizinho | Em uma frase |
|---|---|
| Orquestração | Roda o código na ordem certa e guarda o estado. |
| Ingestão e captura de mudanças (CDC, change data capture) | Trazem o dado da origem; a transformação começa depois que ele chegou. |
| BI e camada semântica | Servem a métrica a quem pergunta. |
| Qualidade e governança | Conceito próprio, para depois; aqui ficam só os testes de dado básicos do capítulo 13. |

**Como funciona na prática**

A fronteira mais difícil de ver é a da camada semântica. A terminologia do dbt ajuda. Mart é tabela
relativamente normalizada (relatively normalized), fonte da verdade de um conceito. O guia de marts
do dbt recomenda tabela larga e desnormalizada, e abre exceção quando há camada semântica: aí o mart
fica o mais normalizado possível. One big table
(uma tabela só, grande) é uso de mercado e, nessa terminologia, o sistema mais desnormalizado: todas
as colunas de interesse de um conceito numa tabela só, para o analista só precisar de um `select`. A
camada semântica aparece como motor de desnormalização (denormalization engine).

Critério da mentoria: a tabela que sai da gold é modelagem. A métrica servida por cima dela é
vizinha. E a definição do número, que o capítulo 18 ensina a registrar, não calcula nada: o registro
descreve, a camada semântica calcula.

**O equívoco comum**

Achar que adotar o dbt é modelar. O dbt roda o `SELECT` que você escreveu. Ele não decide o que uma
linha significa. Por isso, começar com SQL à mão é caminho válido: a decisão é a mesma, com ou sem
ferramenta (critério da mentoria).

### 3.5 Dois modelos mentais para guardar

"Como eu lembro disso sem decorar termo?"

Os dois são critério da mentoria. Ajudam a lembrar, não definem nada.

**Medalhão como cozinha.** A arquitetura medalhão organiza o dado em camadas de qualidade crescente.
Bronze é o ingrediente como chegou do fornecedor. Silver é a bancada: lavado, cortado, conferido.
Gold é o prato, pronto para servir ao negócio. A analogia falha num ponto: a cozinha gasta o
ingrediente, e a bronze fica guardada, para você poder refazer o resto.

**Fato e dimensão como verbo e substantivo.** Em "a loja vendeu duas camisetas no dia 20", o verbo é o
fato: um evento de negócio, medido. O número é a medida. Os substantivos, loja, produto e data, são
as dimensões: o contexto que você usa para filtrar e agrupar.

Se a silver é a bancada e a gold é o prato, cada regra precisa de um lugar. O capítulo 4 decide onde
cada uma mora.

---

[Índice](../README.md#capítulos) · [Anterior: 2. Contexto de negócio](02-contexto-de-negocio.md) · [Próximo: 4. Camadas: onde cada regra mora](04-camadas.md)
