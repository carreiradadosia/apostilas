---
title: "Apostila, Modelagem e transformação: fundamentos, do dado cru ao número da diretoria"
date: 2026-11-04
type: apostila
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - modelagem
  - apostila
  - mentoria
---

# Apostila, Modelagem e transformação: fundamentos, do dado cru ao número da diretoria

> Trilha de Engenharia de Dados. Conduzida por Iuri Zambotto.

## Sumário

- [0. Como usar esta apostila](#0-como-usar-esta-apostila)
- [1. Objetivo pedagógico](#1-objetivo-pedagógico)
- [2. Contexto de negócio](#2-contexto-de-negócio)
- [3. O que é modelar e transformar, e o que não é](#3-o-que-é-modelar-e-transformar-e-o-que-não-é)
- [4. Camadas: onde cada regra mora](#4-camadas-onde-cada-regra-mora)
- [5. Grão: o que uma linha significa](#5-grão-o-que-uma-linha-significa)
- [6. Silver: texto, coluna redundante e duplicata](#6-silver-texto-coluna-redundante-e-duplicata)
- [7. Silver: nulo com critério e CASE WHEN](#7-silver-nulo-com-critério-e-case-when)
- [8. Silver: datas e fuso horário](#8-silver-datas-e-fuso-horário)
- [9. Fato, dimensão e esquema estrela](#9-fato-dimensão-e-esquema-estrela)
- [10. Fan-out: quando o JOIN dobra o número](#10-fan-out-quando-o-join-dobra-o-número)
- [11. Histórico: o preço que o UPDATE apaga](#11-histórico-o-preço-que-o-update-apaga)
- [12. Chave substituta e a venda na versão certa](#12-chave-substituta-e-a-venda-na-versão-certa)
- [13. Testes de dado: consultas que precisam voltar vazias](#13-testes-de-dado-consultas-que-precisam-voltar-vazias)
- [14. Materialização, incremental e reprocesso](#14-materialização-incremental-e-reprocesso)
- [15. O mesmo SQL como projeto dbt](#15-o-mesmo-sql-como-projeto-dbt)
- [16. dbt hoje: geração, licença, adaptador e preço](#16-dbt-hoje-geração-licença-adaptador-e-preço)
- [17. SQL Server: a silver e a gold em T-SQL](#17-sql-server-a-silver-e-a-gold-em-t-sql)
- [18. De onde vem este número: definição e linhagem](#18-de-onde-vem-este-número-definição-e-linhagem)
- [19. Onde a regra mora: a decisão de quem gerencia](#19-onde-a-regra-mora-a-decisão-de-quem-gerencia)
- [20. Laboratório](#20-laboratório)
- [21. Exercícios, entregáveis e mini-desafio](#21-exercícios-entregáveis-e-mini-desafio)
- [22. Rubrica de validação da aprendizagem](#22-rubrica-de-validação-da-aprendizagem)
- [23. Erros comuns e como corrigir](#23-erros-comuns-e-como-corrigir)
- [24. Plano de continuidade](#24-plano-de-continuidade)
- [25. Glossário](#25-glossário)
- [Referências](#referências)
- [Fontes verificadas (2026-11-04)](#fontes-verificadas-2026-11-04)

## 0. Como usar esta apostila

### 0.1 Preciso ler tudo?

Não. Cada perfil de mentorado tem o seu caminho, e nem todo caminho passa pelo laboratório.

**Leitura linear ou revisão pontual**

Na primeira vez, leia em ordem: cada capítulo usa o vocabulário do anterior. Para revisar, vá direto
pelo sumário. Termo novo tem definição curta no glossário (25).

**Roteiro por perfil**

| Se você | Leia |
|---|---|
| quer só entender do que se trata | 3 e as aberturas do 4 e do 5 |
| gerencia e quer decidir | 2, 16, 18.1 e 19 |
| está começando na área | 1 a 15, em ordem, os Labs 0 a 6 do capítulo 20 e o exercício prático do 21 |
| já trabalha com dados e quer migrar para engenharia | 5 a 15, 17, 18, 20 e 21 |
| já é engenheiro e mira o próximo nível | 12, 14, 15, 16, 18 e 24 |

Some o que vale para o seu banco: se usa SQL Server, acrescente o 17 e o Lab 8 do capítulo 20.

Escreve SQL à mão hoje? É um bom ponto de partida, e esse é um critério da mentoria. O capítulo 19
mostra que sinal pede subir de degrau.

### 0.2 O que preciso ter antes do laboratório?

**Para ler**

SQL básico: ler e escrever um `SELECT`. O resto a apostila constrói, a partir de uma frase: antes do
SQL, decida o que uma linha significa.

**Versão de referência**

O dbt, ferramenta de transformação, só entra como exemplo. Ele aparece em trechos ao longo dos
capítulos, e o capítulo 15 monta o fluxo inteiro como projeto dbt. O laboratório fixa estas
versões, conferidas em 2026-11-03:

- `dbt-core` 1.12.6, estável, de 2026-10-14, com licença Apache-2.0.
- `dbt-postgres` 1.11.0, de 2026-07-16, o adaptador que liga o dbt ao banco. Exige `dbt-core` da
  1.8 até antes da 2.0, então Postgres com dbt hoje quer dizer dbt v1.
- PostgreSQL 16.15, na imagem `postgres:16.15-alpine`, com suporte até 2028-11-09.

Achou tutorial antigo? Confira a versão antes de copiar.

**Máquina**

O laboratório fica em `engenharia_de_dados/modelagem/dbt/lab/` no repositório clonado; os caminhos
`lab/...` desta apostila partem do módulo `modelagem/dbt/`.

Você precisa de Docker com Compose, terminal com bash e internet na primeira vez: as imagens são
baixadas, e a do dbt é construída na sua máquina. Do Lab 0 ao Lab 6 você não instala Python: o
Lab 0 constrói a imagem do dbt, e os Labs 5 e 6 rodam o dbt em contêiner. Confira:

```bash
docker --version
docker compose version
```

> Verificação: nível 3, em 2026-11-04, em Linux x86_64. Versões na máquina de teste: Docker 28.3.3
> e Compose v2.39.1. A sua será outra. Essas versões rodaram o
> laboratório; não testamos um mínimo. Saída em `lab/saidas/cap00_docker_versoes.txt`.

Quanto pesa? Medimos num Linux de 14 CPUs e 31 GB, que não representa a sua máquina. Sem Airflow,
são menos de 1 GB de imagens e centenas de MiB de memória. O Lab 7 acrescenta a imagem do Airflow
com dbt, de 2,65 GB, e um contêiner com pico entre 370 e 435 MiB. Os Labs 8 e 9 têm exigências
próprias, fora desta medição: veja o capítulo 20.

Serve em máquina comum? Nossa estimativa é que sim, e isso é inferência. Não testamos em máquina de
8 GB nem em Windows: tudo rodou em Linux.

> Verificação: nível 3, em 2026-11-03, com `docker image ls`, `docker stats` e o log de recursos do
> dbt. Saídas: `lab/saidas/recursos_medidos.txt` e `lab/saidas/lab0_subir_do_zero.txt`. As faixas
> variam por rodada; a saída guarda uma rodada do Airflow.

Com o caminho escolhido, vamos ao que você consegue fazer ao terminar e à pergunta de negócio que
puxa tudo isso.

## 1. Objetivo pedagógico

"Sei o que quero, mas travo na hora de escrever o tratamento em SQL."

Essa é, com outras palavras, a trava do gerente de TI que a apostila de Orquestração apresentou: tratar em SQL o dado sujo. Seu cenário pode ser outro. Se a trava é a mesma, este caminho serve para você.

A Orquestração deixou uma ponte: o orquestrador não é o código de limpeza, é quem roda o código. Esta apostila é a desse código, e vai além da limpeza: chega à gold, onde o dado é juntado e agregado. A frase guia dela é esta.

**Antes do SQL, decida o que uma linha significa.**

### 1.1 O que você consegue fazer ao terminar

O que eu vou conseguir fazer sozinho? Oito coisas.

- **Declarar** o grão de uma tabela, o que uma linha significa, antes de escrever o SQL.
- **Escrever** a silver com critério: nulo, `CASE`, texto, data, fuso e duplicata.
- **Montar** uma estrela: fato de vendas ligada às dimensões de loja, produto e data.
- **Guardar** o histórico que a origem apaga, como o preço trocado de noite.
- **Testar** o grão e as chaves, com consultas que precisam voltar vazias.
- **Reproduzir** em dbt o fluxo que você já rodou à mão.
- **Descobrir** de onde vem um número que aparece num relatório.
- **Decidir** onde a regra mora e quando vale subir de degrau.

### 1.2 O objetivo é aprender dbt?

Não. O dbt entra como exemplo, depois do conceito. O projeto dbt completo é montado no capítulo 15. A ferramenta muda de versão. A decisão sobre o que uma linha significa continua sendo sua.

**O equívoco comum**

Achar que a dor da modelagem é falta de ferramenta. Na pesquisa de comunidade de Joe Reis, publicada em fevereiro de 2026, com 1.101 respostas de múltipla escolha, 11% marcaram "None / modeling is going well" (nenhuma, a modelagem vai bem). As dores mais citadas foram pressão por velocidade (59%), falta de dono claro (51%) e manutenção difícil (39%). A ferramenta apareceu em 19%.

Leitura da mentoria: é sinal, não medida do mercado. As respostas vêm da própria comunidade, e o post agradece a um fornecedor de ferramenta de modelagem pela parceria.

## 2. Contexto de negócio

"Por que o mesmo número aparece diferente em dois relatórios? E como eu guardo o preço de ontem?"

A apostila inteira responde a essas duas perguntas. Vamos responder na mesma rede de lojas fictícia da Orquestração, com dados sintéticos.

### 2.1 O que a rede já tem e o que entra agora

Preciso recomeçar do zero? Não. A rede avança.

| Peça | O que a Orquestração deixou | O que esta apostila acrescenta |
|---|---|---|
| Réplica só leitura | Pedidos | Lojas, itens, produtos, fornecedores, preço e atendimentos em UTC |
| Bronze | Pedidos crus | A foto diária do preço, crua, que lá ficou fora do laboratório |
| Silver | Pedidos validados | Nulo, `CASE`, texto, data, fuso, duplicata e a vigência do preço |
| Gold | Receita por dia | Estrela com o grão escrito e uma one big table (uma tabela só, grande) por cima |
| Registro de carga | Linhas e receita de cada carga | Continua, com testes de dado ao lado |

Bronze, silver e gold formam a arquitetura medalhão: cru, validado e enriquecido. A Databricks a chama de prática recomendada, não de requisito. O capítulo 4 mostra onde cada regra mora.

**Como saber que o avanço não quebrou nada**

A estrela, com o grão escrito antes do SQL, devolve a receita que a Orquestração publicou: 430,90, 111,90 e 293,30 nos dias 20, 21 e 22. A one big table, view sobre a estrela, tem as mesmas 13 linhas e a mesma receita, 836,10. É camada de consumo, não segunda fonte de verdade.

> Verificação: nível 3. Comando `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql`, em PostgreSQL 16.15, em 2026-11-03. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

### 2.2 Posso criar a silver na réplica?

Não, e essa é a primeira decisão de arquitetura. Uma réplica Postgres em espera ativa (hot standby) não aceita escrita, nem tabela temporária. No teste da mentoria, a leitura funcionou, e `CREATE TABLE AS`, `CREATE TEMP TABLE` e `CREATE VIEW` falharam com `read-only transaction`. Logo, a silver mora num banco que aceita escrita.

O teste foi em Postgres. Não sabemos que tecnologia de réplica você tem. Pergunte ao time antes de desenhar a silver. O capítulo 4 volta a isso.

> Verificação: nível 3, em teste à parte, porque no laboratório a réplica é simulada por um papel só de leitura. Réplica criada com `pg_basebackup -D /tmp/standby -R -X stream`, em PostgreSQL 16.15, em 2026-11-03.

### 2.3 Quatro números que erram sem dar erro

Se o SQL rodou sem erro, o número está certo? Não. Vamos ver quatro casos.

| Caso | O que aparece | O que é de verdade | Capítulo |
|---|---|---|---|
| Atendimento à meia-noite | 00h25, numa loja que fecha às 22h | 21h25 do dia anterior: a origem grava UTC em coluna sem fuso | 8 |
| Preço trocado de noite | Origem mostra 20,00 para um item vendido a 20,50 dois dias antes | O `UPDATE` noturno apagou o preço anterior | 11 |
| Receita que quase dobra | 850,90 no dia 20 | 430,90: um produto com dois fornecedores faz 6 linhas virarem 9 no JOIN | 10 |
| Regra em dois lugares | 130,00 num relatório, 170,00 no outro | `status = 'pago'` de um lado, `lower(trim(status)) = 'pago'` do outro | 6 e 19 |

Para o banco, nada disso é erro. O horário é válido. O `UPDATE` fez o que foi mandado. O JOIN devolveu uma linha para cada par que casa. As duas consultas são válidas.

No laboratório, 2 de 4 atendimentos mudam de dia com a conversão. As fotos diárias do preço guardam 15 linhas, e o histórico tipo 2 de dimensão de mudança lenta (SCD, slowly changing dimension) derivado delas guarda 7 versões. Na `dim_produto`, o membro desconhecido leva a 8 linhas (capítulo 12). O JOIN que multiplica linhas tem nome de uso corrente: fan-out.

O quarto caso é o do BI por planilha. A Microsoft recomenda tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow (fluxo de dados), para chegar a uma fonte única da verdade. A página trata do Dataflow Gen1, legado, e indica o Gen2. Não achamos página do Microsoft Learn sobre regra duplicada entre Power Query e SQL. A divergência foi simulada em SQL, e nada aqui rodou no Power Query.

> Verificação: nível 3 nos três primeiros casos, com `docker compose exec -T postgres psql -U dw -d dw -f /sql/22_fuso.sql`, `/sql/40_preco_update_apaga.sql` e `/sql/31_fan_out.sql`, em PostgreSQL 16.15, em 2026-11-03. Saídas em `lab/saidas/lab2_fuso_e_datas.txt`, `lab/saidas/lab4_preco_update_e_scd2.txt` e `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. O quarto é simulação em SQL, nível 3 na mesma versão e na mesma data, fora do laboratório.

**O equívoco comum**

Achar que sem erro é o mesmo que certo. Erro de sintaxe para a carga. Estes quatro chegam à diretoria no horário.

**Se você gerencia**

Critério da mentoria: o risco maior não é a carga que para, é a carga que termina com o número errado. Pergunte ao time: "Como saberíamos que este número dobrou?". Se a resposta for "o usuário reclama", já temos por onde começar.

### 2.4 Preciso de ferramenta para começar?

Não. Começar com SQL à mão é caminho válido. É critério da mentoria, não norma de mercado.

À mão, você vê cada linha mudar e descobre de onde vem cada número. Uma ferramenta não decide o grão por você. Por isso o laboratório roda o fluxo primeiro em SQL, à mão, e depois como projeto dbt.

Os sinais para subir de degrau ficam no capítulo 19. Também são critério da mentoria: número divergente entre relatórios, regra copiada em vários lugares, uma segunda pessoa precisando rodar, entrega recorrente para a diretoria.

Antes de escrever a primeira linha, vamos separar o que é modelar e transformar do que não é. É o próximo capítulo.

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

## 4. Camadas: onde cada regra mora

"Sei escrever o `TRIM`. Mas ele vai na silver ou na gold? E o `CASE` de status?" Essa dúvida aparece na hora de abrir o editor.

A resposta curta cabe em duas linhas. Na silver mora o que conserta registro a registro sem mudar o grão, isto é, sem mudar o que uma linha significa. Na gold mora o que junta ou agrega. Isso é **critério da mentoria**, não regra de mercado.

Vamos ver de onde ele vem e aplicá-lo em seis regras da rede de lojas. No fim, voltamos à primeira decisão de arquitetura, que o capítulo 2 adiantou: a réplica não recebe a silver.

### 4.1 Preciso mesmo de três camadas?

**O que é**

A arquitetura medalhão organiza o dado em camadas que indicam qualidade: bronze (cru), silver (validado) e gold (enriquecido). A documentação da Databricks a chama de "a recommended best practice but not a requirement". Ou seja, prática recomendada, não requisito.

Usamos as três porque a rede de lojas já chegou assim da Orquestração.

| Camada | O que a documentação da Databricks diz | Na rede de lojas |
|---|---|---|
| Bronze | Ingestão crua, com validação mínima | `bronze.pedidos`, `bronze.produtos_foto` |
| Silver | Limpa e valida (nulos, duplicatas, conversão de tipo, junções). Guarda ao menos uma representação validada e não agregada de cada registro | `silver.pedidos`, `silver.itens` |
| Gold | Modelagem dimensional e agregação | `gold.fct_vendas`, `gold.vendas_por_dia` |

**O equívoco comum**

"Na bronze não há validação nenhuma." O quadro da página da Databricks diz isso, mas a seção normativa fala em "Minimal data validation". Fique com a regra: validação mínima, não zero.

### 4.2 Onde mora o `CASE WHEN` de negócio?

**O que as fontes dizem**

As fontes não concordam. Melhor saber disso antes de ouvir uma resposta categórica.

| Fonte | O que diz |
|---|---|
| Documentação da Databricks | A silver pode ter junções, e também agregados quando muitos consumidores dependem deles. É comum começar a modelar já nela. |
| Post da Databricks, de 2022 | A silver recebe transformações "just-enough" (só o suficiente). A maior parte das regras de negócio complexas entra na passagem da silver para a gold, que recebe, por exemplo, a estrela. |
| Guia de staging do dbt | A staging (camada de preparação) aceita lógica condicional de categorização e veta agregação, porque mudar o grão ali faz perder acesso ao dado de origem. Junção é "almost always a bad idea", com exceções e por outro motivo: computação duplicada e relações confusas. |

O guia do dbt nem usa a palavra medalhão. Ele descreve um arco, do dado moldado pela origem ("source-conformed") ao dado moldado pelo negócio ("business-conformed"), para aplicar cada transformação num lugar só. Nenhuma fonte oficial que consultamos diz que staging é silver.

**Critério da mentoria**

Na silver, a regra que conserta registro a registro sem mudar o grão: nulo, texto, data, fuso. Na gold, o que junta ou agrega.

Para decidir, faça duas perguntas sobre a regra:

1. Ela resume várias linhas num número de negócio, como a receita do dia?
2. Ela traz para a linha outro assunto do negócio, como loja ou produto?

Qualquer sim, gold. Dois nãos, silver. Assim, cada regra tem um lugar só, o mesmo objetivo do guia do dbt.

A ponte com o dbt também é critério da mentoria: no laboratório, os modelos `stg_` moram na silver, e os `fct_` e `dim_`, na gold.

### 4.3 Como fica em regras de verdade?

**Como funciona na prática**

São seis regras que rodam no laboratório da rede de lojas. Nada aqui pede ferramenta: são scripts SQL rodados à mão.

| Regra | Trecho do laboratório | Camada | Motivo |
|---|---|---|---|
| `TRIM` no nome | `initcap(trim(nome))` | Silver | Conserta o texto na própria linha. As 3 lojas seguem 3 linhas. |
| De-para da categoria | `COALESCE(d.categoria, lower(unaccent(trim(u.categoria))))` | Silver | Troca `papelria` por `papelaria`. Conserta o valor na própria linha, sem criar nem perder produto: o `LEFT JOIN` não multiplica. |
| `CASE` de status | `CASE lower(trim(status)) ... ELSE 'desconhecido' END` | Silver | Troca um valor por outro na mesma linha. |
| Fuso | `AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'` | Silver | Corrige a leitura da hora de cada atendimento. Os 4 seguem 4. |
| Receita por dia | `sum(valor_item) FILTER (WHERE status = 'pago')` com `GROUP BY data_id` | Gold | Agrega. O grão passa de item para dia: 13 itens viram 3 linhas. |
| Estrela | `gold.fct_vendas` com `dim_loja`, `dim_produto` e `dim_data` | Gold | Junta. O grão não muda, são 13 itens e 13 linhas, mas a linha ganha loja, produto e data. |

Esquema estrela é o modelo dimensional em banco relacional: fatos ligadas às dimensões por chave. O capítulo 9 o constrói. Você roda as quatro primeiras regras no Lab 1 e as duas últimas no Lab 3.

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Comandos:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql` e o
> mesmo com `/sql/30_gold.sql`. Trechos desses dois arquivos. Saídas em
> `lab/saidas/lab1_silver_a_mao.txt` e `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

**O equívoco comum**

"Tem `LEFT JOIN` no de-para, então o critério furou." Não furou. A tabela `silver.de_para_categoria` guarda só correções, com chave primária em `categoria_origem`. Cada categoria acha no máximo uma correção, e nenhum produto vira dois. Ela não traz assunto novo: conserta o valor da própria linha. `TRIM`, caixa e acento não corrigem erro de digitação; isso pede um de-para que alguém mantém.

**Onde o critério pede explicação**

Três regras da silver mudam a contagem de linhas que vem da bronze. Melhor dizer às claras.

- **Duplicata.** `bronze.pedidos` tem 11 linhas e `silver.pedidos`, 10, porque o pedido 103 veio em duas cargas. A silver não muda o que a linha significa: devolve "uma linha por pedido". O capítulo 6 mostra como.
- **Última foto.** Com as três fotos, `bronze.produtos_foto` tem 15 linhas e `silver.produtos`, 5, porque a silver lê a última foto de cada produto.
- **Vigência do preço.** A foto tem uma linha por produto e dia. `silver.produtos_vigencia` tem uma por produto e período de preço. Aqui o grão muda, sim, e a regra fica na silver mesmo assim. Critério da mentoria: ela fala de um assunto só, não soma número de negócio e entrega à gold o preço de cada período. O capítulo 11 mostra como.

### 4.4 Por que guardar a foto crua na bronze?

"O sistema sobrescreve o preço toda noite. Se depois eu vou limpar, por que guardar a foto crua?"

**O que é**

Foto é a cópia agendada do estado de uma tabela num dia. Nenhuma fonte diz em que camada ela mora. Critério da mentoria: fica crua na bronze, e a silver monta a vigência.

```sql
-- Daily photo of the product table, raw. Run with: psql -v dia=2026-10-20 -f ...
DELETE FROM bronze.produtos_foto WHERE _dia_referencia = :'dia'::date;
INSERT INTO bronze.produtos_foto SELECT *, :'dia'::date FROM replica.produtos;
SELECT _dia_referencia, count(*) AS linhas FROM bronze.produtos_foto GROUP BY 1 ORDER BY 1;
```

> Verificação: nível 3. Executado em 2026-11-03, com `postgres:16.15-alpine`. Comando:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-20 -f /sql/11_bronze_foto_precos.sql`,
> com `DELETE 0` e `INSERT 0 5`. Saída em `lab/saidas/lab1_silver_a_mao.txt`.

**Por que crua**

O motivo é poder refazer. O histórico que o dbt monta, chamado snapshot (capítulo 11), não se reconstrói sozinho. A documentação avisa: "Snapshots ignore both the full_refresh config and the --full-refresh flag".

No laboratório, apagamos esse histórico e o refizemos dia a dia, a partir das fotos dos dias 20, 21 e 22. Voltaram as mesmas 7 linhas.

> Verificação: nível 3. Executado em 2026-11-03, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e
> `postgres:16.15-alpine`. Comando: `docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'`,
> repetido para os dias 21 e 22. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

### 4.5 Posso criar a silver na réplica?

"Já tenho uma réplica. Não dá para criar a silver nela e poupar outro banco?" É a primeira decisão de arquitetura, que o capítulo 2 adiantou. Aqui vai a prova.

**Como inspecionar, no Postgres**

Não dá. A documentação do Postgres diz que, em espera ativa (hot standby), "not even temporary tables may be written". Testamos numa réplica descartável. A leitura funcionou. A escrita falhou, inclusive a view.

```text
### SELECT pg_is_in_recovery()
t
### SELECT count(*) FROM produto
1
### CREATE TABLE silver_produto AS SELECT * FROM produto
ERROR:  cannot execute CREATE TABLE AS in a read-only transaction
### CREATE TEMP TABLE tmp_produto (id int)
ERROR:  cannot execute CREATE TABLE in a read-only transaction
### CREATE VIEW vw_produto AS SELECT * FROM produto
ERROR:  cannot execute CREATE VIEW in a read-only transaction
```

> Verificação: nível 3. Executado em 2026-11-03, em `postgres:16.15-alpine`, com a réplica criada por
> `pg_basebackup -R` e cada comando rodado por `psql`. Teste à parte do laboratório da rede de lojas;
> script e saída não publicados.

Há um segundo motivo. Consulta longa nessa réplica pode ser cancelada por conflito com a replicação, quando o primário (o banco original) atualiza muito. O parâmetro `hot_standby_feedback` evita o cancelamento por limpeza, mas pode inchar tabela no primário.

Então onde a silver mora? Em outro banco, que lê a réplica. No laboratório, o banco `erp` faz o papel de réplica e o banco `dw` guarda bronze, silver e gold. Ali a réplica é simulada por um papel só de leitura; por isso o teste acima usou uma de verdade.

> Verificação: nível 3, em 2026-11-04, com `postgres:16.15-alpine`. Saída em `lab/saidas/lab9_fatos_da_carga.txt`: o `SELECT` como `replica_leitura` devolve 10 pedidos e o `UPDATE` falha com `cannot execute UPDATE in a read-only transaction`, também pelo `postgres_fdw`.

**No SQL Server, depende**

Depende da tecnologia de réplica, e não sabemos qual é a sua. A documentação da Microsoft sobre grupos de disponibilidade Always On diz o seguinte:

- O banco secundário legível não aceita mudança de esquema nem de dado.
- Outros bancos de leitura e escrita da mesma instância aceitam escrita, inclusive `tempdb`.
- O grupo de disponibilidade básico, só da edição Standard, nem permite leitura no secundário.

Leitura da mentoria: por isso a silver não mora no secundário. Essas páginas tratam só do Always On, e nada disso foi executado aqui (nível 1, conferido na documentação). O T-SQL da silver e da gold está no capítulo 17.

Antes de desenhar, leve estas perguntas ao time: que tecnologia é a nossa réplica? Qual edição? Ela aceita leitura? Em que banco gravável a silver vai morar?

Você já sabe onde cada regra mora. Mas o critério inteiro depende de uma palavra que ainda não provamos: grão. É dela que trata o próximo capítulo.

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

## 8. Silver: datas e fuso horário

"O atendimento foi à meia-noite, e a loja fecha às 22h. O sistema está errado?"

Não. O sistema grava em UTC, o tempo universal coordenado, numa coluna sem fuso. Quem lê esse valor como horário local erra a hora e, perto da virada do dia, erra o dia. A frase guia vale também para uma coluna: antes do SQL, decida o que aquela hora significa, e em que fuso.

A apostila de Orquestração já tratou da agenda e da partição: a que horas a carga roda e onde ela grava. Aqui o assunto é o código de limpeza. Vamos ver a conversão certa, o lugar dela e o texto que nem data é.

### 8.1 O dia que muda sem erro nenhum

"Quantos atendimentos a rede fez no dia 20?"

**Como funciona na prática**

A rede de lojas ganhou um sistema de atendimento que grava UTC. Rode o Lab 2 e compare as duas últimas colunas.

```sql
SELECT b.id, l.nome AS loja, l.fecha_as,
       b.criado_em_utc AS lido_como_esta,
       b.criado_em_utc AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo
FROM bronze.atendimentos b JOIN silver.lojas l ON l.loja_id = b.loja_id ORDER BY b.id;
```

```text
 id |     loja      | fecha_as |   lido_como_esta    |        certo        
----+---------------+----------+---------------------+---------------------
  1 | Loja Centro   | 22:00:00 | 2026-10-20 13:15:00 | 2026-10-20 10:15:00
  2 | Loja Centro   | 22:00:00 | 2026-10-21 00:25:00 | 2026-10-20 21:25:00
  3 | Loja Norte    | 22:00:00 | 2026-10-21 00:50:00 | 2026-10-20 21:50:00
  4 | Loja São João | 20:00:00 | 2026-10-21 12:00:00 | 2026-10-21 09:00:00
(4 rows)
```

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com a imagem `postgres:16.15-alpine`:
> `docker compose exec -T postgres psql -U dw -d dw -f /sql/22_fuso.sql`. Saída em
> `lab/saidas/lab2_fuso_e_datas.txt`.

Olhe o id 2. Gravado às 00h25 (UTC), parece ter acontecido depois do fechamento. Convertido, é 21h25 do dia anterior, com a loja aberta. Os ids 1 e 4 mudam só de hora. Os ids 2 e 3 mudam de dia, e o relatório troca de forma:

| Dia | Lido como está | Convertido |
|---|---|---|
| 2026-10-20 | 1 | 3 |
| 2026-10-21 | 3 | 1 |

**O equívoco comum**

Achar que, se o total bate, a conversão está certa. O total segue 4 nos dois casos. Nenhuma linha some e nenhum erro aparece. Inferência: um teste que só confere o total não pega esse problema.

**Como inspecionar**

Critério da mentoria, em dois passos. Escolha uma linha cujo horário você conhece e confira o dia dela na silver. Depois, conte os atendimentos por hora do dia: hora com a loja fechada pede uma olhada no fuso.

### 8.2 A regra que decide o resultado

"Escrevi `AT TIME ZONE 'America/Sao_Paulo'`. Não era isso?"

**O que é**

No Postgres, um `timestamp` (data e hora) sem fuso seguido de `AT TIME ZONE z` é lido como se já estivesse em `z`. A documentação diz "assuming the given value is in the named time zone", supondo que o valor dado está no fuso nomeado. A expressão não converte para `z`. Ela supõe `z`.

Por isso, UTC gravado em coluna sem fuso pede dois passos: `x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'`. O primeiro declara que o valor está em UTC. O segundo lê esse instante no relógio de São Paulo.

**Como funciona na prática**

Vamos escrever de três jeitos, com a mesma origem:

```sql
SET TIME ZONE 'UTC';
SELECT x AS origem_utc,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo,
       x AT TIME ZONE 'America/Sao_Paulo' AS direcao_errada_em_timestamptz,
       (x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS convertido_duas_vezes
FROM (VALUES (TIMESTAMP '2026-10-21 00:30')) AS t(x);
```

| Escrita | Resultado | Contra o certo |
|---|---|---|
| Dois passos | `2026-10-20 21:30` | certo |
| Só `AT TIME ZONE 'America/Sao_Paulo'` | `2026-10-21 03:30` UTC | 3 horas depois |
| Convertido duas vezes | `2026-10-20 18:30` | 3 horas antes |

> Verificação: nível 3, 2026-11-03, Postgres 16.15, mesmo comando e mesma captura da seção 8.1.

A direção errada ainda engana pela tela. Numa sessão em UTC, ela mostra 03:30. Numa sessão em `America/Sao_Paulo`, o mesmo instante aparece como `2026-10-21 00:30:00-03`, com o relógio do valor gravado. Parece que nada mudou, e são 3 horas depois do certo.

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/70_fuso_por_sessao.sql`, saída em `lab/saidas/lab9_fuso_por_sessao.txt`.

**O equívoco comum**

Decorar os dois passos e aplicar em toda coluna. A regra é uma, e a origem decide. Na mesma silver, o ERP grava horário local, e o pedido usa `criado_em AT TIME ZONE 'America/Sao_Paulo'`, um passo só. Está certo, porque o valor já está em São Paulo. A apostila de Orquestração mostrou esse caso.

Antes de converter, pergunte ao dono da origem em que fuso ela grava. Depois confirme com uma linha conhecida.

### 8.3 O lugar certo, uma vez só

"Converto na silver, na gold ou no Power BI?"

**Critério da mentoria**

Na silver. A conversão conserta registro a registro e não muda o grão: um atendimento continua sendo uma linha. A bronze guarda o valor cru. A gold e o BI só leem o resultado.

```sql
-- The source stores UTC in a column without zone: declare it as UTC, then read it in local time.
CREATE TABLE silver.atendimentos AS
SELECT id AS atendimento_id,
       loja_id,
       COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AS inicio_utc,
       COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS inicio_local,
       (COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo')::date AS dia_local,
       atendido_em_utc IS NULL AS sem_atendido_em
FROM bronze.atendimentos;
```

> Verificação: nível 3. Trecho de `lab/sql/20_silver.sql`, executado em 2026-11-03 no Postgres 16.15, no Lab 1:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`. Saída em
> `lab/saidas/lab1_silver_a_mao.txt`.

Repare em três escolhas. A tabela guarda o instante, o horário local e o dia local, cada um com o nome dizendo o que é. O relatório agrupa por `dia_local`. E a linha sem `atendido_em_utc` usa `criado_em_utc` e fica marcada em `sem_atendido_em`, então a troca aparece.

Sempre que possível, ponha o fuso no nome da coluna. Inferência: a conversão dupla nasce de quem pega uma coluna já local e converte de novo, sem saber. Com `_utc` e `_local` no nome, quem lê vê o que a coluna é.

**O equívoco comum**

Converter no BI "só para ver". No Power Query, `DateTime.LocalNow` devolve a hora da máquina no Desktop e UTC no Power Query Online, porque as máquinas da nuvem estão em UTC. Conversão de fuso feita no BI pode dar um resultado no Desktop e outro no serviço. Isso vem da documentação, nível 1: não rodamos nada em Power Query nesta mentoria. E, se a silver também converte, é a regra escrita duas vezes, que o capítulo 6 já mostrou divergindo.

### 8.4 Nome do fuso, não deslocamento

"Brasília está em -3 o ano inteiro. Por que não desconto 3 horas?"

**Como funciona na prática**

Porque o dado tem passado. Compare as duas escritas em três anos:

```sql
SELECT x AS utc,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS por_nome,
       x - interval '3 hours' AS menos_3_fixo
FROM (VALUES (TIMESTAMP '2018-12-01 12:00'), (TIMESTAMP '2019-12-01 12:00'), (TIMESTAMP '2026-12-01 12:00')) AS t(x);
```

```text
         utc         |      por_nome       |    menos_3_fixo     
---------------------+---------------------+---------------------
 2018-12-01 12:00:00 | 2018-12-01 10:00:00 | 2018-12-01 09:00:00
 2019-12-01 12:00:00 | 2019-12-01 09:00:00 | 2019-12-01 09:00:00
 2026-12-01 12:00:00 | 2026-12-01 09:00:00 | 2026-12-01 09:00:00
(3 rows)
```

> Verificação: nível 3, 2026-11-03, Postgres 16.15, mesmo comando e mesma captura da seção 8.1.

Em dezembro de 2018, São Paulo estava em UTC-2, no horário de verão. O nome do fuso sabe disso, e o desconto fixo erra 1 hora. Em 2019 e em 2026, os dois coincidem.

**O equívoco comum**

Trocar o nome por `'-03'`. Em `AT TIME ZONE`, esse texto é lido como especificação POSIX, positivo a oeste. A documentação avisa que é o oposto da convenção ISO-8601.

```sql
SELECT TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE '-03' AS texto_menos_3,
       TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE '+03' AS texto_mais_3,
       TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE interval '-03:00' AS intervalo_menos_3;
```

```text
    texto_menos_3    |    texto_mais_3     |  intervalo_menos_3  
---------------------+---------------------+---------------------
 2026-10-21 03:30:00 | 2026-10-20 21:30:00 | 2026-10-20 21:30:00
(1 row)
```

> Verificação: nível 3, 2026-11-03, Postgres 16.15, mesmo comando e mesma captura da seção 8.1. A captura marca
> `America/Sao_Paulo` com `-03:00:00` e `is_dst` falso. A imagem traz o pacote `tzdata-2026e-r0`, e o Postgres dela lê os
> fusos de `/usr/share/zoneinfo` (`--with-system-tzdata`); saída em `lab/saidas/lab9_tzdata_da_imagem.txt`, 2026-11-04. A versão mais recente da base da IANA em 2026-11-03 é a 2026f, de 2026-10-27, segundo o NEWS.

O `'-03'` deu UTC+3. O `interval '-03:00'` acerta, e o nome também. Use o nome.

**Horário de verão hoje**

Não há no Brasil. O Decreto nº 9.772, de 25 de abril de 2019, diz no art. 1º: "Fica encerrada a hora de verão no território nacional". A base de fusos da IANA registrou "Brazil has canceled DST and will stay on standard time indefinitely": o Brasil cancelou o horário de verão e fica no horário padrão por tempo indeterminado. Para 2026/2027, o relatório do Ministério de Minas e Energia assinado em 31 de agosto de 2026 registra que os estudos do ONS não indicam implantar o horário de verão e dá a ação por concluída.

Esse é o estado em 2026-11-03. Não achamos decreto posterior, e isso é resultado de busca, não de consulta a um índice oficial. Reconfira antes de depender disso. Inferência: se a regra voltar, o nome do fuso acompanha quando a base de fusos do banco for atualizada, e o desconto fixo fica errado em silêncio.

**Uma rede, vários fusos**

O Brasil tem 16 identificadores de fuso na IANA, de -02 (Noronha) a -05 (Eirunepe e Rio_Branco), todos sem horário de verão. `America/Sao_Paulo` cobre GO, DF, MG, ES, RJ, SP, PR, SC e RS. Critério da mentoria: rede com loja fora dessas UFs precisa de fuso por loja. O laboratório usa um fuso só e não testa esse caso.

### 8.5 O fuso também erra pelo tipo e pela sessão

"Mudei a coluna para `timestamptz`. Resolveu?"

**O que é**

`timestamptz` não guarda o fuso que você informou. E o cast (conversão de tipo) para `date` segue o `TimeZone` da sessão, a configuração de fuso da conexão.

**Como funciona na prática**

```sql
SET TIME ZONE 'UTC';
SELECT TIMESTAMPTZ '2026-10-21 00:30+00' AS instante, (TIMESTAMPTZ '2026-10-21 00:30+00')::date AS dia;
SET TIME ZONE 'America/Sao_Paulo';
SELECT TIMESTAMPTZ '2026-10-21 00:30+00' AS instante, (TIMESTAMPTZ '2026-10-21 00:30+00')::date AS dia;
```

```text
SET
        instante        |    dia     
------------------------+------------
 2026-10-21 00:30:00+00 | 2026-10-21
(1 row)

SET
        instante        |    dia     
------------------------+------------
 2026-10-20 21:30:00-03 | 2026-10-20
(1 row)
```

> Verificação: nível 3, 2026-11-03, Postgres 16.15, mesmo comando e mesma captura da seção 8.1.

Mesmo instante, dois dias, e a consulta não mudou. Por isso o `dia_local` da silver escreve o fuso na expressão. Conferimos em sessão UTC e em sessão `America/Sao_Paulo`, recalculando a expressão: para o atendimento 2, as duas deram `2026-10-20`.

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/70_fuso_por_sessao.sql`, saída em `lab/saidas/lab9_fuso_por_sessao.txt`.

**O equívoco comum**

Confiar em literal com deslocamento. `TIMESTAMP '2026-10-21 00:30:00-03'` sai `00:30`. A documentação diz "PostgreSQL will silently ignore any time zone indication": o tipo sem fuso ignora em silêncio qualquer indicação de fuso. Se a origem manda texto com deslocamento, esse cast joga a informação fora.

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/70_fuso_por_sessao.sql`, saída em `lab/saidas/lab9_fuso_por_sessao.txt`.

### 8.6 Texto que não é data

"Uma data ruim derrubou a carga. Como acho a linha?"

**Como funciona na prática**

O `to_date` não pula a linha. Ele derruba a instrução inteira:

```sql
SELECT to_date('31/02/2026', 'DD/MM/YYYY') AS impossivel;
```

```text
psql:/sql/22_fuso.sql:43: ERROR:  date/time field value out of range: "31/02/2026"
```

> Verificação: nível 3, 2026-11-03, Postgres 16.15, mesmo comando e mesma captura da seção 8.1.

Sem `ON_ERROR_STOP`, o script segue para a instrução seguinte. A captura do Lab 2 mostra isso: o erro está lá, e o `psql` termina com código 0. Se ninguém lê a saída, a carga parece ter passado.

**Como separar antes do cast**

Teste o texto primeiro. `pg_input_is_valid` responde sem dar erro, e `pg_input_error_info` diz o motivo.

```sql
SET datestyle = 'ISO, DMY';
SELECT v AS emissao_texto,
       pg_input_is_valid(v, 'date') AS valida,
       CASE WHEN pg_input_is_valid(v, 'date') THEN v::date END AS dia
FROM (VALUES ('20/10/2026'), ('31/02/2026'), ('ontem')) AS t(v);
SELECT message, sql_error_code FROM pg_input_error_info('31/02/2026', 'date');
RESET datestyle;
```

```text
 emissao_texto | valida |    dia     
---------------+--------+------------
 20/10/2026    | t      | 2026-10-20
 31/02/2026    | f      | 
 ontem         | f      | 
(3 rows)

                     message                      | sql_error_code 
--------------------------------------------------+----------------
 date/time field value out of range: "31/02/2026" | 22008
(1 row)
```

> Verificação: nível 3, 2026-11-04, Postgres 16.15: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/71_texto_antes_do_cast.sql`,
> saída em `lab/saidas/lab9_fuso_por_sessao.txt`.

O teste roda com `DateStyle` em `'ISO, DMY'`, dia antes do mês, como o texto da origem. Na imagem do laboratório, o padrão da sessão é `ISO, MDY`. Confira o da sua sessão antes de confiar no resultado.

**Critério da mentoria**

A linha ruim não some e não vira data inventada. O `CASE` devolve nulo, e nulo sem contagem é falha escondida, como no capítulo 7. Mantenha o texto original ao lado da data e conte as linhas que falharam. O capítulo 13 transforma essa contagem em teste.

**Para levar**

Pergunte em que fuso a origem grava. Converta uma vez, na silver, pelo nome do fuso. Guarde instante, horário local e dia local, com o nome dizendo o que cada um é. Separe o texto ruim antes do cast e conte o que separou. No SQL Server a escrita muda, e o capítulo 17 mostra como.

Com texto, nulo, data e fuso tratados, a silver está pronta. Agora dá para montar o que junta: fato, dimensão e a estrela do capítulo 9.

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

## 14. Materialização, incremental e reprocesso

Os testes dizem quando não publicar. Faltam duas decisões: como guardar o resultado e o que acontece quando a mesma carga roda de novo. Quem decidiu o que uma linha significa já sabe qual é a chave. E é a chave que separa reprocesso de duplicata.

### 14.1 View, table ou incremental?

"Preciso gravar tudo em tabela, ou a view resolve?"

**O que é**

Materialização é a estratégia para guardar o resultado do modelo no banco. O dbt tem cinco tipos embutidos: table, view, incremental, ephemeral e materialized view. Vamos ficar em três. A escolha existe com ou sem ferramenta.

| Forma | O que guarda | Quando processa | Indicação | O preço |
|---|---|---|---|---|
| View | Nada, só a consulta | A cada uso | É o padrão do dbt | Fica lenta quando empilhada |
| Table | O resultado | Refeita a cada execução | O que o BI consulta | Refaz tudo, até o que não mudou |
| Incremental | O resultado acumulado | Só parte dos dados, sobre o que já existe | Nunca como ponto de partida | Chave, reprocesso, atraso e afastamento da origem |

Critério da mentoria: comece em view. Passe para table o que o BI consulta, quando a lentidão aparecer medida no seu banco. Passe para incremental só quando refazer a table ficar lento demais, também medido.

**Como funciona sem ferramenta**

Sem ferramenta, o Postgres já entrega as peças. `CREATE VIEW` não materializa: a consulta roda a cada uso. `CREATE OR REPLACE VIEW` exige as mesmas colunas, com os mesmos nomes, na mesma ordem e com os mesmos tipos, e pode acrescentar colunas no fim. `REFRESH MATERIALIZED VIEW` substitui todo o conteúdo. Numa prova curta, depois de um `INSERT` na tabela base, a view mostrou 2 linhas e a materializada 1. Depois do `REFRESH`, 2 e 2.

> Verificação: nível 3, `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`.

**O equívoco comum**

"Incremental é o jeito profissional." A documentação do dbt diz o contrário: "don't start with incremental models". Incremental troca tempo de execução por decisões que você passa a carregar. O resto do capítulo é essa conta.

### 14.2 A mesma carga, rodada duas vezes

"O orquestrador repetiu a tarefa. O que aconteceu com o meu número?"

**O que é**

A apostila de Orquestração deixou a definição: idempotência é rodar de novo e ter o mesmo resultado de rodar uma vez. O orquestrador repete a tarefa que falha. Por isso a documentação do Airflow pede o mesmo resultado a cada nova tentativa e manda trocar `INSERT` por `UPSERT` (atualizar se a linha existe, inserir se não).

**Como funciona na prática**

Vamos ver por que dobra, na menor carga possível: uma linha por loja e dia.

```sql
-- A daily load with one row per store. Synthetic data.
CREATE TEMP TABLE carga_do_dia (dia date, loja_id int, receita numeric(10,2));
INSERT INTO carga_do_dia VALUES ('2026-10-20', 1, 130.00), ('2026-10-20', 2, 90.00);
CREATE TEMP TABLE fct_dia (dia date, loja_id int, receita numeric(10,2));

-- The same load twice, as an orchestrator retry would do.
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
INSERT INTO fct_dia SELECT * FROM carga_do_dia;

SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;
```

```text
 loja_id | linhas | receita 
---------+--------+---------
       1 |      2 |  260.00
       2 |      2 |  180.00
(2 rows)
```

Nenhum erro. A loja 1 vendeu 130,00, e a tabela diz 260,00. Há dois caminhos de saída. Limpe a tabela antes de cada um e repita o `SELECT` no fim.

```sql
TRUNCATE fct_dia;

-- Path A: replace the window inside one transaction. Run this block twice.
BEGIN;
DELETE FROM fct_dia WHERE dia = '2026-10-20';
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
COMMIT;
```

```sql
TRUNCATE fct_dia;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE (dia, loja_id);

-- Path B: the key lives in the table. Run this INSERT twice.
INSERT INTO fct_dia SELECT * FROM carga_do_dia
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
```

| Caminho, rodado duas vezes | Linhas por loja | Receita da loja 1 |
|---|---|---|
| `INSERT` | 2 | 260,00 |
| `DELETE` da janela e `INSERT`, numa transação | 1 | 130,00 |
| `UNIQUE (dia, loja_id)` e `ON CONFLICT DO UPDATE` | 1 | 130,00 |

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`. O arquivo traz os blocos desta seção e da 14.4, sem `ON_ERROR_STOP`.

Por que a transação? Sem ela, um erro no meio pode deixar a janela pela metade. Na mesma prova, forçamos um erro no `INSERT` depois do `DELETE`: o `ROLLBACK` deixou a janela como estava, com 1 linha e 130,00. No teste do capítulo 19, rodado à mão, o script que falhou no meio apagou a carga anterior, gravou metade da nova e o `psql` saiu com 0. Com `ON_ERROR_STOP` e `--single-transaction`, saiu com 3 e preservou o estado anterior.

Critério da mentoria: refaz a janela inteira? `DELETE` e `INSERT`. A chave é estável e a tabela aceita `UNIQUE`? `ON CONFLICT`.

### 14.3 O mesmo reprocesso no dbt

"A ferramenta me protege sozinha?"

**Como funciona na prática**

Só se você der a chave a ela. No Lab 6, dois modelos leem os mesmos 4 atendimentos com o mesmo filtro.

```sql
{{ config(materialized='incremental') }}

-- No unique_key: dbt appends, so the lookback window duplicates rows on every reprocess.
select atendimento_id, loja_id, dia_local
from {{ ref('stg_atendimentos') }}
{% if is_incremental() %}
where dia_local >= (select max(dia_local) from {{ this }})
{% endif %}
```

O outro modelo muda a primeira linha e o comentário:

```sql
{{ config(materialized='incremental', unique_key='atendimento_id') }}
```

Rode o `dbt build` duas vezes e conte as linhas:

```text
  modelo   | linhas | atendimentos 
-----------+--------+--------------
 sem_chave |      5 |            4
 com_chave |      4 |            4
(2 rows)
```

> Verificação: nível 3. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, `postgres:16.15-alpine`, 2026-11-03. Primeira carga com `docker compose --profile dbt run --rm dbt dbt build --select tag:experimento --vars '{experimentos: true}'`. Reprocesso com `docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'`. Saída em `lab/saidas/lab6_testes_que_param.txt`. Nível 2: `dbt parse` em `lab/saidas/lab5_projeto_dbt.txt` e o SQL compilado em `target/compiled`.

Vamos ver por que deu 5, e não 8. O filtro traz de volta só o último dia, que tem 1 atendimento. A segunda execução registra `INSERT 0 1` nos dois modelos. Sem chave, essa linha fica repetida. Com chave, o adaptador usa `delete+insert`: o `logs/dbt.log` mostra `delete from` antes do `insert`, e o total fica em 4.

O teste `unique` do capítulo 13 acusa a diferença: `FAIL 1` no modelo sem chave, `PASS` no outro, e o `dbt build` sai com 1. Depois, `--full-refresh` reconstruiu o modelo sem chave com 4.

**O que é**

Sem `unique_key`, a maioria dos adaptadores só acrescenta (append), sem olhar se a linha é duplicata. No `dbt-postgres`, as estratégias são `append`, padrão sem chave; `merge`; `delete+insert`, padrão com chave; e `microbatch`. Se a regra mudou, `--full-refresh` derruba a tabela e reconstrói tudo.

### 14.4 Tenho chave. Estou protegido?

"O que ainda duplica depois da chave única?"

**Chave com nulo**

Por padrão, dois nulos não colidem numa restrição `UNIQUE`. O `ON CONFLICT` não vê o conflito. Continue na tabela do caminho B:

```sql
-- Run this INSERT twice: the nulls do not collide.
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;

SELECT count(*) AS linhas FROM fct_dia WHERE dia = '2026-10-23';
```

```text
 linhas 
--------
      2
(1 row)
```

Com a restrição refeita como `UNIQUE NULLS NOT DISTINCT (dia, loja_id)`, as mesmas duas cargas deram 1 linha. O dbt faz o mesmo aviso: coluna de `unique_key` com nulo pode gerar duplicata.

Critério da mentoria: não esconda na restrição um defeito da chave. Ponha `not_null` ao lado do `unique`, como no capítulo 13, e decida o que aquele nulo significa, como no capítulo 7.

**Chave repetida no lote**

Agora a própria carga traz a mesma chave duas vezes. Testamos cada comando em separado, com chave nova e com chave já gravada no alvo.

```sql
-- A batch with the same key twice.
CREATE TEMP TABLE lote (dia date, loja_id int, receita numeric(10,2));
INSERT INTO lote VALUES ('2026-10-22', 1, 10.00), ('2026-10-22', 1, 20.00);

INSERT INTO fct_dia SELECT * FROM lote
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;

MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);

DELETE FROM fct_dia f USING lote l WHERE f.dia = l.dia AND f.loja_id = l.loja_id;
INSERT INTO fct_dia SELECT * FROM lote;
```

| Comando | Chave nova no alvo | Chave já no alvo |
|---|---|---|
| `ON CONFLICT DO UPDATE` | `ON CONFLICT DO UPDATE command cannot affect row a second time` | O mesmo erro |
| `MERGE`, com `UNIQUE` | `duplicate key value violates unique constraint` | `MERGE command cannot affect row a second time` |
| `MERGE`, sem `UNIQUE` | Grava as duas, `MERGE 2`, 30,00 | `MERGE command cannot affect row a second time` |
| `DELETE ... USING` e `INSERT`, numa transação, sem `UNIQUE` | Grava as duas, 30,00 | Grava as duas, 30,00 |

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`. O `DELETE` e o `INSERT` rodaram entre `BEGIN` e `COMMIT`.

Erro é o caso bom: a carga parou, e o alvo ficou como estava. O caso ruim é o silencioso: duas linhas e 30,00 numa chave só. A documentação do `MERGE` explica a diferença: `INSERT` repetido causa violação de unicidade; `UPDATE` ou `DELETE` repetido, violação de cardinalidade.

E no dbt? O `delete+insert` apaga as chaves do lote e insere o lote inteiro, sem deduplicar. Lendo a macro `default__get_delete_insert_merge_sql`, a chave repetida entraria duas vezes. Nível 1: leitura de código, não executamos esse caso no dbt.

Critério da mentoria: deduplique o lote antes de gravar, por chave e com desempate explícito, como no capítulo 6. Depois da carga, rode `unique`.

Tudo aqui rodou em Postgres, em Linux. Em outro banco, confira o comportamento antes de confiar na tabela. O `MERGE` em T-SQL está no capítulo 17.

### 14.5 O fato que chega atrasado

"O atendimento de ontem só apareceu hoje. Ele entra?"

**O equívoco comum**

"Filtro por `max(updated_at)` e todo dado novo entra." Não entra. O incremental filtrado assim perde o fato que chega atrasado. O dbt recomenda uma janela de volta (lookback window) junto com `unique_key`. E admite o limite: os incrementais "inevitably drift from the source data over time", ou seja, se afastam da origem com o tempo.

**Como funciona na prática**

Numa prova curta, com `atendimento_id` como chave e `ON CONFLICT`, só muda o `WHERE`:

```sql
-- Looks forward only: the late row is older than the target's maximum.
WHERE dia >= (SELECT max(dia) FROM alvo)

-- Lookback window of one day: the key absorbs the rows that come back.
WHERE dia >= (SELECT max(dia) FROM alvo) - 1
```

| Situação, com o alvo já no dia 21 | Na origem | No alvo |
|---|---|---|
| Chega um atendimento do dia 20, filtro no máximo | 3 | 2 |
| O mesmo caso, janela de um dia | 3 | 3 |
| Chega outro, do dia 18, fora da janela | 4 | 3 |

> Verificação: nível 3, `postgres:16.15-alpine`, 2026-11-04, dados sintéticos: `docker compose exec -T postgres psql -U dw -d dw -X -f /sql/76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`.

A última linha é o afastamento que o dbt admite. A janela só alcança o atraso que cabe nela. O filtro do Lab 6 é o caso mínimo: volta só ao último dia.

Critério da mentoria: meça o maior atraso real da sua origem antes de escolher a janela. Lembre que janela sem chave duplica, como na seção 14.3. E agende uma reconstrução com `--full-refresh`, conferindo o total contra a origem. Ela só funciona enquanto a camada anterior ainda guarda o dado.

### 14.6 O histórico cabe num incremental?

"Posso guardar o histórico do preço com incremental?"

Não. `delete+insert` apaga a linha antiga e não guarda histórico. A documentação do dbt é direta: "For SCD2, use dbt snapshots, not delete+insert". O tipo 2 do capítulo 11 cria uma linha nova a cada mudança. O incremental com chave substitui a linha. O capítulo 15 mostra o snapshot.

**Como decidir**

Critério da mentoria, para revisar qualquer incremental:

1. Qual é o grão, e que coluna o garante?
2. A chave pode ter nulo?
3. O lote pode trazer a chave repetida?
4. Qual é o maior atraso da origem, e a janela o cobre?
5. Se a tarefa rodar duas vezes, o que muda no total?

Alguma resposta foi "não sei"? Fique na table até saber.

Decidido como guardar, falta organizar. No próximo capítulo, o mesmo SQL vira projeto dbt, e vamos conferir se o número continua o mesmo.

## 15. O mesmo SQL como projeto dbt

Até aqui, tudo rodou em SQL à mão. Esse caminho é válido, e este capítulo não pede que você o abandone. Ele mostra o que muda quando o mesmo fluxo vira projeto no dbt, a ferramenta que usamos como exemplo. O que uma linha significa, o dbt não decide por você.

### 15.1 O SELECT sai do script e vira modelo

"Vou ter de reescrever o SQL que já escrevi?"

**O que é**

Não. No dbt, um modelo é principalmente um `SELECT` salvo num arquivo `.sql`. Rodar o modelo transforma o dado sem tirá-lo do armazém: é o T do ELT. A dbt Labs mostra o caminho num guia de migração: o `INSERT ... SELECT` vira modelo quando o `SELECT` sai da procedure e vai para o arquivo do modelo.

**Como funciona na prática**

Vamos ver a mesma tabela dos dois jeitos. Primeiro, o script do Lab 1:

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

Agora, o modelo do Lab 5, em `models/silver/stg_pedidos.sql`:

```sql
with ultima_carga as (
    select
        *,
        row_number() over (partition by id order by _carregado_em desc) as ordem
    from {{ source('bronze', 'pedidos') }}
)

select
    id as pedido_id,
    loja_id,
    coalesce(nullif(initcap(trim(cliente)), ''), 'Não informado') as cliente,
    valor,
    lower(trim(status)) as status_origem,
    case lower(trim(status))
        when 'pago' then 'pago'
        when 'cancelado' then 'cancelado'
        when 'pendente' then 'pendente'
        else 'desconhecido'
    end as status,
    to_date(emissao_texto, 'DD/MM/YYYY') as dia_emissao,
    criado_em at time zone 'America/Sao_Paulo' as criado_em_utc,
    criado_em::date as dia_local
from ultima_carga
where ordem = 1
```

> Verificação: script em nível 3, com `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql`, saída em `lab/saidas/lab1_silver_a_mao.txt`. Modelo em nível 3 pela execução com `docker compose --profile dbt run --rm dbt dbt build`, e em nível 2 por `dbt parse` e pelo SQL compilado, saída em `lab/saidas/lab5_projeto_dbt.txt`. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03.

Compare os dois. Saiu o `CREATE TABLE silver.pedidos AS`. A leitura de `bronze.pedidos` virou `{{ source('bronze', 'pedidos') }}`. A caixa das palavras mudou, e isso é estilo. O `COALESCE`, o `CASE` com `ELSE`, o `to_date`, o fuso e a última carga são os mesmos.

**O equívoco comum**

"Então é copiar e colar e está pronto." O `SELECT` vem junto. O modo de pensar, não. A própria dbt Labs reconhece que migrar procedures é uma mudança grande de paradigma, do procedural para o declarativo. Leitura da mentoria: o SQL escrito à mão não se perde. Você para de escrever cada passo na ordem e passa a declarar o resultado e de quem ele depende.

### 15.2 O que mais mora na pasta

"Além dos SELECT, o que eu passo a manter?"

**Como funciona na prática**

Vamos abrir o projeto do Lab 5. O resumo abaixo diz o papel de cada item neste laboratório.

```text
projeto_dbt/
  dbt_project.yml           nome do projeto e como guardar cada camada
  profiles.yml              a conexão, com a senha vinda de variável de ambiente
  models/_sources.yml       as tabelas da bronze, carregadas pela ingestão
  models/silver/            stg_*.sql, foto_do_dia.sql e _silver.yml, com os testes
  models/gold/              dim_*.sql, fct_vendas.sql, obt_vendas.sql, vendas_por_dia.sql e _gold.yml
  models/experimentos/      os casos de erro do Lab 6, desligados por padrão
  seeds/                    de_para_categoria.csv
  snapshots/_snapshots.yml  o histórico do preço
  tests/                    assert_*.sql, os testes escritos à mão
```

Cada camada diz como guardar o resultado. Trecho do `dbt_project.yml`:

```yaml
models:
  rede_de_lojas:
    silver:
      +schema: silver
      +materialized: view
    gold:
      +schema: gold
      +materialized: table
    experimentos:
      +schema: experimentos
      +enabled: "{{ var('experimentos', false) }}"
      +tags: ["experimento"]
```

Materialização é a estratégia para guardar o resultado do modelo. A silver fica em view, o padrão do dbt, que não guarda dado. A gold fica em table, a indicada para o que o BI consulta, com uma exceção: `obt_vendas`, view sobre a estrela, configurada no próprio modelo. O script da silver grava tabela, e o projeto grava view. A seção 15.4 compara o conteúdo dos dois, e o capítulo 14 trata da escolha.

O `var('experimentos', false)` tem um detalhe que custa tempo. Um `var()` no `dbt_project.yml` não enxerga o bloco `vars` do próprio arquivo. Sem o valor padrão, o `dbt debug` para em `Required var 'experimentos' not found in config`.

> Verificação: trecho em nível 3 pela execução do Lab 5, e em nível 2 por `dbt parse`. A falha sem valor padrão: nível 3, `dbt-core` 1.12.6, 2026-11-04, numa cópia que só tira o valor padrão (`lab/checagens/var_sem_padrao/dbt_project.yml`), com `dbt debug`; saída em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`. A mensagem inteira: `Could not render {{ var('experimentos') }}: Required var 'experimentos' not found in config`.

Agora o elo entre os modelos. No código de `fct_vendas`, ele está escrito assim:

```sql
from {{ ref('stg_itens') }} i
join {{ ref('stg_pedidos') }} o using (pedido_id)
```

No SQL compilado, o que chega ao banco é SQL comum:

```sql
from "dw"."dbt_silver"."stg_itens" i
join "dw"."dbt_silver"."stg_pedidos" o using (pedido_id)
```

O `dbt` de `dbt_silver` vem do `schema` do `profiles.yml`, e o `silver`, do `+schema`.

O mesmo `ref` alimenta o grafo do projeto. O `dbt docs generate` roda local, sem conta, e escreve `index.html`, `catalog.json` e `manifest.json` em `target/`. O manifesto guarda os pais de cada modelo, no `parent_map` (mapa de pais):

```text
pais de fct_vendas: ['model.rede_de_lojas.dim_loja', 'model.rede_de_lojas.dim_produto', 'model.rede_de_lojas.stg_itens', 'model.rede_de_lojas.stg_pedidos']
```

> Verificação: nível 3. `docker compose --profile dbt run --rm dbt dbt docs generate`, `dbt-core` 1.12.6, 2026-11-03. SQL compilado e pais em `lab/saidas/lab5_projeto_dbt.txt`.

**O equívoco comum**

"Se está no dbt, a linhagem está completa." Não está. O grafo só vê o que o projeto declara com `ref`, `source`, `function` ou `metric`. No Lab 9, um modelo com a tabela escrita à mão roda e fica sem pai nenhum: `pais de model.linhagem.copia_sem_ref: []`. Saída em `lab/linhagem/saidas/dbt_01_linhagem.txt`. Inferência, sem teste com esses produtos: o cálculo de um ERP e o Power Query só entram se alguém os declarar. O capítulo 18 volta a isso.

### 15.3 Snapshot em YAML

"O capítulo 11 montou a vigência à mão. O dbt faz isso por mim?"

**O que é**

Faz. No dbt, snapshot é a implementação de SCD tipo 2. A forma atual é em YAML, com `relation` e `config`. `strategy` e `unique_key` são obrigatórios. O bloco abaixo traz duas estratégias de propósito, lendo a mesma foto:

```yaml
snapshots:
  - name: snap_produtos_preco
    description: Type 2 history of the price. check compares the column, and the photo day dates the version.
    relation: ref('foto_do_dia')
    config:
      schema: snapshots
      unique_key: id
      strategy: check
      check_cols: [preco]
      updated_at: foto_em

  - name: snap_produtos_por_timestamp
    description: The wrong choice on purpose. The nightly job touches atualizado_em on every row, so every night looks like a change.
    relation: ref('foto_do_dia')
    config:
      schema: snapshots
      unique_key: id
      strategy: timestamp
      updated_at: atualizado_em
```

O modelo `foto_do_dia` lê da bronze a foto do dia escolhido pela variável `dia_foto`. A foto crua fica na bronze, como critério da mentoria desde o capítulo 11.

**Como funciona na prática**

Rode os três dias, um por vez:

```bash
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-21"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-22"}'
```

O `check` guarda 7 versões para 5 produtos:

```text
 id | preco |   dbt_valid_from    |    dbt_valid_to     
----+-------+---------------------+---------------------
 10 | 60.00 | 2026-10-20 00:00:00 | 
 20 | 33.30 | 2026-10-20 00:00:00 | 
 30 | 15.00 | 2026-10-20 00:00:00 | 2026-10-22 00:00:00
 30 | 17.00 | 2026-10-22 00:00:00 | 
 40 | 20.50 | 2026-10-20 00:00:00 | 2026-10-22 00:00:00
 40 | 20.00 | 2026-10-22 00:00:00 | 
 50 | 12.00 | 2026-10-20 00:00:00 | 
(7 rows)
```

O `timestamp` guarda 15, três por produto. Veja o produto 10, com o preço sempre igual:

```text
 id | preco |   dbt_valid_from    |    dbt_valid_to     
----+-------+---------------------+---------------------
 10 | 60.00 | 2026-10-20 03:00:00 | 2026-10-21 03:00:00
 10 | 60.00 | 2026-10-21 03:00:00 | 2026-10-22 03:00:00
 10 | 60.00 | 2026-10-22 03:00:00 | 
(3 rows)
```

> Verificação: nível 3 pela execução, nível 2 por `dbt parse`. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

Vamos ver por que 15. O capítulo 11 mostrou a rotina que toca a data de alteração de todas as linhas toda noite. O `timestamp` cria versão quando essa data é mais recente que a última execução. Toda noite parece mudança, e nascem versões falsas. O `check` compara só o preço. A documentação indica esse uso: "The check strategy is useful for tables which do not have a reliable updated_at column".

Três detalhes da saída:

- Com `updated_at: foto_em`, a versão nasce no dia da foto, sem aviso.
- A vigência já nasce meio aberta. Nas versões fechadas, `dbt_valid_to` é igual ao `dbt_valid_from` da seguinte, o que combina com `>=` e `<`. Aqui, só as 2 fechadas provam isso, as dos produtos 30 e 40. As outras 5 estão abertas. `hard_deletes` em `invalidate` não testamos.
- O snapshot acrescenta `dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from` e `dbt_valid_to`. A documentação trata o `dbt_scd_id` como chave de uso interno. O capítulo 12 explica por que a chave da dimensão é outra.

**O equívoco comum**

"É mais um modelo. Se der errado, refaço." Não é. "Snapshots can't be rebuilt", diz a documentação. Ela sugere schema separado e pede chave realmente única. O snapshot também trabalha em lote: só registra mudança quando roda, e por isso precisa de agenda, entre uma vez por hora e uma por dia.

Recarga completa (full refresh) não resolve. A documentação diz que snapshot ignora tanto a configuração `full_refresh` quanto a flag `--full-refresh`. O que refaz é a foto crua. Só faça isto no laboratório: o `DROP` apaga o histórico.

```bash
docker compose exec -T postgres psql -U dw -d dw -c "drop table dbt_snapshots.snap_produtos_preco, dbt_snapshots.snap_produtos_por_timestamp"
```

Repita os três dias e confira:

```text
 linhas_check | linhas_timestamp 
--------------+------------------
            7 |               15
(1 row)
```

> Verificação: nível 3, `dbt-core` 1.12.6, 2026-11-03, saída em `lab/saidas/lab5_projeto_dbt.txt`. Em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`, nível 3, 2026-11-04: `dbt snapshot --full-refresh` é recusado com `No such option`, e `dbt build --full-refresh --select` no snapshot manteve as 7 linhas.

Inferência: sem a foto, snapshot apagado é histórico perdido. E o `updated_at` protege também a chave interna. Num teste à parte, sem arquivo publicado, com `updated_at` no dia da foto, refazer os três dias devolveu as mesmas 7 chaves. Sem ele, o hash leva a hora da execução, e nenhuma voltou.

> Verificação: nível 3, num teste à parte, sem arquivo publicado. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, PostgreSQL 16.15, 2026-11-03.

### 15.4 A prova: o mesmo número

"Como sei que o dbt não mudou o meu número?"

**Como inspecionar**

Rode o projeto inteiro e compare com o SQL à mão, que grava em `silver` e `gold`. O dbt grava em `dbt_silver` e `dbt_gold`, então os dois convivem.

```bash
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/50_comparar_a_mao_e_dbt.sql
```

```text
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
```

São 46 nós: 1 seed (o CSV de categorias), 2 snapshots, 5 modelos em table, 6 em view e 32 testes de dado. O dbt acha 12 modelos e roda 11, porque `foto_do_dia` é ephemeral (efêmero) e não aparece na saída como objeto. Os 2 avisos são de propósito: `assert_status_desconhecido` e `not_null_stg_produtos_custo`. O `assert_vendas_sem_versao` passa, porque nenhuma venda real cai no membro desconhecido.

A comparação usa `EXCEPT` nos dois sentidos. Cada coluna conta as linhas que só existem de um lado. Trecho de `50_comparar_a_mao_e_dbt.sql`:

```sql
SELECT 'pedidos da silver',
       (SELECT count(*) FROM (SELECT * FROM silver.pedidos EXCEPT SELECT * FROM dbt_silver.stg_pedidos) x),
       (SELECT count(*) FROM (SELECT * FROM dbt_silver.stg_pedidos EXCEPT SELECT * FROM silver.pedidos) x)
```

```text
         tabela         | so_a_mao | so_dbt 
------------------------+----------+--------
 vendas_por_dia         |        0 |      0
 fct_vendas             |        0 |      0
 dim_produto            |        0 |      0
 pedidos da silver      |        0 |      0
 atendimentos da silver |        0 |      0
(5 rows)

 lado  | linhas | chaves 
-------+--------+--------
 a_mao |      8 |      8
 dbt   |      8 |      8
(2 rows)
```

> Verificação: nível 3. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03, com os dois comandos acima. Saída em `lab/saidas/lab5_projeto_dbt.txt`, sem os carimbos de hora na linha `Done`.

Zero nas duas colunas. Mudou quem organiza. O tratamento não mudou.

A chave está na comparação: `produto_sk` entra na lista de colunas de `dim_produto` e de `fct_vendas`. A fórmula de hash é a mesma nos dois fluxos, critério da mentoria que o capítulo 12 explicou. Os dois lados têm 8 linhas e 8 chaves: 7 versões e o membro `'-1'`. A receita paga segue em 836,10, com 430,90, 111,90 e 293,30 nos dias 20, 21 e 22. É o número que a apostila de Orquestração publicou, e o teste `assert_receita_igual_a_do_piloto` passa a vigiá-lo.

**O equívoco comum**

"Deu zero, então a ferramenta garante." Não garante. Inferência: o zero vale para estes dados e estas cinco comparações. Critério da mentoria para a sua migração: rode script e modelo lado a lado, escreva o seu `EXCEPT` nos dois sentidos e só desligue o script quando voltar zero. Se a chave não entrar na comparação, ela pode divergir sem ninguém ver.

### 15.5 Sintaxe atual contra material antigo

"Achei um tutorial com `tests:`, e ele roda. Posso seguir?"

**Como inspecionar**

Pode rodar. Não copie para projeto novo. Compare com esta tabela, que mostra o que aconteceu ao rodar a forma antiga em cada geração:

| No material antigo | Na sintaxe atual | No dbt v1 | No dbt v2 |
|---|---|---|---|
| `tests:` | `data_tests:` | Roda sem aviso | Roda sem aviso |
| `values:` direto em `accepted_values` | `values:` sob `arguments:` | Só aviso, com `WARN=0` no resumo | Erro `dbt1159` |
| `meta` fora de `config` | `meta` dentro de `config` | Passa em silêncio | Erro `dbt1060` |
| Chave própria direto em `config` | A chave dentro de `meta` | Passa em silêncio | Erro `dbt1060` |
| `materialized` sem `+` no `dbt_project.yml` | `+materialized` | Passa em silêncio | Erro `dbt1013` |
| Snapshot em bloco SQL, com `target_schema` | YAML com `relation` e `config` | Roda sem aviso | Roda sem aviso |

> Verificação: nível 3 num teste à parte da mentoria, sem arquivo publicado, com um projeto em cada sintaxe. `dbt-core` 1.12.6 e `dbt-oss` 2.0.11, os dois com DuckDB, 2026-11-03. Esta tabela não testa o v2 com Postgres, e o capítulo 16 conta por quê. Entrada de cada forma, pela documentação (nível 1): `data_tests` na 1.8, snapshot em YAML na 1.9, `arguments` na 1.10.5.

Leia as duas últimas colunas juntas. Passar no v1 não prova que passa no v2. Parte desses avisos, diz a documentação, vale só para Snowflake, Databricks, BigQuery e Redshift. Inferência: silêncio em outro banco não é aprovação. O `tests:` não quebra hoje, mas está fora da sintaxe documentada. O snapshot em bloco SQL segue disponível, e a documentação recomenda YAML para os novos. O laboratório já nasce na sintaxe atual, para você não aprender duas vezes.

**O equívoco comum**

"Migrar o snapshot para YAML é só trocar a forma." Não é: a tabela muda de lugar. Num teste à parte, sem arquivo publicado, `target_schema='snapshots'` gravou em `snapshots`. Com `schema: snapshots`, o dbt gravou em `main_snapshots`, porque juntou o schema da conexão, `main` naquele teste. No nosso laboratório, o mesmo arranjo dá `dbt_snapshots`. Como snapshot não se reconstrói, a documentação orienta criar antes uma tabela de backup ("create a backup snapshot table"). Faça a cópia e confira onde a tabela nova nasce antes de agendar.

### 15.6 O dbt como passo de uma Dag

"E quem roda isso às 6h, sem mim?"

**O que é**

A apostila de Orquestração deixou a frase: o orquestrador não é o código de limpeza, é quem roda o código. Aqui ela fica literal. A Dag do Lab 7 não limpa nada. Ela roda o `dbt build`, diz qual é o dia e lê o código de saída.

**Como funciona na prática**

O dbt entra na imagem do Airflow num ambiente virtual do Python (virtualenv), criado na construção da imagem. Critério da mentoria: ambiente próprio, para os pacotes fixados dele não disputarem com os do Airflow.

```dockerfile
FROM apache/airflow:3.3.2-python3.13
# dbt gets its own virtualenv, so its pinned packages never fight the Airflow constraints.
COPY runner/requirements.lock /tmp/dbt-requirements.lock
RUN python -m venv /opt/airflow/dbt-venv \
    && /opt/airflow/dbt-venv/bin/pip install --no-cache-dir -r /tmp/dbt-requirements.lock
```

A tarefa é um `BashOperator`. Dois trechos da Dag, que está inteira em `lab/orquestrador/dags/dbt_rede_de_lojas.py`:

```python
DBT = "/opt/airflow/dbt-venv/bin/dbt"
# target and logs go to /tmp so the run never writes into the mounted project.
FLAGS = "--project-dir /lab/projeto_dbt --target-path /tmp/dbt-target --log-path /tmp/dbt-logs"
```

```python
    BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT} build {FLAGS} --exclude test_type:unit --vars '{{dia_foto: \"{{{{ ds }}}}\"}}'",
    )
```

O `--exclude test_type:unit` segue a recomendação da dbt Labs de rodar teste unitário só em desenvolvimento ou CI. Este projeto não tem teste unitário, e o dbt avisou `does not match any enabled nodes` no Lab 7.

O contrato é o código de saída. A documentação do operador diz: "a non-zero exit code produces an AirflowException and thus a task failure". Vamos provar em três rodadas, com a mesma Dag:

| Rodada | O que aconteceu | Resumo do dbt | Código de saída | DagRun |
|---|---|---|---|---|
| 1 | Dados normais | `PASS=44 WARN=2 ERROR=0 SKIP=0` | 0 | Sucesso |
| 2 | A ingestão duplica os itens do pedido 104 | `PASS=27 WARN=2 ERROR=2 SKIP=15` | 1 | Falha |
| 3 | Bronze refeita | `PASS=44 WARN=2 ERROR=0 SKIP=0` | 0 | Sucesso |

Linhas da segunda rodada:

```text
Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
Command exited with return code 1
airflow.sdk.exceptions.AirflowException: Bash command failed. The command returned a non-zero exit code 1.
DagRun failed
```

> Verificação: nível 3 pela execução, com `docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"`, nível 2 por `dbt parse`. Airflow 3.3.2, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03, em Linux. Saídas em `lab/saidas/lab7_orquestrador_construir_imagem.txt` e `lab/saidas/lab7_orquestrador_roda_dbt.txt`. Linhas filtradas, sem carimbo de hora e sem os campos de log.

Repare em duas coisas. Aviso não derruba a Dag: a rodada 1 tem `WARN=2` e sai com 0. Erro derruba: os testes `unique_stg_itens__pedido_id_item_seq_` e `assert_itens_batem_com_pedido` falham, e 15 nós são pulados. O efeito está medido no Lab 6, com a mesma carga dupla: a gold do dbt mantém 430,90 no dia 20, e o SQL à mão sai com 0 e publica 741,80. O capítulo 13 trata dessa decisão.

**O equívoco comum**

"Se a tarefa falhar, o orquestrador repete, e está resolvido." Repetir só é seguro se der o mesmo resultado, como o Airflow pede da tarefa (seção 14.2). Neste projeto, as tabelas são refeitas, e o snapshot do mesmo dia não cria versão: o `dbt build` do Lab 5, com a foto do dia 22 já registrada, mostra `INSERT 0 0` nos dois snapshots. Modelo incremental pede mais cuidado, e o capítulo 14 mostra por quê.

**O limite desta prova**

Foi `airflow dags test`: uma execução da Dag, sem agendador de pé. A agenda das 6h não foi exercitada. O dia chegou ao comando, que saiu renderizado com `--vars '{dia_foto: "2026-10-22"}'`. Nada rodou em Windows. E, como o snapshot só registra quando roda, a agenda da Dag define o que o histórico enxerga (inferência).

O número é o mesmo, e o orquestrador já sabe rodar. Falta a pergunta que vem antes de instalar qualquer coisa: qual dbt, para o seu banco? O próximo capítulo responde.

## 16. dbt hoje: geração, licença, adaptador e preço

Não decore nome nem número. Decore a pergunta. Os nomes e a licença do dbt mudaram em pouco tempo, e todo número deste capítulo vale para 2026-11-03. Reconfira no dia da sua decisão.

Se você está no SQL à mão, siga: é caminho válido, e o capítulo 19 discute quando subir de degrau. E nenhuma geração decide o que uma linha significa. Isso continua com você.

Critério da mentoria: cinco perguntas, nesta ordem.

| Pergunta | Onde conferir |
|---|---|
| 1. Meu banco tem adaptador em qual geração? | [Tabela de adaptadores do v2](https://docs.getdbt.com/docs/supported-data-platforms) e a página de conexão do banco |
| 2. Quem mantém o adaptador, e quem assume o risco? | Cabeçalho da página de conexão: "Maintained by" e "dbt support" |
| 3. Até quando essa linha tem suporte? | [Página de versões](https://docs.getdbt.com/docs/dbt-versions) e [FAQ de licenças](https://www.getdbt.com/licenses-faq) |
| 4. Preciso de algo que só a plataforma paga entrega? | [Página de preço](https://www.getdbt.com/pricing) |
| 5. Que versões estão travadas, e em que data conferi? | O seu arquivo de versões travadas (lock) |

### 16.1 Quantos dbt existem?

"Vejo dbt Core, dbt v2, `dbt-oss`. Qual é qual?"

**O que é**

São duas gerações. A v1 é a linha 1.x, no pacote `dbt-core`. A v2 é a geração nova, com duas distribuições locais e gratuitas: `dbt`, a completa, e `dbt-oss`, um subconjunto. O nome "dbt Core" não se aplica a nenhuma distribuição do v2. Adaptador é o pacote que liga o dbt a um banco específico.

| | dbt v1 | dbt v2, `dbt` | dbt v2, `dbt-oss` |
|---|---|---|---|
| Versão no PyPI (índice de pacotes do Python) | `dbt-core` 1.12.6 | 2.0.9 | 2.0.11 |
| Licença | Apache 2.0 | Código proprietário sob o dbt Product Licensing Agreement, com uso interno gratuito e sem restrição | Apache 2.0 |
| Exige conta ou plano pago? | Não: o Lab 5 roda local, sem conta | Não, e sem limite de usuários | Não, e sem limite de usuários |
| O que tem | Recursos novos chegam só no v2 | Compreensão de SQL, análise estática, servidor de linguagem (LSP), `dbt lint` e integração com a extensão do VS Code | Nenhum desses cinco recursos |
| Adaptadores | Entre outros, `dbt-postgres`, da dbt Labs, `dbt-sqlserver`, de comunidade, e `dbt-duckdb` | Tabela do v2: Snowflake, BigQuery, Databricks, Redshift e DuckDB disponíveis; Apache Spark em beta; ClickHouse em beta privado | Não conferimos a tabela por distribuição; o DuckDB rodou aqui, embutido, sem adaptador separado |

**O equívoco comum**

"Código proprietário quer dizer pago." Não. A dbt Labs responde "No" a "If I use dbt, do I have to pay dbt Labs anything?". As condições recaem sobre quem redistribui como serviço gerenciado e, para todos, sobre contornar o login da plataforma, derivar o código proprietário e remover avisos de licença. Critério da mentoria: se o dbt vai entrar num produto que você oferece a terceiros, leve o contrato ao jurídico.

> Verificação: nível 3. `dbt-oss` 2.0.11, 2026-11-03: `dbt build` num projeto mínimo à parte, fora do laboratório, sem arquivo publicado, contra um DuckDB local, sem conta, sem login e sem adaptador separado. Resultado: `Summary: 6 total | 6 success`.

### 16.2 O banco escolhe a geração

"Quero começar na geração nova. O que me impede?"

**Como funciona na prática**

O seu banco. A própria dbt Labs diz que, hoje, o principal fator para escolher o v2 é o adaptador ter suporte completo: "Today, the main determinant is whether your adapter is fully supported for your use case".

Postgres e SQL Server não aparecem na tabela do v2. A issue (chamado) `dbt-labs/dbt#13123`, que pede o adaptador de Postgres, segue aberta. No v1, o `dbt-postgres` 1.11.0 é mantido pela dbt Labs, com "dbt support: Supported", e exige `dbt-core<2.0,>=1.8.0rc1`. Postgres com dbt hoje quer dizer v1, e por isso o laboratório roda nessa linha.

Vamos ver o que o v2 responde ao perfil do laboratório:

```text
[error] [InvalidConfig (dbt1005)]: Configuration Error: The 'postgres' adapter is not yet supported by dbt. Supported adapters: snowflake, bigquery, databricks, redshift, duckdb, salesforce, clickhouse. To use an experimental adapter, set the environment variable DBT_ALLOW_EXPERIMENTAL_ADAPTERS=true. Note that experimental adapters may be unstable and are not yet recommended for production use.
```

**O equívoco comum**

"Mas dá para ligar." Dá. Com a variável acima, a `libpq.so.5` do sistema e o snapshot refeito dia a dia, o projeto constrói: `47 total | 44 success | 2 warn | 1 no-op`, e `EXCEPT` 0 e 0 contra o v1 em `vendas_por_dia`, `dim_produto` e `fct_vendas`. Isso prova compatibilidade do projeto, não suporte. A própria mensagem avisa que o modo não é recomendado para produção.

Em outra rodada da mesma sonda, o snapshot começou tarde, só com a foto do dia 22, e as vendas dos dias 20 e 21 ficaram sem versão de preço. Elas foram para o membro desconhecido, e o build saiu com código 0 (`47 total | 43 success | 3 warn | 1 no-op`): quem acusou foi o teste que conta as vendas sem versão, em aviso. Inferência: com o membro, snapshot que começa tarde não para mais o build, e só o aviso mostra.

> Verificação: nível 3. dbt 2.0.9, `postgres:16.15-alpine`, 2026-11-03: `dbt debug`, `dbt parse` e `dbt build` em imagem à parte, com o projeto do laboratório, e `EXCEPT` nos dois sentidos. Saída em `lab/saidas/sonda_dbt_v2_com_postgres.txt`.

### 16.3 Até quando a linha 1.x vale, e quando migrar?

"Se eu ficar no v1, estou comprando um problema?"

**O que é**

Ficar no v1 é caminho suportado ("remains fully supported"), mas recursos novos chegam só no v2. A página de versões diz:

| Versão | Situação em 2026-11-03 |
|---|---|
| v2.0, lançada em 2026-09-14 | Suporte ativo até 2027-09-13 |
| v1.13 | Beta ("coming soon") |
| v1.12, lançada em 2026-07-16 | Suporte ativo até 2027-07-15 |
| v1.11 | Suporte crítico até 2026-12-18 |
| v1.8 a v1.10, v1.1 e v1.2 | Deprecated (depreciada) |
| v1.3 a v1.7 | End of Life (fim de vida), com data de depreciação em 2027-01-31 |

Olhe o material que você tem em mãos contra essa tabela. A versão que ele ensina diz quanto ele envelheceu.

O horizonte não tem data de corte. A dbt Labs declara que a 1.13 será a última versão menor da linha 1.x, com suporte crítico (segurança e instalação) além da janela normal de um ano, e que espera de 3 a 5 anos. Critério da mentoria: trate isso como expectativa, não como prazo. Reabra a conta quando a 1.13 sair e quando o seu adaptador aparecer na tabela do v2.

**Como funciona na prática**

Para migrar, as páginas da dbt Labs pedem adaptador e autenticação suportados e o projeto rodando na última versão do v1 sem avisos de depreciação nem erros. Os avisos se resolvem antes, com o `dbt-autofix` para os que se corrigem automaticamente. Na 1.12, teste o projeto com a opção `--use-v2-parser`, que só vale se você ligar. Nada disso foi executado aqui. O capítulo 15 mostra a sintaxe que separa as gerações.

### 16.4 A fusão e os nomes: o que muda para quem decide?

"Teve fusão com a Fivetran. Isso mexe na minha decisão?"

**O que é**

A fusão da Fivetran com a dbt Labs foi concluída em 2026-06-01, por troca de ações, depois de anunciada em 2025-10-13. No FAQ de licenças, a empresa combinada se compromete a manter o `dbt-oss` sob Apache 2.0 por tempo indeterminado. O compromisso está no FAQ, não no comunicado da fusão. O histórico do mesmo FAQ mostra o movimento:

| Data | Registro |
|---|---|
| 2025-05-28 | Publicação original, no lançamento do Fusion, então sob ELv2 |
| 2026-06-01 | Saem as referências a ELv2; o código do Fusion passa a Apache 2.0; o binário ganha contrato próprio |
| 2026-09-15 | "dbt Fusion engine" e "dbt Core v2" viram `dbt` e `dbt OSS` |

São três mudanças em 16 meses, na contagem da mentoria. Material que fala em "Fusion" ou "dbt Core 2.0" está desatualizado.

**O equívoco comum**

"A fusão decide por mim." Inferência: ela não muda o que o seu banco aceita hoje. O efeito prático é outro: decisão sem data envelhece rápido, porque nome e licença já mudaram. O SQL que você escreveu segue seu.

Existe alternativa aberta? O SQLMesh é Apache 2.0, projeto da Linux Foundation, ainda na série 0.x (0.236.4 em 2026-10-22). Lista Postgres, DuckDB e MSSQL entre os motores e hoje exige `duckdb` abaixo de 2. A Tobiko Data, criadora dele, foi comprada pela Fivetran em 2025-09-03. Nós não o executamos.

### 16.5 Preciso pagar a plataforma?

"Para usar dbt, tenho que contratar a plataforma?"

**O que é**

Para rodar, não, nas duas gerações. A plataforma é outra decisão. Preço público consultado em 2026-11-03. Reconfira antes de decidir.

| Plano | Preço | O que a página lista |
|---|---|---|
| Developer | Grátis | 1 assento, 1 projeto, 3.000 modelos com sucesso por mês, sem linhagem listada |
| Starter | US$ 100 por usuário por mês | 5 assentos, 15.000 modelos com sucesso por mês, "Lineage with dbt Catalog" |
| Enterprise e Enterprise+ | Sob consulta | Linhagem por coluna no Catalog, que só aparece nesses dois |

O dbt State exige login e é cobrado por uso.

**Como funciona na prática**

Veja primeiro o que já é grátis. No v1, `dbt docs generate` roda local e sem conta. No v2, os docs v2 (lite ou full) são marcados como gratuitos para sempre e servidos localmente, e o modo full traz linhagem por coluna, visível ao compilar com `--static-analysis strict`. Inferência: quem está em Postgres ou SQL Server fica no v1 e não alcança isso hoje, e o `dbt-oss` não traz análise estática.

Critério da mentoria: comece sem plataforma. Pague quando houver um pedido concreto que a tabela cubra, como mais pessoas precisando da linhagem no Catalog. Antes, pergunte se o plano conecta ao seu banco: isso não foi conferido aqui.

### 16.6 Fixe a versão: o ambiente muda em dias

"Instalei igual ao colega e deu diferente. Como?"

**Como funciona na prática**

Um pacote traz outros junto, e esses não ficam parados. O lock é o arquivo com a versão exata de cada pacote. O do laboratório, `lab/runner/requirements.lock`, é de 2026-11-01, sai de dois pinos (versões fixadas à mão) e tem `dbt-core-experimental-parser==2.0.8`. Resolvendo os mesmos dois pinos sem o lock, em 2026-11-03 e outra vez em 2026-11-04, `dbt-core` e `dbt-postgres` ficam em 1.12.6 e 1.11.0, e o `dbt-core-experimental-parser` sai 2.0.11:

```bash
uv pip compile runner/requirements.in --python-version 3.13 --no-header --no-annotate -q | grep -E "^(dbt-core|dbt-postgres|dbt-adapters|dbt-core-experimental-parser)=="
```

```text
dbt-adapters==1.24.5
dbt-core==1.12.6
dbt-core-experimental-parser==2.0.11
dbt-postgres==1.11.0
```

> Verificação: nível 2, resolução sem instalar. uv 0.11.13, Python 3.13, 2026-11-04. Saída em `lab/saidas/cap16_resolucao_sem_lock.txt`.

Os pinos ficaram. O pacote que veio junto andou em dois dias.

**O equívoco comum**

"Deixo sem versão e pego sempre a estável." Hoje, `dbt-core` sem versão entrega a 1.12.6, porque a 2.0.0rc10 é pré-lançamento. Mas a dbt Labs diz que, por ora, `pip install dbt-core` continua funcionando e instalará o `dbt-oss`, e o README da 2.0.0rc10 avisa que o nome `dbt-core` no PyPI será descontinuado a longo prazo. Inferência: sem versão, o mesmo comando pode trocar de geração no dia em que a estável mudar. Escreva o pino, gere o lock, versione o lock.

### 16.7 Nota: não seria mais leve com DuckDB?

"Por que não DuckDB, que parece mais leve?"

**O equívoco comum**

Em memória, não é. Medido em 2026-11-03, num host Linux de 14 CPUs e 31 GB: Postgres parado com 31 a 41 MiB e pico do processo do dbt entre 112 e 151 MiB, contra pico do dbt com DuckDB entre 186 e 202 MiB. A ordem de grandeza é firme, e as faixas variam por rodada. Não houve teste em máquina de 8 GB nem em Windows.

> Verificação: nível 3. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `dbt-duckdb` 1.11.1, 2026-11-03: `docker stats` e o relatório de recursos do log do dbt. Saídas em `lab/saidas/recursos_medidos.txt` e `lab/saidas/alternativa_duckdb.txt`.

O DuckDB tem adaptador nas duas gerações: `dbt-duckdb` 1.11.1 no v1 e embutido no v2, só na linha de comando (CLI), com driver que não carrega extensões. O risco é o arquivo. O `dbt-duckdb` declara `duckdb>=1.0.0` sem teto e resolve o 2.0.0, lançado em 2026-10-21, com suporte longo até ao menos outubro de 2027; a 1.5 tem suporte até março de 2027. Arquivo criado pela 2.0 não abre na 1.5.6:

```text
duckdb py 1.5.6
ERRO IOException IO Error: Trying to read a database file with version number 69, but we can only read versions between 64 and 68.
```

> Verificação: nível 3. `dbt-duckdb` 1.11.1, `duckdb` 2.0.0 e 1.5.6, 2026-11-03: `dbt build` num projeto mínimo à parte, fora do laboratório, sem arquivo publicado (`PASS=6 WARN=0`), e abertura do arquivo pelo pacote `duckdb` em Python.

Critério da mentoria: o DuckDB fica como nota, e o laboratório segue em Postgres, por continuidade.

### 16.8 "Meu banco é SQL Server. Qual dbt eu uso?"

**Como funciona na prática**

Aplique as cinco perguntas, na ordem. A preferência não entra antes do adaptador.

1. **Banco.** SQL Server não aparece na tabela do v2. Logo, dbt v1 com `dbt-sqlserver`, que exige `dbt-core<2.0,>=1.12.0`.
2. **Quem mantém.** A página diz "Maintained by: Community" e "dbt support: Not Supported", e avisa: "Some core functionality may be limited". A licença é MIT, e o piso é SQL Server 2016. Esse é o risco.
3. **Horizonte.** Sem data de corte, como na seção 16.3.
4. **Plataforma.** Comece sem, e confirme antes se ela conecta ao seu banco.
5. **Versões.** Trave no lock.

A documentação do adaptador lista limites. Ele não suporta a materialização `ephemeral` (pode funcionar em casos simples; T-SQL não aceita CTE aninhada). Cria tabela em armazenamento por coluna (columnstore) por padrão, o que exige SQL Server 2017 ou mais novo em servidor próprio. E não aceita restrições nas colunas das tabelas de origem de snapshot. Inferência: num SQL Server 2016 próprio, o piso passa e o padrão de tabela não.

```text
$ printf 'dbt-core==1.12.6\ndbt-sqlserver[pyodbc]\n' | uv pip compile - --python-version 3.13 --no-header --no-annotate -q | grep -E '^(dbt-core|dbt-sqlserver|dbt-adapters|pyodbc)=='
dbt-adapters==1.24.5
dbt-core==1.12.6
dbt-sqlserver==1.12.2
pyodbc==5.3.0
```

> Verificação: nível 2, resolução sem instalar. uv 0.11.13, Python 3.13, 2026-11-03. Saída em `lab/sqlserver/saidas/dbt_sqlserver_resolucao.txt`.

A 1.12.2 saiu no mesmo dia da consulta; mais cedo, a resolução dava 1.12.1. O `pyodbc` só vem com o extra `[pyodbc]`, e há também o extra `mssql`, com outro driver. O lock vale mais que o número daqui.

**O limite desta apostila**

`dbt debug` e `dbt run` contra SQL Server não foram executados. O adaptador ficou só em resolução, e o T-SQL do capítulo 17 rodou direto no banco. Nada rodou em Windows. E não conhecemos a versão, a edição nem a collation (regra do banco para ordenar e comparar texto) do seu banco.

**O risco fica por escrito**

Critério da mentoria: antes de adotar, registre uma página com estes campos.

| Campo | Exemplo |
|---|---|
| Decisão e data | dbt v1 com `dbt-sqlserver`, conferido em AAAA-MM-DD, versões no lock |
| Risco aceito | Adaptador de comunidade, sem suporte da dbt Labs, com funcionalidade que pode ser limitada |
| Prova | `dbt debug` e `dbt run` num banco de teste, com a sua versão e a sua collation |
| Dono | Quem acompanha o adaptador e atualiza o lock |
| Saída | Se o adaptador travar, views e scripts T-SQL versionados seguem de pé |
| Quando reabrir | SQL Server na tabela do v2, ou a 1.13 publicada |

Se o risco não couber, não adote agora. SQL versionado continua caminho válido.

Com adaptador ou sem ele, o SQL é seu. No próximo capítulo, a silver e a gold vão para T-SQL, direto no banco, e vamos ver onde o comportamento muda.

## 17. SQL Server: a silver e a gold em T-SQL

"Meu ERP roda em SQL Server. O que vimos em Postgres vale para mim?" O raciocínio vale inteiro: antes do SQL, decida o que uma linha significa. A escrita muda, e este capítulo mostra onde. T-SQL é o dialeto SQL do SQL Server.

Comece pelo resultado. Os mesmos tratamentos da silver e da gold, em T-SQL, dão os números do laboratório em Postgres: **32 de 32 linhas batem**, na 2022, na 2025 Enterprise Developer e na 2025 Standard Developer. Entre a 2022 e a 2025, nenhum número muda.

```text
item|postgres|sql_server|resultado
----|--------|----------|---------
gold.dim_produto, linhas|8.00|8.00|bate
gold.dim_produto, membro -1|1.00|1.00|bate
gold.fct_vendas, vendas no membro -1|.00|.00|bate
receita paga, dia 20|430.90|430.90|bate
receita paga, dia 21|111.90|111.90|bate
receita paga, dia 22|293.30|293.30|bate
receita paga, total|836.10|836.10|bate
fan-out 1, receita dobrada|850.90|850.90|bate
```

> Verificação: nível 3. `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04` e `2025-CU10-ubuntu-24.04`, 2026-11-03: `ACCEPT_EULA=Y ./roteiro.sh 2022` e `ACCEPT_EULA=Y ./roteiro.sh 2025`, depois com `MSSQL_PID=StandardDeveloper`. Trecho, 8 das 32 linhas, de `lab/sqlserver/saidas/2022/lab5_conferencia_postgres.txt`; igual em `lab/sqlserver/saidas/2025/lab5_conferencia_postgres.txt` e, com `StandardDeveloper`, em `lab/sqlserver/saidas/diferencas_2025_enterprise_standard.txt`.

Bater não quer dizer que os dois bancos se comportam igual. Quer dizer que o SQL foi ajustado onde eles diferem. É o que o Lab 8 mostra, com um ERP fictício e a silver num banco próprio. O banco `erp` faz o papel da réplica. O `dw` guarda bronze, silver e gold e lê o `erp` por sinônimos. Os dois ficam na mesma instância, sem grupo de disponibilidade: o `erp` é um banco comum, não uma réplica de verdade.

Tudo rodou em Linux, em contêiner, e nada em Windows. Quando o texto disser "prova à parte", o caso rodou em nível 3, em 2026-11-03, nas imagens de SQL Server deste capítulo ou em Postgres 16.15, fora do roteiro do laboratório e sem captura publicada.

### 17.1 Licença e contêiner: leia antes de subir

"Posso subir um SQL Server na minha máquina sem pagar?" Para desenvolver e testar, pode. Leia os termos antes.

**O que os termos dizem**

A edição Developer pode ser instalada e usada em qualquer dispositivo para projetar, desenvolver, testar e demonstrar programas. Não pode ser usada em produção. Na 2025, ela se divide em Enterprise Developer e Standard Developer, e só a primeira tem tudo. Os termos não citam contêiner. A Microsoft publica a imagem com Developer no registro e documenta como rodá-la. Esta é uma leitura factual dos termos, não um parecer jurídico.

Inferência: a silver que vai para produção não fica em Developer. A Express existe, mas não tem SQL Server Agent e limita o banco a 10 GB na 2022 e a 50 GB na 2025.

A seção 5 dos termos, na 2022 e na 2025, exige aprovação prévia por escrito da Microsoft para divulgar a terceiros o resultado de qualquer teste de desempenho (benchmark). Por isso este capítulo não traz duração, memória nem comparação de desempenho, e as capturas levam só a data.

**Como funciona na prática**

O `docker-compose.yaml` não traz o aceite. Quem roda aceita na linha de comando:

```bash
./preparar.sh                    # generates .env with a random sa password
ACCEPT_EULA=Y ./roteiro.sh 2022  # runs everything from an empty volume, then takes the project down
ACCEPT_EULA=Y ./roteiro.sh 2025  # same script on 2025
```

> Verificação: nível 3. Mesmas imagens, 2026-11-03. Capturas em `lab/sqlserver/saidas/2022/` e `lab/sqlserver/saidas/2025/`.

A trava do Compose só barra a variável vazia ou ausente. E a imagem aceita qualquer valor: em prova à parte, na imagem da 2022, subiu com `N`, com um texto qualquer e com `1`. Nem a trava nem o contêiner de pé provam que alguém leu. Passar `Y` com uma edição em `MSSQL_PID` declara ter licença válida para aquela edição e versão.

Os links de licença das páginas oficiais não levam ao termo da versão. Use os PDFs listados nas fontes.

A tabela de `MSSQL_PID` da 2025 traz `EnterpriseDeveloper` e `StandardDeveloper`, sem `Developer`, e o exemplo de Docker da mesma página passa `Developer`. Na execução, `Developer` e `EnterpriseDeveloper` subiram Enterprise Developer, e `StandardDeveloper`, Standard Developer (`./edicoes_2025.sh`, saída em `lab/sqlserver/saidas/2025/lab0_edicoes.txt`).

**O equívoco comum**

Procure o `sqlcmd` em `/opt/mssql-tools18/bin`. Nas imagens testadas, `/opt/mssql-tools/bin` não existe (prova à parte). Sem `-C`, ele recusa o certificado autoassinado do contêiner e sai com 1:

```text
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : SSL Provider: [error:0A000086:SSL routines::certificate verify failed:self-signed certificate].
```

> Verificação: nível 3. Mesmas imagens, 2026-11-03. Primeira das duas linhas de erro, copiada de `lab/sqlserver/saidas/2022/lab0_ambiente.txt`; igual em `lab/sqlserver/saidas/2025/lab0_ambiente.txt`.

Com `-C` e a senha na variável `SQLCMDPASSWORD`, sai com 0. A documentação chama `-P` de inseguro, e o laboratório não o usa.

### 17.2 O mesmo tratamento nos dois dialetos

"O que eu troco, linha a linha?" A tabela sai das duas silver e das duas gold do laboratório. A última coluna diz o que olhar.

| Tratamento | Postgres | T-SQL | O que olhar |
|---|---|---|---|
| Espaço | `trim(nome)` | `TRIM(nome)` | Sem lista, só tira `char(32)`. Seção 17.3 |
| Iniciais e acento | `initcap(unaccent(trim(cidade)))` | `silver.iniciais(silver.sem_acento(TRIM(cidade)))` | Funções do laboratório, não há nativas. Seção 17.3 |
| Texto literal | `'Não informado'` | `N'Não informado'` | Sem `N`, passa pela página de código. Seção 17.3 |
| Data em texto | `to_date(emissao_texto, 'DD/MM/YYYY')` | `TRY_CONVERT(date, NULLIF(TRIM(emissao_texto), N''), 103)` | Inválida vira `NULL`. Sem o `NULLIF`, vazio vira 1900-01-01, e só tab passa mesmo com ele. Seção 17.4 |
| Fuso | `AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'` | `AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time'` | O nome do fuso. Seção 17.5 |
| Nulo | `COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado')` | `COALESCE(NULLIF(silver.iniciais(TRIM(cliente)), N''), N'Não informado')` | `ISNULL` trunca. Seção 17.6 |
| Regra de negócio | `CASE lower(trim(status)) ... ELSE 'desconhecido' END` | `CASE LOWER(TRIM(status)) ... ELSE N'desconhecido' END` | Sem `ELSE`, devolve `NULL`. Seção 17.6 |
| Duplicata | `row_number()` em CTE, ou `DISTINCT ON (id)` | `ROW_NUMBER()` em CTE | Não há `DISTINCT ON`. Seção 17.7 |
| Tabela nova | `CREATE TABLE silver.itens AS SELECT ...` | `SELECT ... INTO silver.itens FROM ...` | Entra em transação. Seção 17.8 |
| Chave em hash | `md5(loja_id::text)` | `CONVERT(char(64), HASHBYTES('SHA2_256', CONVERT(varchar(20), loja_id)), 2)` | O valor da chave difere. Seção 17.9 |

> Verificação: nível 3 nos dois lados. `lab/sql/20_silver.sql`, `lab/sql/30_gold.sql`, `lab/sqlserver/sql/20_silver.sql` e `lab/sqlserver/sql/30_gold.sql`, em Postgres 16.15 e nas imagens acima, 2026-11-03. Execução capturada em `lab/saidas/lab1_silver_a_mao.txt` e `lab/saidas/lab3_gold_estrela_e_fan_out.txt` e, em T-SQL, por `./sq.sh dw 20_silver.sql -b` e `./sq.sh dw 30_gold.sql -b`, em `lab1_silver_a_mao.txt` e `lab3_gold_estrela_e_fan_out.txt` de `lab/sqlserver/saidas/2022/` e de `lab/sqlserver/saidas/2025/`. Reticências marcam o corte na tabela.

### 17.3 Texto: o mesmo SQL pode esconder a sujeira

"Por que o meu `DISTINCT` deu 2 categorias, se no dado eu vejo 4?"

**Como funciona na prática**

Rode:

```sql
CREATE TABLE #categorias (categoria nvarchar(30));
INSERT INTO #categorias VALUES (N'Papelaria'), (N'PAPELARIA'), (N'papelaria '), (N'Papelária');

SELECT DISTINCT categoria AS distinct_padrao FROM #categorias;
```

```text
distinct_padrao
---------------
Papelaria
Papelária

(2 rows affected)
```

> Verificação: nível 3. Imagem da 2022, 2026-11-04: `./sq.sh dw 60_texto_e_collation.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`; igual na 2025. A contagem de 4 no Postgres 16 está em `lab/sqlserver/saidas/postgres_contraprova.txt`.

O Postgres dá 4 linhas. Vamos ver o que juntou aqui. São duas regras.

A primeira é a collation, a regra do banco para ordenar e comparar texto. Sem `MSSQL_COLLATION`, a do contêiner é `SQL_Latin1_General_CP1_CI_AS`: insensível a caixa e sensível a acento. Ela junta `Papelaria` e `PAPELARIA`, e sobra `Papelária`.

A segunda é o preenchimento do SQL-92, que ignora o espaço à direita e não depende da collation. Sob `Latin1_General_100_BIN2`, `N'papelaria'` e `N'papelaria '` ainda viram uma linha só (prova à parte).

Leitura da mentoria: o mesmo SQL pode ser limpo em um banco e esconder sujeira no outro. No Postgres, as 4 linhas denunciam o problema. Aqui, a contagem parece boa antes de você limpar qualquer coisa. E a comparação engana igual: no laboratório, `CASE bruto WHEN N'pago'` casa `PAGO` e `pago `, e não casa ` Pago `, com espaço à esquerda (`lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`).

Critério da mentoria: `DISTINCT` não prova que o texto está padronizado. Limpe mesmo onde a collation já junta, porque ela muda a comparação, não o valor gravado.

**Como inspecionar**

Rode no seu banco antes de escrever a silver:

```sql
SELECT CAST(SERVERPROPERTY('Collation') AS nvarchar(128)) AS servidor,
       CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS nvarchar(128)) AS banco,
       UNICODE(N'ã') AS unicode_de_a_til;
```

> Verificação: nível 3. Imagem da 2022, 2026-11-04: primeira consulta de `./sq.sh dw 60_texto_e_collation.sql`, em `lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`; igual em `lab/sqlserver/saidas/2025/lab6_texto_e_collation.txt`. O contêiner devolve `SQL_Latin1_General_CP1_CI_AS` nas duas colunas e 227 na terceira. O seu banco pode ter outra collation.

**O que mais muda no texto**

- **`TRIM` sem lista só tira `char(32)`.** Tab e espaço duro (`NCHAR(160)`) ficam: `LEN` dá 3 em `x` cercado por eles, e com lista de caracteres dá 1. `TRIM` existe a partir da 2017. `LEADING` e `TRAILING` pedem 2022 com compatibilidade 160.
- **Espaço à direita é ignorado em `=` e em `LEN`, e conta em `DATALENGTH`.** Só vale para `char(32)`: tab e espaço duro à direita mudam `LEN` e deixam o `=` diferente (prova à parte). No Postgres, `'abc' = 'abc   '` é falso em `text` (`lab/sqlserver/saidas/postgres_contraprova.txt`).
- **`varchar` troca caractere por `?` sem erro.** Com collation de página de código legada, o que não cabe nela vira `?`: `São João` seguido da letra cirílica `Ж` sai `São João ?`. A documentação avisa que essa perda não é reportada. Com collation `_UTF8`, da 2019 em diante, `varchar` guarda o caractere. O laboratório usa `nvarchar` e literal com `N`.
- **Collation compara ignorando acento, mas não remove.** `N'São Paulo' COLLATE Latin1_General_100_CI_AI` continua `São Paulo`.
- **`INITCAP` e `unaccent` não existem**, na 2022 nem na 2025: erro 195. O laboratório traz duas funções próprias, com o mesmo resultado do Postgres nestes dados. "Nestes dados" é limite real: `silver.sem_acento` deixa `Ñandu Ýdalir` intacto, onde `unaccent` dá `Nandu Ydalir`, e `silver.iniciais` dá `Caixa-d'água`, onde `initcap` dá `Caixa-D'Água` (prova à parte). Confira com o seu texto antes de adotar.

A forma documentada de trocar caractere é `TRANSLATE`, a partir da 2017:

```sql
-- T-SQL has no unaccent. The binary collation matters: under a case-insensitive collation
-- TRANSLATE would map an uppercase accented letter to the first lowercase match.
CREATE OR ALTER FUNCTION silver.sem_acento (@texto nvarchar(200))
RETURNS nvarchar(200)
AS
BEGIN
    RETURN TRANSLATE(@texto COLLATE Latin1_General_100_BIN2,
                     N'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                     N'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC');
END;
```

> Verificação: nível 3. Imagens da 2022 e da 2025, 2026-11-03: `./sq.sh dw 20_silver.sql -b`, com o arquivo em `lab/sqlserver/sql/20_silver.sql`. Execução capturada em `lab/sqlserver/saidas/2022/lab1_silver_a_mao.txt` e `lab/sqlserver/saidas/2025/lab1_silver_a_mao.txt`.

Por que `BIN2`? No padrão insensível a caixa, `TRANSLATE(N'Álvaro São João', N'áãÁÃ', N'aaAA')` devolve `alvaro Sao Joao`: o `Á` virou minúsculo. Com `COLLATE Latin1_General_100_BIN2`, devolve `Alvaro Sao Joao`. A página de `TRANSLATE` só diz "always SC collation aware", então isso é comportamento observado, não documentado. Listas de tamanhos diferentes dão erro, o 9828, número que vem da execução.

> Verificação: nível 3. Imagem da 2022, 2026-11-04: `./sq.sh dw 60_texto_e_collation.sql`. Valores desta seção, fora os de prova à parte, em `lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`; igual em `lab/sqlserver/saidas/2025/lab6_texto_e_collation.txt`.

As 32 linhas não exercitam essa collation, porque nenhuma maiúscula acentuada passa pela função nesses dados. Quem testa é a etapa de texto e collation do Lab 8.

**Duas collations no mesmo JOIN**

Comparar duas colunas de collations diferentes é erro 468:

```text
Cannot resolve the collation conflict between "SQL_Latin1_General_CP1_CI_AS" and "Latin1_General_CI_AS" in the equal to operation.
```

> Verificação: nível 3. Imagem da 2022, 2026-11-04, `lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`. O número 468 vem da execução: a página de `COLLATE` não fala de conflito.

`COLLATE` na expressão resolve, como em `ON #a.c = #b.c COLLATE Latin1_General_CI_AS`. Coluna contra literal não dá erro (prova à parte). Inferência: esse erro é o que se espera ao juntar um ERP com um banco novo em outra collation. Critério da mentoria: leia a collation do ERP antes de criar o banco da silver, e decida de propósito.

### 17.4 Data: a carga que não aborta

"Uma data inválida derruba a carga?" Com `TRY_CONVERT`, não. É a vantagem, e é o risco.

**Como funciona na prática**

`TRY_CONVERT` com estilo 103, dia/mês/ano, devolve `NULL` em data inválida: `N'31/02/2026'` vira nulo, onde `CONVERT` dá erro 241. A carga segue, e quem não conta perde a linha em silêncio. Conte o texto que virou nulo.

Três surpresas:

- **Não salva conversão proibida.** Inteiro para `date` é erro 529. Inteiro para `datetime` é permitido, e `TRY_CONVERT(datetime, 46000)` devolve 2025-12-11 sem erro (prova à parte).
- **O estilo 103 não valida o formato.** Aceita `'20261020'`, `'20-10-2026'`, `'20.10.2026'` e `'Oct 20 2026'`. Dá `NULL` em `'20/10/26'` e `'2026-10-20'`, então ano de dois dígitos cai no mesmo nulo calado da data inválida (prova à parte).
- **Texto vazio não vira `NULL`.** Em `date` dá 1900-01-01, em `int` dá 0, e só em `numeric` dá `NULL`. A documentação registra o caso só para `numeric` e `decimal`. Em `date` e `int`, é comportamento observado.

A silver usa `NULLIF(TRIM(x), N'')` por causa disso. Cobre vazio e espaços. Não cobre tab:

```sql
SELECT caso,
       TRY_CONVERT(date, NULLIF(TRIM(texto), N''), 103) AS nullif_trim,
       TRY_CONVERT(date, NULLIF(TRIM(NCHAR(9) + NCHAR(160) + N' ' FROM texto), N''), 103) AS trim_com_lista
FROM (VALUES (1, N'vazio', N''),
             (2, N'espacos', N'   '),
             (3, N'tab', NCHAR(9)),
             (4, N'tab_e_espaco', NCHAR(9) + N' '),
             (5, N'espaco_duro', NCHAR(160)),
             (6, N'valor_real', N'20/10/2026'),
             (7, N'valor_real_com_tab', NCHAR(9) + N'20/10/2026' + NCHAR(160))) AS casos(ordem, caso, texto)
ORDER BY ordem;
```

```text
caso|nullif_trim|trim_com_lista
----|-----------|--------------
vazio|NULL|NULL
espacos|NULL|NULL
tab|1900-01-01|NULL
tab_e_espaco|1900-01-01|NULL
espaco_duro|NULL|NULL
valor_real|2026-10-20|2026-10-20
valor_real_com_tab|NULL|2026-10-20
```

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 69_datas_com_tab.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab15_datas_com_tab.txt`; igual em `lab/sqlserver/saidas/2025/lab15_datas_com_tab.txt`. Os outros valores desta seção, fora os de prova à parte, saem de `./sq.sh dw 61_datas_em_texto.sql`, em `lab/sqlserver/saidas/2022/lab7_datas_em_texto.txt`.

Os dados do laboratório não têm tab, por isso a silver dele usa a forma curta. Os seus podem ter. Critério da mentoria: se a origem aceita texto digitado à mão, use `TRIM` com lista, e trate 1900-01-01 na silver como sintoma.

**O equívoco comum**

"Meu `CAST` funciona aqui." Sem estilo, data em texto depende da sessão. `'02/03/2026'` dá 3 de fevereiro em `mdy`, padrão do `us_english`, e 2 de março em `dmy` ou com `SET LANGUAGE Brazilian`, sem erro. Sob `dmy`, `'2026-02-03'` é 3 de fevereiro em `date` e `datetime2`, e 2 de março em `datetime`.

Com estilo explícito e data só em números, a sessão não interfere. Mês por extenso segue o idioma: com estilo 103, `'Oct 20 2026'` dá 2026-10-20 em `us_english` e `NULL` em `Brazilian` (prova à parte). Critério da mentoria: estilo explícito e tipo `date`.

### 17.5 Fuso: o nome muda, a armadilha não

"`America/Sao_Paulo` funciona aqui?" Não. Nem `-03:00`: os dois dão erro 9820.

**O que é**

Os nomes de fuso em T-SQL são os do Windows, não os da IANA, e ficam listados em `sys.time_zone_info`, também no contêiner Linux. O de Brasília é `E. South America Standard Time`, e a documentação de fuso no Linux mapeia `America/Sao_Paulo` para ele. Nenhum nome da lista tem barra. Cruzada com os nomes do Postgres, só `UTC` coincide (prova à parte).

`AT TIME ZONE` em `datetime` ou `datetime2` supõe que o valor já está no fuso pedido e só aplica o deslocamento. Em `datetimeoffset`, converte. Por isso, de UTC para Brasília, encadeie os dois.

**Como funciona na prática**

```sql
SELECT x AS origem_utc,
       CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS certo,
       x AT TIME ZONE N'E. South America Standard Time' AT TIME ZONE N'UTC' AS direcao_errada_em_utc,
       CAST(CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0))
            AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS convertido_duas_vezes,
       CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time'
            AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS repetido_sem_perder_o_deslocamento
FROM (VALUES (CAST('2026-10-21 00:30' AS datetime2(0)))) AS t(x);
```

```text
origem_utc|certo|direcao_errada_em_utc|convertido_duas_vezes|repetido_sem_perder_o_deslocamento
----------|-----|---------------------|---------------------|----------------------------------
2026-10-21 00:30:00|2026-10-20 21:30:00|2026-10-21 03:30:00 +00:00|2026-10-20 18:30:00|2026-10-20 21:30:00
```

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 22_fuso.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab2_fuso_e_datas.txt`; na 2025, muda só a contagem de zonas, de 141 para 144.

O certo é 21:30 do dia 20, e o atendimento muda de dia. A direção errada dá 03:30 UTC. A conversão dupla dá 18:30. São os mesmos valores do laboratório em Postgres. A última coluna mostra o detalhe: a conversão dupla só aparece quando o deslocamento se perde no meio.

**O equívoco comum**

"Então eu subtraio 3 horas." Não. Com o nome, o deslocamento é -2 h em 2018-12-01, com horário de verão, e -3 h em 2019-12-01 e em 2026-12-01. Bate com o Postgres.

Hora local em troca de horário segue a regra da documentação: 2018-11-04 00:30, que não existiu, vira 01:30 -02:00, e aí a hora muda. Já 2019-02-16 23:30, que existiu duas vezes, fica com -02:00. De hora local para UTC na hora repetida, os motores divergem: 01:30 UTC no T-SQL e 02:30 UTC no Postgres (prova à parte). Conversão por instante, em `datetimeoffset`, separa as duas 23:30. Se o seu histórico atravessa essas datas, converta por instante.

### 17.6 Nulo: `ISNULL` trunca

"`ISNULL` e `COALESCE` não fazem a mesma coisa?" Não.

```sql
DECLARE @curto varchar(2) = NULL;
SELECT ISNULL(@curto, 'desconhecido') AS com_isnull, COALESCE(@curto, 'desconhecido') AS com_coalesce;
```

```text
com_isnull|com_coalesce
----------|------------
de|desconhecido
```

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 62_nulos.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab8_nulos.txt`; igual na 2025.

`ISNULL` usa o tipo do primeiro argumento e corta o rótulo, sem erro. `COALESCE` usa o tipo de maior precedência. Três cuidados ficam, além do critério do capítulo 7:

- **Tipo misturado quebra tarde.** `COALESCE` de `int` com texto dá erro 245 quando o valor chega à conversão. `COALESCE(CAST(1 AS int), N'desconhecido')` devolve 1 sem erro (prova à parte). A carga passa no teste e quebra quando aparece o nulo.
- **`CASE` sem `ELSE` devolve `NULL`.** No laboratório, `estornado` sai `NULL` sem `ELSE` e `desconhecido` com ele (`lab/sqlserver/saidas/2022/lab8_nulos.txt`).
- **`UNIQUE` aceita um só nulo por coluna**, ao contrário do Postgres, e a mesma DDL se comporta diferente com chave nula. Em chave composta, a regra vale para a combinação. Isso vem da documentação, nível 1, sem execução aqui.

### 17.7 Duplicata: sem `DISTINCT ON` nem `QUALIFY`

"Como deixo uma linha por chave?" Escreva o grão primeiro: uma linha é um item de pedido, com a chave `pedido_id` e `item_seq`. Depois numere e filtre por fora:

```sql
WITH ultima_carga AS (
    SELECT pedido_id, item_seq, quantidade, preco_unitario,
           ROW_NUMBER() OVER (PARTITION BY pedido_id, item_seq ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.itens_pedido
)
SELECT pedido_id, COUNT(*) AS linhas, SUM(quantidade * preco_unitario) AS soma
FROM ultima_carga
WHERE ordem = 1 AND pedido_id = 104
GROUP BY pedido_id;
```

```text
pedido_id|linhas|soma
---------|------|----
104|2|310.90
```

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 63_dedup.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab9_dedup.txt`; igual na 2025.

Sem deduplicar, a carga dupla do pedido 104 soma 621,80. Com `ROW_NUMBER`, 310,90. O que não passa: `DISTINCT ON` é erro 156. `QUALIFY` é erro 102, e a documentação o restringe ao Fabric Data Warehouse. `ROW_NUMBER` no `WHERE` é erro 4108. Tabela derivada e `SELECT TOP (1) WITH TIES ... ORDER BY ROW_NUMBER() OVER (...)` dão o mesmo (prova à parte).

**O equívoco comum**

"Ordenei por data, a escolha é estável." Só sem empate. `ROW_NUMBER` é não determinístico quando o `ORDER BY` empata. O laboratório não exercita isso, porque a carga dupla tem 2 instantes distintos. Milissegundos não evitam empate dentro de uma carga: na bronze do laboratório principal, em Postgres, as 13 linhas de `itens_pedido`, gravadas num só `INSERT`, têm um só `_carregado_em` (seção 6.5). Critério da mentoria: chave repetida no mesmo lote pede coluna de desempate.

### 17.8 Recarga segura

"Se a recarga falhar no meio, o que sobra da silver?" Depende de como você escreve e de como você chama.

**`MERGE`: chave repetida no lote**

| Caso, com a chave repetida no lote | Resultado |
|---|---|
| Já existe no alvo, e `WHEN MATCHED` atualiza a mesma linha duas vezes | Erro 8672 |
| Nova, com `PRIMARY KEY` no alvo | Erro 2627 |
| Nova, com `UNIQUE INDEX` no alvo | Erro 2601 (prova à parte) |
| Nova, sem chave no alvo | Grava as duas, sem erro |
| Já existe, sem `WHEN MATCHED`, ou com condição que deixa passar uma linha | Sem erro (prova à parte) |

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 64a_merge_chave_repetida.sql`. Saída em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`; igual na 2025.

Ou seja, o resultado depende do alvo e da cláusula, no mesmo padrão do Postgres (capítulo 14). Sem ponto e vírgula no fim, é erro 10713. O conserto é deduplicar a fonte antes, no próprio grão, com a CTE da seção 17.7 na frente do `MERGE`. O arquivo do laboratório traz essa forma (`lab/sqlserver/sql/64a_merge_chave_repetida.sql`, saída em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`).

A documentação do `MERGE` avisa: em escala, ele pode trazer problemas complicados de concorrência, e pede teste completo antes de produção. Filtrar o alvo no `ON` pode dar resultado errado. E `INSERT`, `UPDATE` e `DELETE` separados podem ser melhores sob concorrência alta. Não comparamos em tempo, pelos termos da seção 17.1.

**`DELETE` e `INSERT`: as duas travas**

A tabela começa com 3 linhas boas. A recarga repete a chave 1 no meio:

```sql
-- Same reload, now with XACT_ABORT: the first run-time error ends the batch and rolls everything back.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
INSERT INTO silver.recarga_demo VALUES (1, 99.00);
INSERT INTO silver.recarga_demo VALUES (2, 22.00);
COMMIT;
GO
```

| `SET XACT_ABORT ON` | `sqlcmd -b` | Saída | A tabela no fim |
|---|---|---|---|
| Não | Não | 0 | 2 linhas: carga parcial |
| Não | Sim | 1 | 2 linhas: carga parcial, porque o `COMMIT` do lote roda |
| Sim | Não | 0 | 3 linhas: estado anterior |
| Sim | Sim | 1 | 3 linhas: estado anterior |

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 64d_recarga_com_xact_abort.sql -b` e as outras três combinações. Saídas em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`; igual em `lab/sqlserver/saidas/2025/lab10_merge_e_recarga.txt`.

Vamos ler a tabela. `XACT_ABORT` cuida do dado, e `-b` avisa quem chamou. Inferência: com saída 0, o orquestrador segue em frente sobre uma silver que pode estar pela metade.

**O que escapa das duas travas**

| Como falha | Saída | A tabela no fim |
|---|---|---|
| `RAISERROR` de severidade 16, com as duas travas | 1 | 2 linhas: o `COMMIT` roda |
| `THROW`, com as duas travas | 1 | 3 linhas: estado anterior |
| `TRY/CATCH` que engole o erro, com as duas travas | 0 | 3 linhas, e quem chamou não sabe |
| Vários lotes, com `XACT_ABORT` e sem `-b` | 0 | O lote seguinte grava fora de transação: a linha 4 entrou |

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 68a_recarga_raiserror.sql -b` e seguintes. Saídas em `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt`; igual em `lab/sqlserver/saidas/2025/lab14_erro_na_recarga.txt`.

A documentação de `RAISERROR` diz que ele não obedece a `SET XACT_ABORT`. Por isso o par não equivale ao `psql` com `ON_ERROR_STOP` e `--single-transaction`, que no nosso teste sai com 3 e preserva o estado anterior (nível 3, psql 16.15, 2026-11-04, `lab/saidas/lab9_psql_erro.txt`). O par protege contra erro de execução do motor e contra `THROW`. Só isso.

Critério da mentoria: `SET XACT_ABORT ON`, um lote só, `sqlcmd -b`, `THROW` para falha de validação, e confira o estado da tabela depois.

**Reconstruir a tabela inteira**

`DROP TABLE` e `SELECT INTO` entram em transação. Com falha depois do `DROP`, a tabela antiga continua lá: é o que a silver do laboratório usa (`lab/sqlserver/sql/20_silver.sql`, com `BEGIN TRANSACTION`, `DROP TABLE`, `SELECT ... INTO` e `COMMIT`). `TRUNCATE` com `ROLLBACK` preserva a linha, e `CREATE DATABASE` em transação dá erro 226 (prova à parte). `DROP TABLE IF EXISTS` pede 2016, e `CREATE OR ALTER VIEW` pede 2016 SP1.

Se você tem view sobre a tabela, atenção. View criada sem `SCHEMABINDING` precisa de `sp_refreshview` quando a tabela de baixo muda de forma que afete a definição. Senão, pode devolver resultado inesperado. Leitura da mentoria: é um risco silencioso do degrau de views. Isso vem da documentação, nível 1.

### 17.9 Chave: `IDENTITY` truncada e `HASHBYTES`

"Por que a gold não usa `IDENTITY`?" Por causa da recarga.

**O equívoco comum**

`IDENTITY` não garante unicidade nem valores seguidos, e o valor se perde no `ROLLBACK`. `SEQUENCE` é objeto próprio, compartilhável entre tabelas e fora da transação. Vamos ver o que acontece ao truncar e recarregar a dimensão em outra ordem:

```text
momento|sk_na_fato|produto_que_a_chave_aponta
-------|----------|--------------------------
antes|4|40

momento|sk_na_fato|produto_que_a_chave_aponta
-------|----------|--------------------------
depois|4|20
```

> Verificação: nível 3. Imagem da 2022, 2026-11-03: `./sq.sh dw 65_chave_substituta.sql`. Saída copiada de `lab/sqlserver/saidas/2022/lab11_chave_substituta.txt`; igual na 2025.

A fato passou a apontar para outro produto, sem erro. `DELETE` não reinicia o contador, `TRUNCATE` reinicia, e é isso que produz a troca (prova à parte). Sem truncar, com `NOT EXISTS`, a chave fica igual. Com hash, também, por construção, porque o hash só depende do id, e não da ordem de carga. Na gold, ele junta o id e o início da vigência, e a mesma versão volta com a mesma chave.

**Como funciona na prática**

```sql
SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONCAT(v.produto_id, '|', CONVERT(char(10), v.valido_de, 23))), 2) AS produto_sk,
```

> Verificação: nível 3. Imagens da 2022 e da 2025, 2026-11-03: `./sq.sh dw 30_gold.sql -b`. Linha de `lab/sqlserver/sql/30_gold.sql`; execução capturada em `lab/sqlserver/saidas/2022/lab3_gold_estrela_e_fan_out.txt` e `lab/sqlserver/saidas/2025/lab3_gold_estrela_e_fan_out.txt`.

O hash é critério da mentoria, explicado no capítulo 12, ao custo de 64 caracteres por chave. Dimensão persistente com carga incremental pede inteiro gerado pelo banco, sem truncar. Venda sem versão vai para o membro `'-1'`, e o laboratório tem 0 vendas nele. O que olhar em T-SQL:

- **Algoritmo.** Desde a 2016, todo algoritmo de `HASHBYTES` fora `SHA2_256` e `SHA2_512` está preterido. O MD5 ainda roda, sem erro e sem aviso.
- **Bytes.** `HASHBYTES('MD5', '1')` e `HASHBYTES('MD5', N'1')` dão valores diferentes, e só o `varchar` coincide com o MD5 do texto em ASCII. Com acento, `'ã'` em `varchar` difere entre CP1252 e UTF-8 (prova à parte).
- **Separador.** `CONCAT(1, 23)` e `CONCAT(12, 3)` colidem sem ele. Como `CONCAT` troca `NULL` por vazio, nem o separador distingue `NULL` de texto vazio (prova à parte).
- **Conferência.** O valor da chave difere do `md5` do Postgres. A conferência entre motores compara contagem e receita, não o valor da chave.

### 17.10 Réplica e tabela temporal

"Posso montar a silver na réplica do ERP?" Em grupo de disponibilidade Always On, não.

**Réplica**

A seção 4.5 já trouxe o que a documentação diz. Secundário legível (readable secondary) não aceita mudança de esquema nem de dado. Outros bancos de leitura e escrita da mesma instância aceitam, inclusive `tempdb`. Grupo de disponibilidade básico, só da edição Standard, nem permite leitura no secundário.

Leitura da mentoria: por isso a silver não mora nele, e sim num banco próprio. Isso é documentação, nível 1, e trata só dessa tecnologia. Pergunte ao DBA qual réplica você tem, porque a receita depende disso.

**Tabela temporal**

"A tabela temporal não resolve o preço que muda?" Pode ser alternativa à foto, e nós não a testamos. A seção 11.3 a pôs na árvore do preço, com os três fatos que pesam na decisão: ela grava uma linha no histórico a cada modificação, mesmo sem mudança de valor. Não aceita `TRUNCATE` com versionamento ligado. E registra a vigência em UTC. Inferência: num ERP cuja tarefa noturna toca todas as linhas, o histórico cresce sem mudança real. Isso também é só documentação.

### 17.11 O que não testamos

"Isso garante que vai rodar no meu banco?" Não. Veja o que ficou de fora:

- **Windows, Power Query e monitor de ERP.** Nada rodou.
- **Abaixo da 2022.** As versões mínimas vêm da documentação. Compatibilidade 140 na 2022 deu o mesmo (prova à parte), o que não prova a 2017.
- **Grupo de disponibilidade.** Não foi montado. O `erp` é um banco comum.
- **`dbt run`.** O `dbt-sqlserver` ficou só em resolução de dependências, e `dbt debug` também não rodou. O que a documentação do adaptador diz, de quem mantém aos limites, e como decidir estão na seção 16.8.
- **Desempenho.** Nada medido, pelos termos da seção 17.1.

> Verificação: nível 2 na resolução. `uv` 0.11.13, Python 3.13, `dbt-core` 1.12.6 resolveu `dbt-sqlserver` 1.12.2, 2026-11-03. Saída em `lab/sqlserver/saidas/dbt_sqlserver_resolucao.txt`. Fixe a versão num arquivo de lock: a resolução mudou no mesmo dia.

Entre a 2022 e a 2025, a diferença apareceu em outro lugar. `REGEXP_REPLACE`, `||` e `CURRENT_DATE` rodam na 2025, mesmo com banco em compatibilidade 160 (prova à parte), e dão erro na 2022. A compatibilidade padrão de banco novo é 160 na 2022 e 170 na 2025. Com `StandardDeveloper`, mudam só o nome da edição e o código de `EngineEdition`, de 3 para 2. Saídas em `lab/sqlserver/saidas/diferencas_2022_2025.txt` e `lab/sqlserver/saidas/diferencas_2025_enterprise_standard.txt`. Se a sua produção é mais antiga que o seu laboratório, escreva para a mais antiga (critério da mentoria).

**Como inspecionar**

O seu banco tem versão, edição e collation próprias, e nós não as conhecemos. Leia antes de copiar. Troque os nomes dos bancos pelos seus:

```sql
SET NOCOUNT ON; SELECT @@VERSION; SELECT SERVERPROPERTY('Edition'); SELECT SERVERPROPERTY('Collation')
SET NOCOUNT ON; SELECT name, collation_name, compatibility_level FROM sys.databases WHERE name IN ('erp', 'dw') ORDER BY name
```

> Verificação: nível 3. Imagens da 2022 e da 2025, 2026-11-03, dentro de `./roteiro.sh 2022` e de `./roteiro.sh 2025`. Saídas em `lab/sqlserver/saidas/2022/lab0_ambiente.txt` e `lab/sqlserver/saidas/2025/lab0_ambiente.txt`, que diferem na versão, na edição e na compatibilidade.

Começar com SQL à mão, como no Lab 8, é caminho válido também aqui. O tratamento agora você escreve nos dois bancos. Falta a pergunta que vem antes dele: de onde vem o número que você quer reproduzir? É o próximo capítulo.

## 18. De onde vem este número: definição e linhagem

"O faturamento do relatório do sistema não bate com o meu. De onde ele vem?" Quem cruza um relatório de sistema com a própria planilha cedo ou tarde faz essa pergunta. Este capítulo dá o caminho para responder sem pesar a produção e sem permissão de ler as tabelas. E termina num registro curto, para a pergunta não voltar no mês seguinte. A frase guia é: antes do SQL, decida o que uma linha significa. Aqui ela ganha um par: antes de discutir o número, escreva o que ele significa.

O exemplo é o Lab 9. Um sistema fictício gera o relatório de faturamento por loja, e descobrimos o SQL de fora, em Postgres e em SQL Server, com dados sintéticos. O limite vem logo: rodou em Linux, em contêiner. Nada rodou em Windows, no Power Query nem no monitor de um ERP. Não sabemos a versão, a edição nem a tecnologia de réplica do seu banco, e parte da receita depende disso.

### 18.1 Duas perguntas que parecem uma

"O número está errado, ou é outro número?"

**O que é**

A definição do número diz o que ele significa, com regra, grão e dono. É decisão de negócio. A linhagem diz como o dado se move, onde é transformado e onde é consumido. É rastro técnico. Essa definição de linhagem é de um fornecedor, a dbt Labs, e serve para reduzir a análise de causa raiz e os efeitos inesperados de uma mudança feita antes no caminho.

**O equívoco comum**

Achar que a linhagem encerra a discussão. Critério da mentoria: sem a definição, a linhagem só mostra como o erro foi calculado.

Quem decide é o dono do número. Na pesquisa de comunidade de Joe Reis publicada em 2026-02-20 (1.101 respostas, múltipla escolha), 51% citaram falta de dono claro entre as dores da modelagem, e 19% apontaram a ferramenta. Leitura da mentoria: não é amostra representativa, e o post agradece a um fornecedor de ferramenta de modelagem pela parceria. É sinal, não medida.

### 18.2 O caminho em quatro passos

"Preciso pedir acesso ao banco de produção para isso?"

**Como funciona na prática**

Para começar, não. Critério da mentoria, do que pede menos para o que pede mais:

1. Pergunte onde o relatório roda: primário ou réplica, com qual login ou aplicação.
2. Leia o que já está ligado, sem mudar nada: catálogo, `pg_stat_statements` ou Query Store.
3. Se faltar a consulta ou o valor, capture por pouco tempo, com filtro.
4. Do SQL capturado, vá pelo catálogo até as tabelas de origem e registre a definição.

Se o seu sistema tem um monitor de consultas, ele ajuda no passo 2. Nenhum monitor de ERP foi testado aqui. Confira se ele mostra o comando inteiro, com que valores e para quem. Os quatro passos pedem só SQL à mão, sem projeto nenhum.

### 18.3 No Postgres: o que já está guardado

"Preciso ligar alguma coisa para ver o que o relatório rodou?"

**O que é**

Talvez não. Cada fonte conta uma parte. Literal, na tabela, é o valor escrito no texto do comando.

| Fonte | O que mostra | Limite |
|---|---|---|
| `pg_stat_statements`, módulo de estatísticas de comandos | texto normalizado, papel, banco, contagem | sem aplicação, host, plano nem momento de cada execução; sobreviveu a reinício limpo e sumiu em queda |
| `pg_stat_activity`, visão das sessões | o comando de agora, ou o último de sessão aberta, com o literal | é uma foto: sessão encerrada não deixa linha, e texto maior que `track_activity_query_size` vem cortado |
| Log de consultas | o texto com o literal, e o parâmetro enviado à parte (bind) em `DETAIL` | com `log_min_duration_statement`, o comando de dentro de função não aparece |
| `auto_explain`, plano no log | com `log_nested_statements`, o comando de dentro da função e um plano com as tabelas por trás da view | exige superusuário ou `SET` nos parâmetros |
| Catálogo: `pg_get_viewdef`, `pg_depend` | definição da view, tabelas e colunas de que ela depende | corpo em PL/pgSQL não gera dependência, função `BEGIN ATOMIC` gera; `information_schema.view_table_usage` filtra por dono e devolveu zero linhas ao papel de fora |

**Como inspecionar**

Comece pelo `pg_stat_statements`. Confira se ele está ligado: o módulo exige `shared_preload_libraries`, e isso pede reinício do servidor para ligar ou desligar. Se não estiver, o passo 2 vira pedido ao DBA.

```sql
-- What pg_stat_statements kept for the application role.
SELECT r.rolname AS papel, s.queryid, s.calls, s.rows, s.toplevel,
       left(regexp_replace(s.query, '\s+', ' ', 'g'), 150) AS query
FROM pg_stat_statements s
JOIN pg_roles r ON r.oid = s.userid
WHERE r.rolname = 'app_relatorio'
ORDER BY s.toplevel DESC, query;
```

```text
     papel     |       queryid        | calls | rows | toplevel |                                                          query                                                           
---------------+----------------------+-------+------+----------+--------------------------------------------------------------------------------------------------------------------------
 app_relatorio |  6373311547144384952 |     2 |    3 | t        | SELECT dia, sum(valor_item) AS total FROM relatorios.vw_faturamento_itens WHERE dia >= DATE $1 GROUP BY dia ORDER BY dia
 app_relatorio | -1234613963579190824 |     2 |    5 | t        | SELECT loja, faturamento FROM relatorios.faturamento_por_loja($1, $2)
 app_relatorio | -3418423842587297862 |     2 |    2 | t        | SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = $1
(3 rows)
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03, dentro de `lab/linhagem/`: `bin/pg postgres admin_lab lab -f /cenario/ver_statements.sql`. Saída copiada de `lab/linhagem/saidas/pg_02_statements.txt`.

O relatório rodou duas vezes, com `'Cliente A'` e `'Cliente E'`, e virou uma linha só: `calls = 2`, `trim(cliente) = $1`. Repare no que falta. O texto cita uma view e uma função, e a regra não aparece. No padrão, `track = top`, só a chamada da função entra. Com `track = all`, o comando de dentro dela aparece, com `toplevel = false`.

Vá então ao catálogo. Rodamos com um papel sem `GRANT` nos schemas:

```sql
-- Definition of the view.
SELECT pg_get_viewdef(c.oid, true) AS definicao
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'relatorios' AND c.relname = 'vw_faturamento_itens';
```

```text
                         definicao                          
------------------------------------------------------------
  SELECT p.id AS pedido_id,                                +
     p.loja_id,                                            +
     l.nome AS loja,                                       +
     p.cliente,                                            +
     p.criado_em::date AS dia,                             +
     i.quantidade::numeric * i.preco_unitario AS valor_item+
    FROM erp.pedidos p                                     +
      JOIN erp.itens_pedido i ON i.pedido_id = p.id        +
      JOIN erp.lojas l ON l.id = p.loja_id                 +
   WHERE lower(TRIM(BOTH FROM p.status)) = 'pago'::text;
(1 row)
```

```text
ERROR:  permission denied for schema relatorios
```

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03: `bin/pg postgres monitor_lab lab -f /cenario/catalogo.sql` e `bin/pg postgres monitor_lab lab -c "SELECT count(*) FROM relatorios.vw_faturamento_itens;"`. Trechos de `lab/linhagem/saidas/pg_05_catalogo.txt`. Consulta em `lab/linhagem/postgres/catalogo.sql`.

Achamos a regra, e o mesmo papel foi recusado ao ler a view. Ler a definição não pediu acesso aos dados.

Agora a pergunta do começo tem resposta. Imagine que a sua planilha filtra `status = 'pago'`. Os pedidos gravados como `PAGO` e ` Pago ` contam no relatório e ficam fora da planilha. No cenário sintético do Lab 9, há um de cada, e os dois somam 180,00 em itens (`lab/linhagem/postgres/00_cenario.sql`).

Medir essa diferença no total pede ler os dados, então vem por último e com quem tem acesso:

```text
 status_igual_pago | status_normalizado 
-------------------+--------------------
            656.10 |             836.10
(1 row)

 pedido_id | status_como_veio | valor_itens 
-----------+------------------+-------------
       101 | [PAGO]           |      120.00
       109 | [ Pago ]         |       60.00
(2 rows)
```

> Verificação: nível 3, `postgres:16.15-alpine`, 2026-11-04: `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/78_fatos_da_carga.sql`, fim de `lab/saidas/lab9_fatos_da_carga.txt`. A medida foi feita no laboratório principal, que tem as mesmas 10 linhas de pedidos e 13 de itens do cenário do Lab 9. O Lab 9 não rodou para esta conta.

Os 180,00 não são erro de soma. São duas definições. Qual vale? Quem responde é o dono do número.

**Quando falta a consulta ou o valor**

O passo 3 pede captura curta. Um caminho estreito é o log por papel: `ALTER ROLE app_relatorio SET log_min_duration_statement = 0;`. Vale para as sessões novas desse papel, sem reiniciar, e sai com `RESET`. Quem faz é superusuário ou papel com privilégio além de `SET`. No laboratório, outro papel ficou de fora. A amostragem existe, mas é aleatória: 200 comandos com taxa 0,1 geraram cerca de 20 linhas, e o número muda a cada execução.

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03. Comandos e saídas em `lab/linhagem/saidas/pg_03_log.txt` e `lab/linhagem/saidas/pg_04_auto_explain.txt`.

**O custo**

A documentação não dá número geral de custo do `pg_stat_statements`. Diz que a memória é proporcional a `pg_stat_statements.max` e é consumida com o módulo carregado, mesmo com `track = none`, e que `track_planning` pode ter penalidade perceptível. Do `auto_explain`, avisa que `log_analyze` pode ter impacto extremamente negativo.

No laboratório, com `pgbench` somente leitura numa máquina compartilhada e o módulo carregado em todos os cenários, a base variou cerca de 30% entre rodadas. O `track = top` ficou dentro desse ruído, e registrar todo comando em log ficou abaixo da base da mesma rodada nas três. Isso não prevê a sua produção e não vira regra (`lab/linhagem/saidas/pg_08_custo_laboratorio.txt`).

### 18.4 No SQL Server: Query Store, Extended Events e catálogo

"E se o sistema roda em SQL Server?"

**O que é**

| Fonte | O que mostra | Limite |
|---|---|---|
| Query Store | texto, plano e contagens, por banco | sem coluna de login, aplicação, usuário ou host; em queda, o texto ficou e os contadores voltaram atrás |
| Extended Events (eventos estendidos), com sessão filtrada | o SQL com os valores, inclusive comandos de dentro da procedure e SQL dinâmico montado | é preciso criar a sessão; módulo cifrado vem como `-- Encrypted text`; parar a sessão descarta o `ring_buffer` e mantém o arquivo |
| `sys.dm_exec_query_stats` | o que está no cache de planos | procedure `WITH RECOMPILE` não apareceu, cifrada vem com texto `NULL`, e as linhas do relatório sumiram depois de `DBCC FREEPROCCACHE` |
| `sys.dm_exec_requests` | o que está rodando no instante | terminou, sumiu |
| Catálogo: `OBJECT_DEFINITION`, `sys.sql_expression_dependencies`, `sys.dm_sql_referenced_entities` | definição, tabelas e, na última, colunas | a procedure para na view, e chegar às tabelas pede um segundo passo |

**Como inspecionar**

Primeira pergunta: o Query Store está ligado nesse banco? Ele vem desligado por padrão até o SQL Server 2019 e ligado em `READ_WRITE` para banco novo a partir do 2022. Num banco criado sem opção no 2022 CU27, o modo de captura observado foi `AUTO`, com retenção de 30 dias. A documentação se contradiz sobre esse modo, e a execução só resolve o conflito para esse caso. O 2019 não foi testado, e banco migrado ficou só na documentação.

O modo importa. Em `AUTO`, consulta avulsa (ad hoc) leve e pouco repetida fica de fora, e uma pesada entra na primeira execução. O limiar é interno e pode mudar. Então "não está no Query Store" não prova que não rodou. Com `QUERY_CAPTURE_MODE = ALL`, o relatório inteiro entrou, inclusive o SQL dinâmico. É mudança de configuração do banco: quem decide é o DBA.

```text
query_id|objeto|parametrizacao|cifrado|execucoes|texto
--------|------|--------------|-------|---------|-----
19|(ad hoc)|User|0|1|(@P1 date)SELECT dia, SUM(valor_item) AS total FROM relatorios.vw_faturamento_itens WHERE dia >= @P1 GROUP BY dia ORDER BY dia
20|(ad hoc)|None|0|1|SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE TRIM(cliente) = N'Cliente A'
12|faturamento_cifrado|None|1|2|** Encrypted Text **
9|faturamento_por_loja|None|0|3|(@inicio date,@fim date)SELECT TRIM(v.loja) AS loja, CAST(SUM(v.valor_item) AS numeric(14, 2)) AS faturamento     FROM relatorios.vw_faturamento_itens AS v     WHERE
```

> Verificação: nível 3. `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04`, edição Developer, 2026-11-03, dentro de `lab/linhagem/`: `bin/ms sa -i /scripts/30_qs_ler.sql`, depois de `QUERY_CAPTURE_MODE = ALL`. Trecho de `lab/linhagem/saidas/mssql_04_query_store.txt`. Os scripts de SQL Server não selecionam duração nem CPU.

O plano guardado ajuda mais que o texto. Ele traz as tabelas de origem mesmo quando o comando só cita a view, porque o otimizador expande view não indexada antes de gerar o plano. View indexada aparece como tabela. No laboratório, os planos de `faturamento_por_loja` e até da `faturamento_cifrado`, cujo texto está oculto, trouxeram `erp.pedidos`, `erp.itens_pedido` e `erp.lojas` (`bin/ms sa -i /scripts/31_qs_planos.sql`, mesma saída).

O Query Store diz o que rodou, não quem rodou. Para isso existe o Extended Events. A sessão do laboratório, em `lab/linhagem/mssql/10_xe_criar.sql`, filtra por `client_app_name`, usa `sql_batch_completed`, `rpc_completed` e `sp_statement_completed`, e não tem evento de plano. Outra aplicação ficou de fora.

```text
evento|aplicacao|login|objeto|texto
------|---------|-----|------|-----
rpc_completed|erp_relatorios|app_relatorio|faturamento_por_loja|exec relatorios.faturamento_por_loja '2026-10-20','2026-10-22'
sql_batch_completed|erp_relatorios|app_relatorio|NULL|SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE TRIM(cliente) = N'Cliente A'
```

> Verificação: nível 3. Mesma imagem e data, cliente python-tds 1.17.1: `bin/ms sa -i /scripts/11_xe_ler_arquivo.sql`. Trecho de `lab/linhagem/saidas/mssql_01_extended_events.txt`.

Três cuidados. O filtro é só o nome da aplicação, declarado pelo cliente: não separa login. Com `EXECUTE AS`, filtrar por `server_principal_name` perde eventos; para seguir quem conectou, use `session_server_principal_name`. E a atualização automática de estatísticas (`SELECT StatMan`) entrou como ruído, na primeira execução deste cenário.

E o Profiler? SQL Trace e SQL Server Profiler estão preteridos e serão removidos em versão futura. A Microsoft manda usar Extended Events, com exceção de cargas de Analysis Services. Não executamos.

Por fim, as dependências, lidas em `sys.sql_expression_dependencies`:

```text
objeto|esquema|referencia|depende_de_quem_chama
------|-------|----------|---------------------
faturamento_cifrado|relatorios|vw_faturamento_itens|0
faturamento_por_loja|relatorios|vw_faturamento_itens|0
vw_faturamento_itens|erp|itens_pedido|0
vw_faturamento_itens|erp|lojas|0
vw_faturamento_itens|erp|pedidos|0
```

> Verificação: nível 3. Mesma imagem e data: `bin/ms sa -i /scripts/40_catalogo.sql`. Trecho de `lab/linhagem/saidas/mssql_05_catalogo.txt`.

A `faturamento_dinamico` não aparece, nem nessa lista nem em `sys.dm_sql_referenced_entities`: o acesso dela mora em SQL dinâmico, e aí só a captura mostra. A `faturamento_cifrado` aparece: com `WITH ENCRYPTION`, a definição vem `NULL` em `sys.sql_modules` e em `OBJECT_DEFINITION`, mas as dependências seguem visíveis.

**O custo**

A Microsoft descreve o Extended Events como leve, com o `event_file` padrão devendo ter impacto mínimo ou nenhum. Avisa que `NO_EVENT_LOSS` pode causar problemas de desempenho detectáveis e que `query_post_execution_showplan` tem sobrecarga significativa. Não medimos. Pela seção 5 dos termos de 2022 e de 2025, vista na seção 17.1, os laboratórios de SQL Server não registram duração nem publicam comparação de desempenho.

### 18.5 A réplica tem a própria memória

"Olhei na réplica e não achei nada. O relatório não roda?"

**O equívoco comum**

Talvez rode, em outro servidor. Na réplica física do Postgres, estatísticas de consulta, sessões e log são de cada servidor. O relatório que rodou no primário não apareceu no `pg_stat_statements` da réplica, e o que rodou na réplica não mudou o primário. O `queryid` foi igual nos dois, o que ajuda a comparar. A documentação avisa que replicação lógica não promete o mesmo.

A réplica também precisa do próprio `shared_preload_libraries`. Sem ele, consultar `pg_stat_statements` nela falha, enquanto o primário segue contando. Nela, `CREATE EXTENSION` e `ALTER ROLE` são recusados, e `ALTER SYSTEM` com reload funciona. O catálogo responde lá também: o papel sem `GRANT` leu a definição da view na réplica.

> Verificação: nível 3. `postgres:16.15-alpine`, 2026-11-03. Comandos e saídas em `lab/linhagem/saidas/pg_06_replica.txt`.

No SQL Server, não montamos grupo de disponibilidade. Que Extended Events e visões dinâmicas valem por instância é inferência da documentação. O Query Store em secundário legível é recurso à parte. No 2022, é prévia limitada, exige o trace flag 12606 (sinalizador de rastreamento), não é suportado em produção e aparece na tabela de edições só na Enterprise. No 2025, está disponível, desligado por padrão e por banco, e pede grupo de disponibilidade; a página diz que segue em prévia em todas as plataformas. Nada disso foi executado. Por isso o passo 1 vem primeiro: descubra qual é a tecnologia da sua réplica.

### 18.6 O que pedir ao DBA ou ao fornecedor

"Não sou DBA. O que eu peço, exatamente?"

**Como funciona na prática**

Peça o mínimo, na ordem da tabela.

| Você quer | Postgres | SQL Server | O que isso abre |
|---|---|---|---|
| Ler definição e dependências | nada além de conectar | `VIEW DEFINITION` no schema lê a definição; `sys.sql_expression_dependencies` pediu `VIEW DEFINITION` no banco e `SELECT` nela | a regra, sem `SELECT` nos dados |
| Ler o que já foi guardado | `pg_read_all_stats`; sem ele, o texto de outro papel vem como `<insufficient privilege>` | `VIEW DATABASE PERFORMANCE STATE` para o Query Store; `VIEW SERVER PERFORMANCE STATE` para as visões dinâmicas | texto, literal e valor de parâmetro |
| Capturar por pouco tempo | superusuário faz `ALTER ROLE <papel> SET log_min_duration_statement = 0`, depois `RESET` | `CREATE ANY EVENT SESSION`, `ALTER ANY EVENT SESSION ENABLE` e `DISABLE`, `DROP ANY EVENT SESSION`; ler a sessão e o arquivo pede `VIEW SERVER PERFORMANCE STATE` | valores em log ou arquivo |
| Ver o comando de dentro da função | `pg_stat_statements.track = all` ou `auto_explain` | Query Store e `sp_statement_completed` | o comando interno e o plano |

> Verificação: nível 3. Imagens e data acima. `lab/linhagem/saidas/pg_02_statements.txt`, `lab/linhagem/saidas/pg_03_log.txt`, `lab/linhagem/saidas/pg_04_auto_explain.txt`, `lab/linhagem/saidas/pg_05_catalogo.txt`, `lab/linhagem/saidas/mssql_01_extended_events.txt`, `lab/linhagem/saidas/mssql_04_query_store.txt`, `lab/linhagem/saidas/mssql_05_catalogo.txt` e `lab/linhagem/saidas/mssql_06_permissoes.txt`.

Duas ressalvas. A matriz do SQL Server foi observada no 2022, e a da captura é cumulativa: o login já tinha as permissões anteriores. E a página de `query_store_query_text` pede a permissão de servidor; no teste, a de banco foi suficiente.

Se o sistema é de terceiro, critério da mentoria, leve três perguntas ao fornecedor:

- O relatório roda no primário ou na réplica, com qual login ou aplicação?
- O monitor mostra o comando inteiro, com valores? Quem mais pode ver?
- A regra mora em módulo cifrado ou em SQL dinâmico? Os dois fecham parte do caminho.

### 18.7 Quem lê o texto lê valor

"Dei só permissão de monitoramento. Essa pessoa não vê dado nenhum, certo?"

**O equívoco comum**

Vê. Num teste à parte, sem arquivo publicado, um login só com `VIEW DATABASE PERFORMANCE STATE` e `SELECT` negado em `erp.pedidos` leu `N'Cliente A'` em `query_sql_text` e 2 planos com `ParameterCompiledValue` de 2026-10-20. O resto segue a mesma lógica:

- **Log do Postgres.** A documentação avisa que o comando registrado pode revelar dado sensível e até senha em texto puro. `log_parameter_max_length = 0` esconde o bind, não o literal.
- **`pg_stat_activity`.** Com `pg_read_all_stats`, o texto vem com o literal.
- **`pg_stat_statements`.** Em geral o valor não fica, mas isso não é garantia. A documentação avisa que ele pode aparecer, sobretudo com muita desalocação de entradas, e `COPY`, `DO` e `SET` ficam com o literal.
- **Query Store.** Guarda o texto como foi enviado quando o motor não parametriza. Comando parametrizado pelo cliente fica sem o valor. Consulta simples de uma tabela perde o literal e tem o texto reescrito, mesmo no padrão `SIMPLE`. A do relatório, com view e `TRIM`, guardou o literal; com `PARAMETERIZATION FORCED`, virou `@0`.
- **Extended Events.** Mostra os valores. A Microsoft avisa que os arquivos podem conter dado sensível e recomenda evitar sessão longa nesse caso.

Critério da mentoria: trate permissão de monitoramento como acesso a dado. Peça janela curta e filtro, e combine quem apaga o arquivo no fim.

### 18.8 O registro mínimo

"Achei a regra. Onde eu guardo, para não refazer tudo daqui a seis meses?"

**Como funciona na prática**

Escreva junto do SQL. Um arquivo de texto ao lado do script já serve. Critério da mentoria: oito campos, aqui com o exemplo do Lab 9.

| Campo | Exemplo |
|---|---|
| Nome do número | Faturamento por loja |
| Pergunta que responde | Quanto cada loja faturou em pedidos pagos, por dia? |
| Regra em uma frase, com o que fica de fora | Soma de quantidade vezes preço unitário dos itens de pedidos com status pago, depois de limpar espaços e caixa do texto. Fica de fora: cancelado, pendente e status nulo. |
| Grão | Uma linha por loja e dia |
| De onde vem | `erp.pedidos`, `erp.itens_pedido`, `erp.lojas` |
| Onde é calculado hoje | `relatorios.vw_faturamento_itens` e `relatorios.faturamento_por_loja`, no sistema; `mart_faturamento_por_loja`, no projeto dbt |
| Dono, que arbitra quando dois relatórios divergem | Diretoria comercial (fictícia) |
| Última conferência | 2026-11-03: 419,90, 344,20 e 72,00 por loja, nos dois lados |

> Verificação: nível 3. `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03: a soma de `dw.mart_faturamento_por_loja` contra `relatorios.faturamento_por_loja('2026-10-20', '2026-10-22')`. Saída em `lab/linhagem/saidas/dbt_01_linhagem.txt`.

**O equívoco comum**

Fazer do registro uma segunda fonte de cálculo. O corte, também critério da mentoria: o registro descreve, a camada semântica calcula. O campo "grão" é a frase guia posta no papel. Se ninguém consegue preencher o campo "dono", você achou o problema de verdade.

### 18.9 Linhagem no dbt e o seu limite

"Se eu adotar dbt, a linhagem vem pronta?"

**Como funciona na prática**

Vem a do que o projeto declara. O registro cabe no próprio modelo: `description`, `doc()` e `config.meta` entram no `manifest.json`.

```yaml
version: 2

models:
  - name: mart_faturamento_por_loja
    description: '{{ doc("faturamento_por_loja") }}'
    config:
      meta:
        dono_do_numero: Diretoria comercial
        reconferido_em: "2026-11-03"
    columns:
      - name: loja
        description: Nome da loja, sem espaços nas pontas.
      - name: dia
        description: Dia do pedido, como o sistema de origem registra.
      - name: faturamento
        description: Soma de quantidade vezes preço unitário dos itens de pedidos pagos.
```

> Verificação: nível 3 pela execução, nível 2 por `dbt parse --no-partial-parse`. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03. Copiado de `lab/linhagem/dbt/models/gold/_gold.yml`; a descrição e o `meta` lidos do `manifest.json` estão em `lab/linhagem/saidas/dbt_01_linhagem.txt`.

O painel entra por uma exposição (exposure), declarada à mão em `lab/linhagem/dbt/models/exposures.yml`. A partir dela, `dbt ls --select +exposure:relatorio_faturamento_diretoria` lista do painel até as fontes.

**Como inspecionar**

Leia o `parent_map` do manifesto:

```text
pais de model.linhagem.mart_faturamento_por_loja: ['model.linhagem.stg_itens', 'model.linhagem.stg_lojas', 'model.linhagem.stg_pedidos']
pais de model.linhagem.copia_sem_ref: []
pais de model.linhagem.copia_da_view_do_sistema: ['source.linhagem.sistema.vw_faturamento_itens']
pais de source.linhagem.sistema.vw_faturamento_itens: []
pais de exposure.linhagem.relatorio_faturamento_diretoria: ['model.linhagem.mart_faturamento_por_loja']
```

> Verificação: nível 3 pela execução, nível 2 por `dbt parse --no-partial-parse`. `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, 2026-11-03: `docker compose --profile dbt run --rm -T --no-deps dbt python ler_manifesto.py`. Trecho de `lab/linhagem/saidas/dbt_01_linhagem.txt`.

`dbt docs generate` e `dbt docs serve` rodaram local e sem conta. O primeiro escreve `index.html`, `catalog.json` e `manifest.json` em `target/`. O site respondeu HTTP 200 de dentro do contêiner, e a página gráfica de linhagem não foi aberta em navegador. No Lab 5, os pais de `fct_vendas` são `dim_loja`, `dim_produto`, `stg_itens` e `stg_pedidos` (`lab/saidas/lab5_projeto_dbt.txt`).

**O equívoco comum**

Achar que o grafo enxerga tudo. Ele só vê o que o projeto declara com `ref`, `source`, `function` ou `metric`. O modelo com a tabela escrita à mão, `copia_sem_ref`, tem pais vazios. O que lê a view do sistema para na `source`, sem chegar às tabelas de dentro dela. Por isso os quatro passos continuam valendo depois do dbt.

Inferência: cálculo do ERP e Power Query só entram se alguém os declarar. Não testamos com esses produtos. A página de exposições automáticas lista só Tableau, em Enterprise.

Agora você sabe de onde o número vem e quem responde por ele. Falta a decisão de quem gerencia: onde essa regra deve morar daqui para a frente, e que sinal justifica subir de degrau. É o próximo capítulo.

## 19. Onde a regra mora: a decisão de quem gerencia

"Preciso de dbt já?" A resposta curta é não. Você precisa de SQL versionado e de teste. Isso é **critério da mentoria**, não norma: não achamos norma que diga quando subir de degrau.

Este capítulo dá um caminho para decidir. Uma escada, o sinal que justifica cada subida, os casos em que ainda não é hora e as perguntas para levar ao time. Antes do SQL, você decide o que uma linha significa. Antes da ferramenta, decida onde a regra mora e quem responde por ela.

### 19.1 A minha dor é falta de ferramenta?

"Se a gente comprar a ferramenta certa, o número para de divergir?"

**O que a pesquisa mostra**

Na pesquisa de comunidade de Joe Reis, publicada em 2026-02-20, com 1.101 respostas de múltipla escolha, 19% apontaram a ferramenta. A falta de dono claro teve 51%. A pressão por velocidade teve 59%, e a manutenção difícil, 39%. Só 11% marcaram "None / modeling is going well" (nenhuma, a modelagem vai bem).

Leia com cuidado. São respostas da própria comunidade, sem amostra representativa (leitura da mentoria). E o post agradece a um fornecedor de ferramenta de modelagem pela parceria. Serve de pista, não de prova.

**O equívoco comum**

"Todo mundo usa, então precisamos." Critério da mentoria: moda não é sinal. Sinal é um número que você consegue apontar.

### 19.2 Que sinal justifica subir?

"O que eu mostro à diretoria para justificar a mudança?"

**Como funciona na prática**

Vamos ao BI por planilha. Um relatório filtra a receita paga de um jeito, o outro filtra de outro, sobre os mesmos dados. É o caso que o capítulo 6 apresentou:

| Regra | Soma |
|---|---|
| `status = 'pago'` | 130,00 |
| `lower(trim(status)) = 'pago'` | 170,00 |

Nenhuma das duas dá erro. As duas rodam. A primeira não enxerga o status escrito com maiúscula ou com espaço. A diferença de 40,00 não aparece em log nenhum: aparece quando alguém compara os dois números.

> Verificação: nível 3 como simulação, com `psql` em `postgres:16.15-alpine`, em 2026-11-03, fora dos scripts do laboratório. As duas regras estão em SQL. Não executamos Power Query.

Critério da mentoria: o sinal para subir é esse, não a moda. Um número divergente, com os dois relatórios na mão. E a primeira decisão que ele pede nem é de ferramenta: qual regra vale e quem arbitra. O capítulo 18 mostra como registrar isso.

**Como inspecionar**

Critério da mentoria: escolha o número que mais dói. Liste onde a regra dele está escrita. Se a lista tem mais de um lugar, você já tem o sinal.

### 19.3 Em que degrau estou e qual é o próximo?

"Existe um caminho, ou é tudo ou nada?"

**A escada (critério da mentoria)**

São cinco degraus, e não há obrigação de passar por todos. Número de pessoas ou de modelos não é gatilho. O gatilho é o sinal da última coluna.

| Degrau | Onde a regra mora e para que serve | Risco | Sobe quando |
|---|---|---|---|
| 0. Planilha e Power Query | No arquivo de cada pessoa. Serve para explorar. | Regra copiada. Histórico impossível. | A mesma regra em dois modelos. O pedido do "valor de ontem". Carga perto dos limites. |
| 1. SQL solto | Em arquivos soltos. Serve para descobrir a origem. | Ninguém sabe que versão gerou o número. Erro passa batido. | A segunda pessoa precisa rodar. A entrega vira recorrente. |
| 2. Views e scripts versionados | No Git, rodando no banco. Serve a uma equipe pequena. | Ordem de execução à mão. Teste que só roda se alguém lembrar. | A ordem vira manutenção. Ninguém responde "se eu mudar esta coluna, o que quebra?". |
| 3. dbt local e agendador | No Git, compilado e rodado no banco. Serve a várias pessoas, com testes como rotina. | Adaptador, geração em transição, snapshot, incremental. | Você precisa de agendamento hospedado e catálogo, e o seu banco é atendido. |
| 4. Plataforma paga | Igual ao 3, hospedado. Serve para agendamento hospedado e catálogo. | Preço. Banco fora da lista. | É o último degrau. |

Pelo mesmo critério, começar com SQL à mão é caminho válido. É nele que você descobre de onde vem cada número. Ficar no degrau 2 também é resultado legítimo, se os sinais de cima não apareceram.

### 19.4 Meu BI já funciona. O que a Microsoft diz sobre o degrau 0?

"Tudo roda no Power Query hoje. Por que mexer?"

**O que a documentação diz**

- **Volume e histórico.** Transformar e preparar o dado no Power Query pode ser difícil com grande volume ou com SCD. Nesse caso, a Microsoft recomenda desenvolver antes um armazém de dados (data warehouse) com carga periódica, e conectar o modelo semântico a ele.
- **O valor de ontem.** Uma atualização não incremental de uma tabela de dimensão produz o efeito de um SCD tipo 1. Quando a origem não guarda versões, é preciso um sistema intermediário, como um armazém, para detectar e guardar as mudanças. A fato busca a chave da versão vigente na data do fato. O modelo semântico usa Power Query e não consegue produzir esse resultado, o processo de carga do tipo 2 inteiro, inclusive a busca por data. Ele pode carregar uma dimensão tipo 2 já pronta.
- **Coluna.** A Microsoft prefere coluna criada no Power Query a coluna calculada em DAX. Quando a fonte é banco, a carga fica mais eficiente com o cálculo definido no SQL ou materializado como coluna na fonte. A exceção é fórmula que avalia medidas ou depende de função que só existe no DAX.
- **Dono.** O roteiro de adoção descreve três estratégias de dono do conteúdo: business-led self-service, managed self-service e enterprise (autoatendimento liderado pelo negócio, autoatendimento gerenciado e corporativo). Cada uma tem uma lista de quando é mais adequada. A do meio é "discipline at the core and flexibility at the edge" (disciplina no centro, flexibilidade na ponta).
- **Versão única.** O objetivo do autoatendimento gerenciado é ter poucos modelos compartilhados e uma versão única da verdade. A Microsoft descreve o outro extremo, um modelo novo por relatório, como coisa de criador menos experiente.

**Número real: os limites de atualização**

Em capacidade compartilhada do Power BI, o modelo tem no máximo oito atualizações agendadas por dia. Cada uma precisa terminar em menos de duas horas. Depois de quatro falhas seguidas, o agendamento é desativado, e esse limiar não é configurável. Carga perto desses números é um dos sinais da escada.

**Existe um degrau dentro do próprio BI?**

Existe. A Microsoft recomenda tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow (fluxo de dados), em Power Query Online, para chegar a uma fonte única da verdade. Essa página trata do Dataflow Gen1, em estado legado, e indica o Gen2.

Isso ataca a regra copiada. Inferência: ainda não resolve o tipo 2, porque continua sendo Power Query e a documentação pede um sistema intermediário para guardar as versões.

**O limite do que testamos**

Nada deste capítulo rodou em Power Query nem em dataflow. Não há página do Microsoft Learn sobre regra duplicada entre Power Query e SQL: a divergência acima foi simulada em SQL.

### 19.5 Meu script roda toda noite e nunca deu erro. Posso confiar?

"Se ninguém reclamou, deu certo, não é?"

**O equívoco comum**

Nunca ter visto erro não prova que não houve erro. Rodado à mão, o `psql` continua depois de um erro por padrão e sai com código 0.

**Como funciona na prática**

Testamos um script que recria a tabela e insere três linhas, com a do meio inválida. Antes de rodar, a tabela guardava a carga de ontem.

| Como rodou | Código de saída | O que ficou na tabela |
|---|---|---|
| Padrão | 0 | Linhas 1 e 3. A carga de ontem sumiu e a nova ficou pela metade. |
| `-v ON_ERROR_STOP=1` | 3 | Linha 1. O erro aparece, mas a tabela fica pela metade. |
| `--single-transaction`, sem a variável | 0 | A transação é desfeita, e o código de saída não mostra a falha. |
| `-v ON_ERROR_STOP=1 --single-transaction` | 3 | A carga de ontem, intacta. O erro aparece. |

A linha que você quer é a última:

```bash
psql -U dw -d dw -X -q -v ON_ERROR_STOP=1 --single-transaction -f /sql/79b_psql_erro_recarga.sql
```

> Verificação: nível 3, 2026-11-04, `postgres:16.15-alpine` e `psql` 16.15, com `lab/sql/79a_psql_erro_preparar.sql`, `79b_psql_erro_recarga.sql` e `79c_psql_erro_estado.sql`; saída em `lab/saidas/lab9_psql_erro.txt`.

No SQL Server, a proteção é outra e não equivale a esse par. `SET XACT_ABORT ON` com `sqlcmd -b` protege contra erro de execução do motor e contra `THROW`, mas com `RAISERROR` de severidade 16 a carga parcial fica. O capítulo 17 mostra as combinações.

> Verificação: nível 3, com `sqlcmd -b` nas versões 2022 e 2025, em 2026-11-03. Saídas em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`, `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt` e `lab/sqlserver/saidas/2025/lab14_erro_na_recarga.txt`.

**E o agendamento?**

A dbt Labs reconhece o cron como forma razoável de agendar comandos, mas avisa que escrever o que falta para produção costuma deixar esse caminho mais complexo que as alternativas. Leitura da mentoria: o aviso faz sentido, e quem escreve vende uma das alternativas. Confira o que falta no seu caso antes de aceitar ou descartar.

**Os limites das views**

O degrau 2 tem limites documentados. Vale conhecer antes de chamá-lo de solução final.

- No Postgres, `CREATE VIEW` não materializa e roda a consulta a cada uso.
- `CREATE OR REPLACE VIEW` exige as mesmas colunas, com os mesmos nomes, na mesma ordem e com os mesmos tipos. Pode acrescentar colunas no fim.
- `REFRESH MATERIALIZED VIEW` substitui todo o conteúdo.
- Em T-SQL, view criada sem `SCHEMABINDING` precisa de `sp_refreshview` quando a tabela de baixo muda de forma que afete a definição. Senão, pode devolver resultado inesperado. Leitura da mentoria: é o risco silencioso deste degrau.

### 19.6 Subir para o dbt: o que eu perco e quanto custa?

"Joguei fora o SQL que já escrevi? E a conta, de quanto é?"

**O que muda**

A dbt Labs mostra que um `INSERT ... SELECT` vira modelo tirando o `SELECT` da procedure para o arquivo do modelo. Leitura da mentoria: o SQL escrito à mão não se perde. A mesma dbt Labs reconhece que migrar procedures é uma mudança grande de paradigma, do procedural para o declarativo. Leitura da mentoria: esse é o custo do degrau 3, o tempo do time mudando o modo de pensar. Não temos fonte de horas de adoção, então não damos número.

**O que decide é o adaptador**

Sobre escolher a geração v2 do dbt, a própria dbt Labs escreve: "Today, the main determinant is whether your adapter is fully supported for your use case" (hoje, o principal fator é o adaptador ter suporte completo para o seu caso de uso). E aí entra o seu banco:

- **Postgres.** Não aparece na tabela de adaptadores da v2. Postgres com dbt hoje quer dizer geração v1, com adaptador mantido pela dbt Labs.
- **SQL Server.** Também não aparece nessa tabela. O `dbt-sqlserver` tem licença MIT e é plugin de comunidade: "Some core functionality may be limited", "Maintained by: Community", "dbt support: Not Supported". Não executamos `dbt run` contra SQL Server. Se você escolher esse caminho, alguém precisa ser dono desse risco.

O capítulo 16 detalha geração, licença e adaptador.

**Número real: o que a tabela de preço diz**

| Opção | Custo público | O que vem |
|---|---|---|
| dbt local | O dbt v1 continua Apache 2.0. Sobre a v2, a dbt Labs responde "No" a "If I use dbt, do I have to pay dbt Labs anything?". | O projeto roda na sua máquina ou no seu agendador. |
| Plataforma, Developer | Grátis | 1 assento, 1 projeto, 3.000 modelos com sucesso por mês, sem linhagem listada. |
| Plataforma, Starter | US$ 100 por usuário por mês | 5 assentos, 15.000 modelos por mês, "Lineage with dbt Catalog". |
| Plataforma, Enterprise e Enterprise+ | Sob consulta | A linhagem por coluna no Catalog só aparece aqui. |
| dbt State | Cobrado por uso | Exige login. |

Preço público consultado em 2026-11-03. Preço muda: confira de novo antes de decidir. Conta da mentoria: cinco assentos ocupados no Starter dão US$ 500 por mês, pelo preço de tabela.

Antes de pedir orçamento, confira se o seu banco é atendido. Não verificado: se a plataforma atende SQL Server em servidor próprio na geração v1. A pergunta é para o fornecedor.

### 19.7 Quando ainda não é hora de subir?

"Todo mundo aqui fala em dbt. Se eu não subir, fico para trás?"

**Critério da mentoria: não suba de degrau quando**

- **Há uma pessoa e poucos relatórios.** O custo de manter a ferramenta não se paga ainda.
- **Não existe banco analítico que aceite escrita.** Uma réplica Postgres em espera ativa (hot standby) não aceita escrita, nem tabela temporária. Logo, a silver não pode ser criada no banco replicado. No SQL Server, depende da tecnologia de réplica: veja o capítulo 4.
- **A dor é falta de dono ou de definição.** Ferramenta não arbitra número. Comece pelo capítulo 18.
- **Ninguém usa Git.** Sem revisão de mudança, o degrau 3 herda o mesmo problema. Suba primeiro para o 2.
- **O adaptador é de comunidade e ninguém é dono do risco.** Quando quebrar, quem responde?
- **O motivo é "todo mundo usa".** Sem um número divergente para apontar, volte à seção 19.2.

### 19.8 O que eu pergunto ao time?

"Não escrevo o SQL. Como eu sei se está no caminho?"

Pergunte, e preste atenção na resposta. Cada pergunta abaixo, e cada resposta que preocupa, é **critério da mentoria**: nenhuma vem de norma. Uma resposta ruim não condena o time. Ela diz por onde começar.

**Antes do SQL (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| O que uma linha desta tabela significa? | "Depende." |
| Onde esta regra está, e em quantos lugares? | Em dois relatórios. |
| Quem é dono deste número? | "Todo mundo." |
| Se o preço mudar hoje, perdemos o de ontem? | "Não sei." |
| Em que fuso a origem grava? | "Acho que é local." |
| Qual tecnologia é a réplica, e onde escrevemos? | "Na réplica." |

**Antes de confiar (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| Se o script falhar no meio, o que fica? | Nunca testaram. |
| O que dá para refazer? | Histórico sem backup. |
| Como saberíamos que o número dobrou? | "O usuário reclama." |
| Se o teste falhar às 6h, a carga para ou segue, e quem é avisado? | Ninguém decidiu. |

**Antes do dbt (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| O que dói hoje, com um exemplo? | "É o padrão." |
| Qual é o estado do adaptador, e quem responde por ele? | Ninguém olhou. |
| Qual geração, qual versão fixa e quando é o próximo upgrade? | `pip install` sem versão. |
| Para que serve a plataforma paga aqui? | Ninguém sabe que o local é gratuito. |
| Quem revisa a mudança? | Sem Git, ninguém. |
| Tem dado pessoal no histórico? | "Guardamos tudo." |

**A última pergunta tem lei por trás**

A LGPD prevê limitação do tratamento ao mínimo necessário (art. 6º, III), eliminação dos dados após o fim do tratamento, com exceções de conservação (art. 16), e direito do titular à eliminação de dados desnecessários ou excessivos (art. 18, IV). Inferência da mentoria, não parecer jurídico: histórico que não se apaga precisa nascer com a escolha de colunas.

Decidido o degrau, falta pôr a mão: no próximo capítulo, você roda o laboratório, do SQL à mão ao projeto dbt.

## 20. Laboratório

"Li até aqui. Dá para ver isso acontecendo na minha máquina, sem servidor e sem nuvem?"

Dá. O laboratório leva a rede de lojas fictícia do dado cru ao número da diretoria. Você sobe o ambiente, roda a silver e a gold e vê a receita de 430,90 no dia 20. Depois dobra a carga de itens e vê o dbt parar onde o SQL à mão publica 741,80. O laboratório mostra o que acontece quando ninguém testa o que uma linha significa.

### 20.1 O que preciso e o que pode dar errado?

"Preciso instalar o quê? Isso mexe em alguma coisa minha?"

**O que protege você**

- Todos os dados são sintéticos.
- Nenhuma porta é publicada na sua máquina. Todo comando entra pelo Docker.
- Nenhuma credencial aparece neste texto. O `./preparar.sh` gera o `.env` com segredos aleatórios, e o `.gitignore` deixa esse arquivo fora do Git.

**O que você precisa ter**

Docker com Compose, terminal com bash e internet na primeira vez. O capítulo 0 traz o comando que confere. Tudo rodou em Linux x86-64. Não testamos em Windows nem em máquina de 8 GB.

| O quê | Medido em 2026-11-03 |
|---|---|
| Imagem do Postgres | 294 MB |
| Imagem do dbt | 531 MB |
| Imagem do Airflow com dbt, só no Lab 7 | 2,65 GB |
| Volume do Postgres, depois de todos os Labs | cerca de 74 MB |
| Postgres em repouso | 31 a 41 MiB |
| Pico do processo do dbt, conforme o comando | 112 a 151 MiB |
| Pico do contêiner do Airflow com dbt | 370 a 435 MiB |

> Verificação: nível 3, num Linux de 14 CPUs e 31 GB, com `docker image ls`, `docker system df -v`, `docker stats` e o log de recursos do dbt. Saídas: `lab/saidas/recursos_medidos.txt` e `lab/saidas/lab0_subir_do_zero.txt`. A ordem de grandeza é firme; as faixas variam por rodada.

Os Labs 8 e 9 têm exigências próprias: a licença do SQL Server, lida antes do comando, e a memória que o `README.md` de cada pasta pede. Não publicamos medida de SQL Server, e o Lab 8 diz por quê.

Quer rodar sem Postgres? `lab/alternativa_duckdb/` traz um projeto menor, que não reproduz estes Labs e não saiu mais leve em memória que Postgres mais dbt.

**Onde está e como ler**

O laboratório fica em `engenharia_de_dados/modelagem/dbt/lab/`, no repositório clonado. A partir daqui, `lab/` é essa pasta. Rode tudo de dentro dela, salvo quando o Lab mandar entrar em subpasta.

Os comandos são as linhas `$` das capturas. A saída esperada é trecho dessas capturas, e `lab/saidas/` guarda o arquivo inteiro. Nas linhas do dbt e do Airflow, cortamos o carimbo de hora e o prefixo de log. O `[exit 0, 2026-11-03]` não vem do comando: o script de captura acrescenta o código de saída e a data. Na sua rodada, confira com `echo $?`.

**Por onde começar**

| Lab | O que você vê | Para quem é, critério da mentoria |
|---|---|---|
| Lab 0 | Subir o ambiente | todo mundo |
| Lab 1 | A silver à mão | todo mundo |
| Lab 2 | Fuso e datas | todo mundo |
| Lab 3 | Estrela, one big table e fan-out | todo mundo |
| Lab 4 | O preço, o `UPDATE` e o tipo 2 | todo mundo |
| Lab 5 | O mesmo fluxo em dbt | quem avalia uma ferramenta |
| Lab 6 | Testes que param | quem avalia uma ferramenta |
| Lab 7 | O dbt numa Dag | quem já usa orquestrador |
| Lab 8 | Silver e gold em T-SQL | quem tem SQL Server |
| Lab 9 | Que SQL um relatório roda | quem precisa achar de onde vem um número |

Os Labs 0 a 7 são uma sequência: cada um parte do estado do anterior. Os Labs 8 e 9 são projetos à parte. Parar no Lab 4 é caminho válido, critério da mentoria. Você já terá silver, estrela e histórico em SQL à mão.

### Lab 0: Subir o ambiente

"O que é esse `.env`? E esse `down -v` não apaga nada meu?"

Pré-condição: Docker com Compose e a pasta `lab/` clonada.

```bash
./preparar.sh
docker compose --profile dbt down -v
docker compose --profile dbt config -q && echo compose ok
docker compose up -d --wait postgres
docker compose exec -T postgres psql -U dw -d dw -c "select version()" -c "\dn" -c "select count(*) as tabelas_na_replica from information_schema.foreign_tables"
docker compose --profile dbt build --no-cache --progress=plain dbt
docker image ls --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -E "^(postgres:16.15-alpine|modelagem-lab-dbt:local|python:3.13.15-slim-bookworm) "
```

O `down -v` só alcança este projeto: contêiner, rede e volume do `modelagem-lab`. Na primeira vez, não há o que apagar. Nas seguintes, ele apaga as tabelas do laboratório, e é por isso que o começo fica limpo.

Saída esperada, em trechos:

```text
.env já existe, nada a fazer.
compose ok
 Container modelagem-lab-postgres-1  Healthy
 PostgreSQL 16.15 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit

       List of schemas
   Name   |       Owner       
----------+-------------------
 bronze   | dw
 controle | dw
 gold     | dw
 public   | pg_database_owner
 replica  | dw
 silver   | dw
(6 rows)

 tabelas_na_replica 
--------------------
                  7
(1 row)

 modelagem-lab-dbt:local  Built
modelagem-lab-dbt:local 531MB
postgres:16.15-alpine 294MB
python:3.13.15-slim-bookworm 121MB
```

Na captura, o `.env` já existia. Na sua primeira vez, o script cria o arquivo e avisa na tela. O aviso do Compose sobre `--progress` não é erro.

**Por que tudo tem versão fixa?**

Porque sem lock (arquivo que trava a versão de cada pacote) o ambiente muda em dias. Resolvendo `dbt-core` 1.12.6 em 2026-11-03, a dependência indireta `dbt-core-experimental-parser` saiu 2.0.11, e o lock de 2026-11-01 tem 2.0.8. Com o lock de 59 pacotes, a captura instala `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, que declaram Python 3.10 a 3.14. O PostgreSQL 16 tem suporte até 2028-11-09.

**Se a imagem não construir**

A construção usa a rede bridge do Docker, e a captura terminou com saída 0 por ela. Mais cedo, no mesmo dia, essa rede ficou sem saída para a internet, por problema do host, não do laboratório. Se acontecer com você, a captura registra também a construção pela rede do host, com o mesmo `Dockerfile` e o mesmo lock:

```bash
docker build --network host --no-cache --progress=plain -t modelagem-lab-dbt:local runner
```

> Verificação: nível 3, em 2026-11-03, em Linux. Imagens `postgres:16.15-alpine` (digest `sha256:0cefaabd882e42bcb2a2f3dc56d3ce4770560ba62fd7f197f1a2e008fd5731ab`) e `python:3.13.15-slim-bookworm`. Saídas: `lab/saidas/lab0_subir_do_zero.txt` e `lab/saidas/lab0_construir_imagem_dbt.txt`. Resolução sem lock em nível 2, com `uv pip compile` e Python 3.13.

### Lab 1: A silver à mão

"O tratamento que eu tenho medo de escrever cabe em SQL puro?"

Pré-condição: Lab 0 concluído, Postgres de pé.

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/10_bronze_carga.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-20 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/21_silver_antes_depois.sql
```

Saída esperada, em trechos:

```text
     tabela      | linhas 
-----------------+--------
 bronze.pedidos  |     11
 replica.pedidos |     10
(2 rows)

          tabela          | linhas 
--------------------------+--------
 silver.pedidos           |     10
 silver.itens             |     13
 silver.lojas             |      3
 silver.produtos          |      5
 silver.produtos_vigencia |      5
 silver.atendimentos      |      4
(6 rows)

    status    | pedidos | valor  
--------------+---------+--------
 cancelado    |       1 |  45.00
 desconhecido |       1 |  80.50
 pago         |       7 | 836.10
 pendente     |       1 |  15.00
(4 rows)

 margem_soma_ignora_nulo | margem_com_zero | itens_sem_custo 
-------------------------+-----------------+-----------------
                  397.10 |          409.10 |               1
(1 row)
```

Confira três coisas. A bronze tem 11 pedidos, e a silver, 10: o pedido 103 chegou duas vezes, e ficou o último estado. O status nulo virou `desconhecido` e segue visível. O custo nulo segue nulo: com zero no lugar, a margem iria de 397,10 para 409,10.

Dois detalhes não são erro. Os `NOTICE` de tabela que não existe aparecem na primeira rodada. E a coluna `carregado_utc` do pedido 103 traz o dia em que você rodou; na captura, 2026-11-03.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab1_silver_a_mao.txt`.

### Lab 2: Fuso e datas

"Por que tem atendimento à meia-noite numa loja que fecha às 22h?"

Pré-condição: Lab 1 concluído.

```bash
docker compose exec -T postgres psql -U dw -d dw -f /sql/22_fuso.sql
```

Saída esperada, em trechos:

```text
== O atendimento da meia-noite. Loja fecha às 22h; a origem grava UTC em coluna sem fuso.
 id |     loja      | fecha_as |   lido_como_esta    |        certo        
----+---------------+----------+---------------------+---------------------
  1 | Loja Centro   | 22:00:00 | 2026-10-20 13:15:00 | 2026-10-20 10:15:00
  2 | Loja Centro   | 22:00:00 | 2026-10-21 00:25:00 | 2026-10-20 21:25:00
  3 | Loja Norte    | 22:00:00 | 2026-10-21 00:50:00 | 2026-10-20 21:50:00
  4 | Loja São João | 20:00:00 | 2026-10-21 12:00:00 | 2026-10-21 09:00:00
(4 rows)

psql:/sql/22_fuso.sql:43: ERROR:  date/time field value out of range: "31/02/2026"
[exit 0, 2026-11-03]
```

Os atendimentos 2 e 3 mudam de dia depois da conversão. O `ERROR` é de propósito: uma data impossível para o comando. Este script roda sem `ON_ERROR_STOP`, por isso segue até o fim e sai com 0. Guarde isso para o Lab 6: saída 0 não prova que deu certo.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab2_fuso_e_datas.txt`.

### Lab 3: Estrela, one big table e fan-out

"Onde aparece o número da diretoria? E como ele dobra sem dar erro?"

Pré-condição: Lab 1 concluído. Por enquanto, só existe a foto do dia 20.

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/31_fan_out.sql
```

Saída esperada, em trechos:

```text
SELECT 92
SELECT 3
SELECT 6
SELECT 13
SELECT 3
CREATE VIEW
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       430.90
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
(3 rows)

 linhas_fct | chaves_fct | itens_silver | linhas_obt | receita_obt 
------------+------------+--------------+------------+-------------
         13 |         13 |           13 |         13 |      836.10
(1 row)

== Fan-out 1: dimensão com duas linhas para a mesma chave. Sem erro nenhum.
 linhas | receita_dobrada 
--------+-----------------
      9 |          850.90
(1 row)

== O teste do grão, em SQL puro: devolve linhas quando quebra.
        tabela        | chaves_repetidas 
----------------------+------------------
 fct_vendas           |                0
 itens com fornecedor |                5
(2 rows)
```

Aí está o 430,90. O mesmo dia dá 850,90 com um JOIN a mais, e nada avisa. Só o teste do grão acusa. No começo da saída, o `SELECT 6` é a dimensão de produto: 5 produtos e o membro `'-1'`. Cada rodada da gold acrescenta uma linha em `controle.carga`, então rodar de novo faz esse registro crescer. É o esperado.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

### Lab 4: O preço, o `UPDATE` e o tipo 2

"O sistema troca o preço toda noite. O de ontem sumiu mesmo?"

Pré-condição: Lab 3 concluído. Os scripts `erp_noite` fazem o papel do ERP sobrescrevendo o preço.

```bash
docker compose exec -T postgres psql -U erp -d erp -v ON_ERROR_STOP=1 -f /sql/erp_noite_21.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-21 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U erp -d erp -v ON_ERROR_STOP=1 -f /sql/erp_noite_22.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-22 -f /sql/11_bronze_foto_precos.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/30_gold.sql
docker compose exec -T postgres psql -U dw -d dw -f /sql/40_preco_update_apaga.sql
```

Saída esperada, em trechos:

```text
== SCD tipo 2 derivado das fotos, por vigência.
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

== Custo de cada caminho: linhas guardadas.
 linhas_nas_fotos | linhas_no_tipo_2 
------------------+------------------
               15 |                7
(1 row)

== BETWEEN com limites fechados: a venda no dia da troca casa com duas versões.
 pedido_id | item_seq | dia_local  | versoes_casadas | valor_somado 
-----------+----------+------------+-----------------+--------------
       108 |        2 | 2026-10-22 |               2 |       160.00
(1 row)
```

A origem guarda só o preço de hoje. As fotos guardam os três dias, e a silver monta a vigência. A receita segue em 430,90, 111,90 e 293,30.

> Verificação: nível 3, em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Saída: `lab/saidas/lab4_preco_update_e_scd2.txt`.

### Lab 5: O mesmo fluxo em dbt

"O dbt muda o número ou só muda quem roda?"

Pré-condição: Lab 4 concluído, porque o snapshot lê as três fotos, e imagem do dbt construída no Lab 0.

```bash
docker compose --profile dbt run --rm dbt dbt --version
docker compose --profile dbt run --rm dbt dbt debug
docker compose --profile dbt run --rm dbt dbt parse
docker compose --profile dbt run --rm dbt dbt seed
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-21"}'
docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-22"}'
docker compose exec -T postgres psql -U dw -d dw -c "select id, preco, dbt_valid_from, dbt_valid_to from dbt_snapshots.snap_produtos_preco order by id, dbt_valid_from" -c "select (select count(*) from dbt_snapshots.snap_produtos_preco) as linhas_check, (select count(*) from dbt_snapshots.snap_produtos_por_timestamp) as linhas_timestamp"
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/50_comparar_a_mao_e_dbt.sql
cat projeto_dbt/target/compiled/rede_de_lojas/models/gold/fct_vendas.sql
docker compose --profile dbt run --rm dbt dbt docs generate
```

A captura guarda duas passadas de snapshot: a segunda apaga as tabelas e refaz, com o mesmo resultado. Você precisa de uma.

Saída esperada, em trechos:

```text
  - installed: 1.12.6
  - postgres: 1.11.0 - Up to date!
dbt v2 is available, and is the default for new installations. This is dbt Core v1.

All checks passed!

 linhas_check | linhas_timestamp 
--------------+------------------
            7 |               15
(1 row)

[WARNING]: in test assert_status_desconhecido (tests/assert_status_desconhecido.sql)
[WARNING]: Got 1 result, configured to warn if != 0
[WARNING]: in test not_null_stg_produtos_custo (models/silver/_silver.yml)
[WARNING]: Got 1 result, configured to warn if != 0
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46

         tabela         | so_a_mao | so_dbt 
------------------------+----------+--------
 vendas_por_dia         |        0 |      0
 fct_vendas             |        0 |      0
 dim_produto            |        0 |      0
 pedidos da silver      |        0 |      0
 atendimentos da silver |        0 |      0
(5 rows)

 lado  | linhas | chaves 
-------+--------+--------
 a_mao |      8 |      8
 dbt   |      8 |      8
(2 rows)
```

Vamos ler. São 46 nós: 1 seed, 2 snapshots, 5 modelos de tabela, 6 de view e 32 testes de dado. Os dois avisos são de propósito: contam o status desconhecido e o custo nulo. A tabela de zeros compara as duas execuções nos dois sentidos, já com a chave `produto_sk`. O dbt não mudou o número. A dimensão tem 8 linhas, 7 versões e o membro `'-1'`. O snapshot `check` tem 7 linhas; o de `timestamp` tem 15, porque o ERP carimba o produto toda noite, mesmo sem mudar o preço.

Quer ver de onde `fct_vendas` lê? Este comando usa o `python3` da sua máquina. Sem ele, pule: nada adiante depende disso.

```bash
ls -la projeto_dbt/target/index.html projeto_dbt/target/catalog.json projeto_dbt/target/manifest.json | awk "{print \$5, \$9}" && python3 -c "import json; m = json.load(open(\"projeto_dbt/target/manifest.json\")); print(\"pais de fct_vendas:\", sorted(m[\"parent_map\"][\"model.rede_de_lojas.fct_vendas\"]))"
```

```text
pais de fct_vendas: ['model.rede_de_lojas.dim_loja', 'model.rede_de_lojas.dim_produto', 'model.rede_de_lojas.stg_itens', 'model.rede_de_lojas.stg_pedidos']
```

> Verificação: nível 3 pela execução e nível 2 por `dbt parse` e pelo SQL compilado, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Saída: `lab/saidas/lab5_projeto_dbt.txt`.

### Lab 6: Testes que param

"Se a carga vier duplicada, quem me avisa antes da diretoria?"

Pré-condição: Lab 5 concluído. Aqui `exit 1` é o resultado certo em três comandos.

Primeiro, dois defeitos de propósito, nos modelos `experimentos`:

```bash
docker compose --profile dbt run --rm dbt dbt build --select tag:experimento --vars '{experimentos: true}'
docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'
docker compose exec -T postgres psql -U dw -d dw -c "select 'sem_chave' as modelo, count(*) as linhas, count(distinct atendimento_id) as atendimentos from dbt_experimentos.exp_inc_sem_chave union all select 'com_chave', count(*), count(distinct atendimento_id) from dbt_experimentos.exp_inc_com_chave"
docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave --full-refresh --vars '{experimentos: true}'
```

```text
[ERROR]: in test unique_exp_fct_fan_out_venda_sk (models/experimentos/_experimentos.yml)
  Got 5 results, configured to fail if != 0
Done. PASS=5 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=6
[exit 1, 2026-11-03]

[ERROR]: in test unique_exp_inc_sem_chave_atendimento_id (models/experimentos/_experimentos.yml)
  Got 1 result, configured to fail if != 0
Done. PASS=3 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=4
[exit 1, 2026-11-03]

  modelo   | linhas | atendimentos 
-----------+--------+--------------
 sem_chave |      5 |            4
 com_chave |      4 |            4
(2 rows)

Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

O teste de grão pega o fan-out. O incremental sem chave duplica no reprocesso, e o `--full-refresh` refaz. Agora o caso principal. Dobre a carga de itens e rode os dois executores:

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile dbt run --rm dbt dbt build
docker compose exec -T postgres psql -U dw -d dw -c "select g.dia, g.receita_paga as gold_a_mao, d.receita_paga as gold_dbt from gold.vendas_por_dia g join dbt_gold.vendas_por_dia d using (dia) order by dia"
```

Saída esperada, em trechos:

```text
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       741.80
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
(3 rows)

[exit 0, 2026-11-03]

[ERROR]: in test unique_stg_itens__pedido_id_item_seq_ (models/silver/_silver.yml)
  Got 2 results, configured to fail if != 0
[ERROR]: in test assert_itens_batem_com_pedido (tests/assert_itens_batem_com_pedido.sql)
  Got 1 result, configured to fail if != 0
Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
[exit 1, 2026-11-03]

    dia     | gold_a_mao | gold_dbt 
------------+------------+----------
 2026-10-20 |     741.80 |   430.90
 2026-10-21 |     111.90 |   111.90
 2026-10-22 |     293.30 |   293.30
(3 rows)
```

Vamos ver por que dobrou e quem parou. O SQL à mão saiu com 0 e publicou 741,80. O dbt achou a chave repetida, saiu com 1 e pulou 15 nós, e a gold dele manteve 430,90. O teste não melhora o dado: impede que o dado ruim chegue ao número.

O SQL à mão não está errado por ser à mão. Faltou a ele o teste, e os testes do capítulo 13 cabem em SQL puro.

Agora conserte. Refaça a bronze e rode os dois de novo:

```bash
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/10_bronze_carga.sql -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile dbt run --rm dbt dbt build
```

```text
 executor | linhas_bronze | linhas_silver | receita_paga 
----------+---------------+---------------+--------------
 a_mao    |            11 |            10 |       836.10
 a_mao    |            11 |            10 |       836.10
 a_mao    |            11 |            10 |      1147.00
 a_mao    |            11 |            10 |       836.10
(4 rows)

Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]
```

O registro de carga guarda o 1147,00 da rodada ruim. É assim que você descobre depois quando o número mudou.

> Verificação: nível 3 pela execução e nível 2 por `dbt parse`, em 2026-11-03, em Linux, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `postgres:16.15-alpine`. Saída: `lab/saidas/lab6_testes_que_param.txt`.

### Lab 7: O dbt numa Dag

"O que o orquestrador faz quando o dbt para?"

Pré-condição: Lab 6 concluído e consertado, com espaço para a imagem de 2,65 GB. O código de limpeza continua no projeto dbt, fora do arquivo da Dag: o orquestrador não é o código de limpeza, é quem roda o código.

```bash
docker build --network host --progress=plain -f orquestrador/Dockerfile -t modelagem-lab-airflow-dbt:local .
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/12_bronze_itens_carga_dupla.sql
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -q -f /sql/10_bronze_carga.sql -f /sql/20_silver.sql -f /sql/30_gold.sql
docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"
```

Saída esperada, em trechos, sem o prefixo de log do Airflow:

```text
Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]

Done. PASS=27 WARN=2 ERROR=2 SKIP=15 NO-OP=0 REUSED=0 TOTAL=46
airflow.sdk.exceptions.AirflowException: Bash command failed. The command returned a non-zero exit code 1.
DagRun failed
[exit 1, 2026-11-03]

Done. PASS=44 WARN=2 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=46
[exit 0, 2026-11-03]
```

A Dag tem uma tarefa só, com `BashOperator`. O código de saída 1 do dbt vira `AirflowException`, e tarefa e execução falham. A mesma Dag volta ao sucesso depois do conserto do dado. Na captura, a imagem já estava em cache; na sua primeira vez, ela constrói o ambiente virtual do Python (virtualenv) do dbt.

> Verificação: nível 3, em 2026-11-03, em Linux, com `apache/airflow:3.3.2-python3.13`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. Saídas: `lab/saidas/lab7_orquestrador_construir_imagem.txt` e `lab/saidas/lab7_orquestrador_roda_dbt.txt`.

### Lab 8: Silver e gold em T-SQL

"Meu banco é SQL Server. Os mesmos tratamentos dão o mesmo número?"

**Antes do comando: a licença**

Este Lab roda o SQL Server na edição Developer. Leia os termos da versão que vai usar:

- SQL Server 2022: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- SQL Server 2025: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf

Os links de licença das páginas da imagem não levam ao termo da versão, então use estes. O que lemos, sem ser parecer jurídico:

- A Developer da 2022 pode ser instalada e usada em qualquer dispositivo para projetar, desenvolver, testar e demonstrar programas, e não pode ser usada em produção (seção 1.a.i).
- Os termos não citam contêiner. A Microsoft publica a imagem com Developer no registro e documenta como rodá-la.
- Os termos da 2025 mantêm o uso e dividem a edição em Enterprise Developer e Standard Developer.
- A seção 5 exige aprovação prévia por escrito da Microsoft para divulgar resultado de benchmark. Por isso as capturas têm só a data, e aqui não há tempo nem comparação de desempenho. Se você medir, não publique sem essa aprovação.

`ACCEPT_EULA=Y` é ato seu, de quem leu. Por isso o `docker-compose.yaml` não traz o aceite. Ao passar `Y` com uma edição em `MSSQL_PID`, você declara ter licença válida para aquela edição e versão.

Não confie na trava. O `${ACCEPT_EULA:?}` só barra a variável vazia ou ausente. A imagem 2022 subiu e ficou saudável com `N`, com um texto qualquer e com `1`. Nem a trava nem o contêiner de pé provam que alguém leu.

**Rodar**

Pré-condição: termos lidos, Docker com Compose e a memória que o `README.md` da pasta pede. O projeto é à parte e não depende dos outros Labs.

```bash
cd sqlserver
./preparar.sh
ACCEPT_EULA=Y ./roteiro.sh 2022
```

O roteiro parte de um volume vazio, roda cada etapa, grava a saída e derruba tudo com `docker compose down -v`. Ele reescreve `saidas/2022`: para guardar a sua rodada à parte, passe `SAIDA=<pasta>`. Um passo usa o `python3` da máquina. As etapas que criam os bancos, espelham os Labs 1 a 4 e conferem o resultado contra o Postgres são estas, nesta ordem:

```bash
./sq.sh master 00_erp_e_dw.sql -b
./sq.sh dw 10_bronze_carga.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-20
./sq.sh dw 20_silver.sql -b
./sq.sh dw 21_silver_antes_depois.sql
./sq.sh dw 22_fuso.sql
./sq.sh dw 30_gold.sql -b
./sq.sh dw 31_fan_out.sql
./sq.sh erp erp_noite_21.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-21
./sq.sh erp erp_noite_22.sql -b
./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-22
./sq.sh dw 20_silver.sql -b
./sq.sh dw 30_gold.sql -b
./sq.sh dw 40_preco_update_apaga.sql
./sq.sh dw 70_conferencia_postgres.sql
```

Depois vêm as etapas próprias do T-SQL: a etapa de texto e collation, datas em texto, nulos, deduplicação, `MERGE` e recarga, chave substituta, versões, sintaxe do Postgres que não passa, erro na recarga e texto só com tab. Cada uma tem arquivo em `lab/sqlserver/saidas/2022/`, e o capítulo 17 as lê.

Saída esperada, em trechos. Primeiro, a trava e o certificado, em `lab/sqlserver/saidas/2022/lab0_ambiente.txt`:

```text
$ env -u ACCEPT_EULA docker compose config --quiet
error while interpolating services.mssql.environment.ACCEPT_EULA: required variable ACCEPT_EULA is missing a value: read the SQL Server license terms linked in README.md, then rerun with ACCEPT_EULA=Y to accept them
[exit 1, 2026-11-03]

Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : SSL Provider: [error:0A000086:SSL routines::certificate verify failed:self-signed certificate].
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Client unable to establish connection. For solutions related to encryption errors, see https://go.microsoft.com/fwlink/?linkid=2226722.
[exit 1, 2026-11-03]
```

O segundo erro também é de propósito: sem `-C`, o `sqlcmd` recusa o certificado autoassinado do contêiner. Ele fica em `/opt/mssql-tools18/bin`; o caminho antigo, `/opt/mssql-tools/bin`, não existe nas imagens testadas. O `sq.sh` passa `-C` e usa a senha em `SQLCMDPASSWORD`, porque a documentação chama `-P` de inseguro.

Depois, a conferência contra o Postgres, em `lab/sqlserver/saidas/2022/lab5_conferencia_postgres.txt`:

```text
item|postgres|sql_server|resultado
----|--------|----------|---------
gold.dim_produto, linhas|8.00|8.00|bate
gold.dim_produto, membro -1|1.00|1.00|bate
gold.fct_vendas, vendas no membro -1|.00|.00|bate
receita paga, dia 20|430.90|430.90|bate
receita paga, total|836.10|836.10|bate
fan-out 1, receita dobrada|850.90|850.90|bate

(32 rows affected)
```

As 32 linhas dão `bate`, nenhuma `DIVERGE`. O mesmo vale na 2025 Enterprise Developer e na 2025 Standard Developer. A conferência não exercita a collation: quem testa isso é a etapa de texto e collation.

Na 2025, o `MSSQL_PID` decide a edição. A tabela da documentação lista `EnterpriseDeveloper` e `StandardDeveloper`, sem `Developer`, e o exemplo de Docker da mesma página passa `Developer`. Veja o que sobe de fato:

```bash
ACCEPT_EULA=Y ./roteiro.sh 2025
ACCEPT_EULA=Y ./edicoes_2025.sh
ACCEPT_EULA=Y MSSQL_PID=StandardDeveloper SAIDA=/tmp/standard ./roteiro.sh 2025
```

```text
MSSQL_PID=Developer
Enterprise Developer Edition (64-bit) 3
MSSQL_PID=EnterpriseDeveloper
Enterprise Developer Edition (64-bit) 3
MSSQL_PID=StandardDeveloper
Standard Developer Edition (64-bit) 2
```

O número é o `EngineEdition`. Essa saída está em `lab/sqlserver/saidas/2025/lab0_edicoes.txt`.

**O limite**

Rodou em Linux, em contêiner, com uma instância só. A réplica é um banco comum lido por sinônimos, sem grupo de disponibilidade. Não sabemos a versão, a edição, a collation nem a tecnologia de réplica do seu banco. Confira antes de copiar.

> Verificação: nível 3, em 2026-11-03, em Linux, com `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04` e `2025-CU10-ubuntu-24.04`. Comando: `ACCEPT_EULA=Y ./roteiro.sh 2022`, e os da 2025 acima. Termos em nível 1. O teste com outros valores de `ACCEPT_EULA` não está nas capturas. Saídas: `lab/sqlserver/saidas/2022/`, `lab/sqlserver/saidas/2025/` e `lab/sqlserver/saidas/diferencas_2025_enterprise_standard.txt`.

### Lab 9: Que SQL um relatório roda

"Como descubro de onde vem o número que o sistema mostra?"

**Antes do comando: a licença.** Este Lab também sobe o SQL Server 2022 Developer. Valem os termos e os avisos do Lab 8. Leia antes de passar `ACCEPT_EULA=Y`.

Pré-condição: termos lidos e a memória que o `README.md` da pasta pede. O projeto é à parte. Um sistema fictício gera um relatório de faturamento, e você descobre o que ele rodou.

```bash
cd linhagem
./preparar.sh
ACCEPT_EULA=Y ./rodar.sh
```

O `rodar.sh` roda do zero, reescreve `saidas/`, remove contêineres e volumes no fim e mantém as imagens. Depois, leia as capturas em `lab/linhagem/saidas/`. Comece por estas três.

No Postgres, em `lab/linhagem/saidas/pg_02_statements.txt`, o relatório rodou duas vezes com valores diferentes e virou uma linha, com `calls` igual a 2 e `trim(cliente) = $1`. Em geral o valor não fica ali, e isso não é garantia: veja o capítulo 18.

No SQL Server, em `lab/linhagem/saidas/mssql_01_extended_events.txt`, a sessão filtrada pelo nome da aplicação mostra a chamada com os valores:

```text
$ bin/ms sa -i /scripts/11_xe_ler_arquivo.sql
evento|aplicacao|login|objeto|texto
------|---------|-----|------|-----
rpc_completed|erp_relatorios|app_relatorio|faturamento_por_loja|exec relatorios.faturamento_por_loja '2026-10-20','2026-10-22'
```

No dbt, em `lab/linhagem/saidas/dbt_01_linhagem.txt`, a exposição (exposure) declarada à mão lista tudo o que alimenta o painel, até as fontes:

```text
$ # The exposure selects what feeds it, up to the sources.
docker compose --profile dbt run --rm -T --no-deps dbt dbt ls --select +exposure:relatorio_faturamento_diretoria --output name 2>&1 | grep -vE 'Running with|Registered adapter|Found ' || true
relatorio_faturamento_diretoria
mart_faturamento_por_loja
stg_itens
stg_lojas
stg_pedidos
erp.itens_pedido
erp.lojas
erp.pedidos
```

A mesma captura mostra `dbt docs serve` respondendo sem conta:

```text
/ 200 text/html
/manifest.json 200 application/json
/catalog.json 200 application/json
```

**O limite**

Rodou em Linux, em contêiner, contra uma aplicação fictícia. Nada foi testado em Windows, em Power Query nem no monitor de um ERP. A página gráfica de linhagem não foi aberta em navegador: a prova é o HTTP 200 de dentro do contêiner e o manifesto. Antes de ligar qualquer captura num banco de verdade, leia o capítulo 18.

> Verificação: nível 3, em 2026-11-03, em Linux. Comando: `ACCEPT_EULA=Y ./rodar.sh`, com `postgres:16.15-alpine`, `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. Saídas: `lab/linhagem/saidas/`.

### 20.2 Como deixo a máquina como estava?

"Terminei. O que sobra aqui?"

Pare e pense no que apaga. Este comando remove o contêiner, a rede e o volume do projeto. Todas as tabelas do laboratório vão junto: bronze, silver, gold, snapshots e registro de carga.

```bash
docker compose --profile dbt down -v
```

```text
 Container modelagem-lab-postgres-1  Removed
 Volume modelagem-lab_postgres-db-volume  Removed
 Network modelagem-lab_default  Removed
```

Ficam as imagens, o `.env` e os arquivos da pasta. Para refazer, volte ao Lab 0. Os Labs 8 e 9 já derrubam o próprio projeto no fim do roteiro. Se você subiu o Lab 8 à mão, o `README.md` da pasta traz o comando.

> Verificação: nível 3, em 2026-11-03, em Linux. Saída: `lab/saidas/lab0_subir_do_zero.txt`, em que as imagens seguem listadas depois do `down -v`.

Com roteiro, você viu o número certo, o número dobrado e quem parou. No próximo capítulo, o roteiro some: exercícios com entregável e critério de correção, e um mini-desafio para achar sozinho a causa de cada número. O gabarito comentado fica com o mentor.

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

## 22. Rubrica de validação da aprendizagem

"Como sei que aprendi, e não só que acompanhei?" A rubrica responde. Ela é o que o mentor usa na call. Sem ela, a avaliação vira impressão. Os níveis abaixo são critério da mentoria.

### 22.1 Como aplicar na call

**O que levar.** Leve o entregável do capítulo 21: a silver da tabela nova, com grão declarado, teste e registro do número. Leve também o mini-desafio resolvido.

**Como funciona na prática.** O mentor escolhe uma regra do seu entregável e pergunta por que ela está ali. Depois pede para você rodar a consulta que prova. Vale o que você mostra e explica, não o que você diz que sabe.

**Como ler o resultado.** Cada critério recebe um nível pela evidência vista na call. Insuficiente não é reprovação. Ele aponta o capítulo que você vai rever. Suficiente em todos os critérios já sustenta o trabalho do dia a dia. Excelente é o que se espera de quem revisa o SQL de outra pessoa.

### 22.2 Os critérios

Vamos ao exemplo que serve de régua. No critério "declara o grão", o insuficiente descreve a tabela pelo relatório: "é a tabela de faturamento". O suficiente escreve a frase antes do SQL: "uma linha é um item de pedido". O excelente prova com consulta e diz o que a frase impede: somar a uma fato de item um valor que está no grão do pedido.

| Critério | Insuficiente | Suficiente | Excelente |
|---|---|---|---|
| Declara o grão (cap. 5) | Descreve a tabela pelo relatório. | Escreve a frase antes do SQL. | Prova com consulta e diz o que a frase impede. |
| Usa critério no nulo e no `CASE` (cap. 7) | Troca todo nulo por zero. Escreve `CASE` sem `ELSE`. | Decide nulo por coluna, com motivo. O `ELSE` trata o valor novo. | Separa o nulo que deve alertar do que tem valor padrão, e escreve o teste que conta. |
| Converte fuso (cap. 8) | Lê o dado em UTC como hora local, ou converte sem saber a origem. | Converte de UTC para `America/Sao_Paulo` uma vez, num lugar só. | Usa um caso como o atendimento depois do fechamento para provar o sentido da conversão. |
| Deduplica por chave (cap. 6) | Esconde a duplicata com `DISTINCT`. | Define a chave e a regra de qual linha fica. | Mostra as duplicatas antes, conta as que saíram e explica de onde vieram. |
| Monta estrela sem fan-out (cap. 9 e 10) | Faz o JOIN e confia no resultado porque não deu erro. | Confere o grão de cada lado antes do JOIN e prova que o resultado não multiplicou linha. | Reconcilia o total da fato com a origem e acha a causa de um número dobrado. |
| Escolhe a forma do histórico (cap. 11 e 12) | Usa `UPDATE` sem perceber o que foi apagado. | Escolhe entre tipo 1 e tipo 2 pela pergunta do negócio, com um filtro de vigência que devolve uma versão só em qualquer dia. | Liga a venda à versão certa, conta o que caiu no membro desconhecido e explica o custo da chave escolhida. |
| Testa grão e chaves (cap. 13) | Não testa, ou olha o resultado a olho. | Tem teste de unicidade, de nulo e de relação, cada um procurando as linhas que desmentem a regra. | Mostra um teste falhando de propósito e diz quem é avisado quando ele falha. |
| Decide o degrau por um sinal (cap. 19) | Escolhe a ferramenta porque ouviu falar dela. | Cita um sinal observado no próprio cenário e decide manter ou subir. | Compara custo e risco dos dois degraus e diz o que faria mudar a decisão. |
| Registra o número (cap. 18) | O número só existe no relatório. | Escreve regra, grão e dono junto do SQL. | Refaz o caminho do número até a origem e explica uma divergência entre dois relatórios. |

**O equívoco comum.** Tratar a tabela como lista de ferramentas decoradas. Nenhum critério pede dbt. Você pode chegar a excelente com SQL à mão, se a evidência estiver lá.

**Como inspecionar.** Antes da call, percorra a tabela sozinho. Para cada critério, separe a consulta ou o trecho que mostra o nível. Onde nada aparecer, comece por lá.

Quando um critério ficar abaixo do esperado, o capítulo seguinte ajuda a achar o erro pelo sintoma.

## 23. Erros comuns e como corrigir

"O número saiu errado e nada deu erro. Por onde começo?" Pelo sintoma. Cada tabela é um momento do trabalho e vai do que você vê até o capítulo que explica.

Vamos ao exemplo que serve de régua:

- **Sintoma:** a receita dobrou e nenhum erro apareceu.
- **Causa:** JOIN no grão errado.
- **Correção:** agregue antes do JOIN e teste o grão.

**O equívoco comum**

"Não deu erro, então está certo." O banco confere a sintaxe. Ele não sabe o que uma linha deveria significar. Por isso a frase guia vem antes de qualquer correção: antes do SQL, decida o que uma linha significa.

**Como ler as tabelas**

A prova de cada causa está na verificação da seção. A coluna de correção é critério da mentoria. Fora das linhas do dbt, nada aqui pede ferramenta.

### 23.1 Ao subir o ambiente

"Nem subiu. O que eu errei?" Estes dois dão erro, e esse é o caso bom: você descobre na hora.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| `dbt debug` falha com `Required var 'experimentos' not found in config`, mesmo com a variável no bloco `vars`. | `var()` usado no `dbt_project.yml` não enxerga o bloco `vars` do próprio arquivo. | Dê um valor padrão: `var('experimentos', false)`. | 15 |
| `sqlcmd` termina com `certificate verify failed` e saída 1. | Sem `-C`, ele recusa o certificado autoassinado do contêiner. | No contêiner do laboratório, use `-C`, com a senha em `SQLCMDPASSWORD`. A doc chama `-P` de inseguro. | 17 |

> Verificação: nível 3. `var()`: em 2026-11-04, `dbt debug`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, numa cópia que só tira o valor padrão (`lab/checagens/var_sem_padrao/dbt_project.yml`), saída em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`; `lab/saidas/lab5_projeto_dbt.txt` mostra o projeto com o valor padrão. `sqlcmd`: em 2026-11-03, com e sem `-C`, SQL Server 2022 Developer, saída em `lab/sqlserver/saidas/2022/lab0_ambiente.txt`.

### 23.2 Na silver

"A carga rodou sem erro. O dado está limpo?" O log não responde. Estes são os que passam em silêncio.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| Usou `DISTINCT` e a duplicata continua: 11 linhas seguem 11. | `DISTINCT` só remove linha idêntica. As duas versões do pedido 103 diferem no status e nas datas. | Deduplique por chave, com desempate explícito: `row_number() OVER (PARTITION BY id ORDER BY _carregado_em DESC)`. Ficam 10. | 6 |
| A soma não mudou, mas a média caiu de 44,00 para 36,67. | `COALESCE(valor, 0)` escondeu a falha de origem: `count(valor)` dá 5 e `count(*)` dá 6. | Deixe a medida nula. Conte os nulos e avise. | 7 |
| Um status novo vira nulo, sem aviso. | `CASE` sem `ELSE` devolve nulo quando nenhuma condição casa: `estornado` saiu nulo. | Escreva `ELSE` com nome, como `'desconhecido'`, e um teste que conta esse valor. | 7 |
| O horário fica 3 horas fora, e o dia pode mudar. | Sentido errado ou conversão dupla. Para `2026-10-21 00:30` em UTC, o certo é 21:30 do dia 20. Só `AT TIME ZONE 'America/Sao_Paulo'` dá o instante 03:30 UTC, 3 horas depois. Duas conversões dão 18:30, 3 horas antes. | Converta uma vez, na silver: `x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'`. | 8 |
| Escreveu `AT TIME ZONE '-03'` e veio 03:30 em vez de 21:30. | Em texto, `'-03'` é especificação POSIX, positiva a oeste, e dá UTC+3. | Use o nome `America/Sao_Paulo`, ou `interval '-03:00'`. | 8 |
| Data de 1900 no SQL Server, ou zero onde não havia número. | Em `TRY_CONVERT`, texto vazio não vira `NULL` em `date` nem em `int`: dá 1900-01-01 e 0. | `NULLIF(TRIM(x), N'')` cobre vazio e espaços. Para tab, passe ao `TRIM` a lista de caracteres. | 17 |
| Rótulo cortado no SQL Server: `'de'` no lugar de `'desconhecido'`. | `ISNULL` usa o tipo do primeiro argumento e trunca, aqui `varchar(2)`. | Use `COALESCE`, que usa o tipo de maior precedência. | 7 e 17 |

> Verificação: nível 3, em 2026-11-03. Postgres 16.15 (`postgres:16.15-alpine`), com `docker compose exec -T postgres psql -U dw -d dw -f /sql/<arquivo>`: `21_silver_antes_depois.sql` para `DISTINCT` e `CASE`, saída em `lab/saidas/lab1_silver_a_mao.txt`; `22_fuso.sql` para fuso e `'-03'`, saída em `lab/saidas/lab2_fuso_e_datas.txt`. Média do `COALESCE`: conta avulsa, fora dos scripts do laboratório. SQL Server 2022: `./sq.sh dw 61_datas_em_texto.sql` e `./sq.sh dw 62_nulos.sql`, saídas em `lab/sqlserver/saidas/2022/lab7_datas_em_texto.txt` e `lab/sqlserver/saidas/2022/lab8_nulos.txt`; o tab com `./sq.sh dw 69_datas_com_tab.sql`, na 2022 e na 2025, em `lab/sqlserver/saidas/2022/lab15_datas_com_tab.txt` e `lab/sqlserver/saidas/2025/lab15_datas_com_tab.txt`. A doc registra o texto vazio só para `numeric` e `decimal`: em `date` e `int`, é comportamento observado.

### 23.3 Na gold

"O total parece errado, e a consulta roda. Onde olho?" Primeiro no grão. Vamos ver por que o número mudou sem que nada reclamasse.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| A receita do dia 20 foi de 430,90 para 850,90, e nenhum erro apareceu. 6 linhas viraram 9. | Fan-out, o JOIN que multiplica linhas: um produto com dois fornecedores repete os itens dele. | Agregue antes do JOIN e teste o grão: `GROUP BY chave HAVING count(*) > 1`. | 5 e 10 |
| Trocou por `SUM(DISTINCT)` e agora falta dinheiro: 716,10 contra 836,10. | `SUM(DISTINCT)` descarta venda legítima de mesmo valor: 120,00 aparece em dois itens. | Agregue cada lado no próprio grão antes do JOIN: 836,10 contra 836,10. | 10 |
| A venda do dia da troca de preço conta em dobro: o item de 80,00 soma 160,00. | `BETWEEN` usa intervalo fechado, e o fim de uma versão é o início da seguinte. | Use intervalo meio aberto: `dia >= valido_de AND dia < valido_ate`. | 11 |
| Teste verde, e há venda sem versão do produto na dimensão. | `relationships` ignora nulo, como `unique` e `accepted_values`. Num teste à parte, sem arquivo publicado, com duas vendas sem versão, `not_null` falhou com 2 e `relationships` passou. | Ponha `not_null` ao lado. Com o membro `'-1'`, os dois passam, então acrescente um teste que conta: ele acusou `WARN 2`. | 12 e 13 |

> Verificação: nível 3, em 2026-11-03. Postgres 16.15, com o mesmo comando: `31_fan_out.sql` para fan-out e `SUM(DISTINCT)`, saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`; `40_preco_update_apaga.sql` para `BETWEEN`, saída em `lab/saidas/lab4_preco_update_e_scd2.txt`. `relationships`: num teste à parte, sem arquivo publicado, com `dbt build`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. O `WARN 2`, em 2026-11-04, em `lab/saidas/lab9_dbt_venda_sem_versao.txt`. Vale para o dbt v1: a implementação no v2 não foi conferida.

### 23.4 Na carga

"Rodei de novo. O que mudou na tabela?" Aqui o erro aparece na segunda execução, ou no código de saída que ninguém leu.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| O modelo rodou de novo, sobre a janela de reprocessamento, e ficou com 5 linhas para 4 atendimentos. | Incremental sem `unique_key` só acrescenta, na maioria dos adaptadores. | Declare `unique_key`: no laboratório, o adaptador usou `delete+insert` e ficou com 4. Regra alterada pede `--full-refresh`. | 14 |
| Reprocessou com `ON CONFLICT` e duplicou assim mesmo. | No Postgres, por padrão, dois nulos não colidem em `UNIQUE`, e o `ON CONFLICT` não vê o conflito: 2 linhas. | Não aceite nulo na chave, ou use `UNIQUE NULLS NOT DISTINCT`: 1 linha. | 14 |
| O lote traz a mesma chave duas vezes, e o resultado depende do comando. | No Postgres, `ON CONFLICT DO UPDATE` recusa com `cannot affect row a second time`. `DELETE ... USING` e `INSERT` gravam as duas, sem erro. `MERGE`: cardinalidade se a chave já existe no alvo; unicidade se é nova e há `UNIQUE`; duas linhas se é nova e não há. | Deduplique o lote no próprio grão antes de gravar, e mantenha `UNIQUE` no destino. | 14 |
| O script falhou no meio, apagou a carga anterior, gravou metade da nova e devolveu 0. | Por padrão, o `psql` continua depois do erro e sai com 0. | `psql -v ON_ERROR_STOP=1 --single-transaction`: sai com 3 e preserva o estado anterior. Só a variável deixa a tabela pela metade. Só `--single-transaction` desfaz, mas sai com 0. | 19 |
| No `sqlcmd`, a recarga com erro sai com 0 e a carga parcial fica. | Sem `-b`, o código de saída não muda. Sem `SET XACT_ABORT ON`, a carga parcial é gravada. | Use os dois: saída 1 e estado preservado. O par protege contra erro do motor e contra `THROW`, e não equivale ao do `psql`: com `RAISERROR`, o `COMMIT` roda e a carga parcial fica. `TRY/CATCH` que engole o erro sai com 0 mesmo com `-b`. | 17 |
| A origem só mostra 20,00 para um item vendido a 20,50 dois dias antes. | O `UPDATE` noturno apagou o preço anterior. | Se o negócio pergunta pelo preço da data, guarde a foto diária crua na bronze e monte a vigência na silver: 15 linhas de foto viram 7 versões. | 11 |

> Verificação: nível 3, em 2026-11-03. Incremental: `docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, saída em `lab/saidas/lab6_testes_que_param.txt`. `UPDATE`: `40_preco_update_apaga.sql`, saída em `lab/saidas/lab4_preco_update_e_scd2.txt`. Chave com nulo e lote: `76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`, 2026-11-04. `psql`: `79a` a `79c`, saída em `lab/saidas/lab9_psql_erro.txt`, 2026-11-04. `sqlcmd`: SQL Server 2022 e 2025, `./sq.sh dw 64c_recarga_sem_xact_abort.sql` e `./sq.sh dw 64d_recarga_com_xact_abort.sql`, com e sem `-b`, saída em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`; `RAISERROR`, `THROW` e `TRY/CATCH` com `./sq.sh dw 68a_recarga_raiserror.sql -b`, `68b_recarga_throw.sql -b` e `68c_recarga_try_catch.sql -b`, saídas em `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt` e `lab/sqlserver/saidas/2025/lab14_erro_na_recarga.txt`.

No `dbt-postgres`, a macro do `delete+insert` insere o lote inteiro, sem deduplicar. Lemos isso no código (nível 1) e não executamos.

### 23.5 Na organização

"Dois relatórios, dois números. Qual está certo?" Antes de escolher um, descubra quantas vezes a regra foi escrita.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| Mesmos dados, dois números: 130,00 e 170,00. | A mesma regra em dois lugares: `status = 'pago'` num, `lower(trim(status)) = 'pago'` no outro. | Cada regra num lugar só: em SQL no banco, na silver. O relatório lê pronto. | 6 e 19 |

> Verificação: nível 3 como simulação, `postgres:16.15-alpine`, em 2026-11-03, fora dos scripts do laboratório. As duas regras estão em SQL. Não executamos Power Query.

Não achamos página do Microsoft Learn sobre regra duplicada entre Power Query e SQL. A recomendação mais próxima, centralizar a preparação do Power Query num dataflow para chegar a uma fonte única da verdade, está na seção 6.6.

### 23.6 E quando o sintoma não está aqui?

"O meu erro não aparece em nenhuma tabela. E agora?" Critério da mentoria: três perguntas, nesta ordem.

1. **O que uma linha significa?** Escreva o grão do resultado e rode o teste da chave repetida.
2. **Onde o número mudou?** Compare `count(*)` e a soma antes e depois de cada etapa. Numa etapa que não filtra, não deduplica e não agrega, `count(*)` não deveria mudar. Se mudou, ache a linha que entrou ou saiu.
3. **O que acontece quando falha?** Provoque a falha de propósito. Confira o código de saída e o estado da tabela.

**O limite destas tabelas.** Tudo rodou em Linux, em contêiner. Nada rodou em Windows nem em Power Query. Não conhecemos a versão, a edição e a collation do seu banco. Confirme o sintoma no seu ambiente antes de aplicar a correção.

Achar o erro pelo sintoma resolve o que está na sua frente. O capítulo seguinte olha para o próximo passo, por perfil.

## 24. Plano de continuidade

"Terminei. E agora?" Depende de onde você está. Aqui há um próximo passo por perfil e o que vem depois na trilha. Falamos de conceito, não de módulo: nada aqui promete material com data.

### 24.1 Qual é o meu próximo passo?

"Tenho pouco tempo. Por onde sigo?" Escolha a sua linha. O caminho é critério da mentoria.

| Se você | Próximo passo |
|---|---|
| quer só entender do que se trata | Guarde a frase guia. Na próxima tabela que aparecer, pergunte o que uma linha significa. |
| gerencia e quer decidir | Leve ao time as perguntas do capítulo 19. |
| está começando na área | Refaça os Labs 0 a 6 sem olhar a saída. Depois, o exercício prático do capítulo 21. |
| já trabalha com dados | Refaça a silver com uma tabela da própria empresa, em ambiente seu. |
| é engenheiro e mira o próximo nível | Rode o Lab 7 e deixe escrita a decisão sobre a geração do dbt, na seção 24.4. |

### 24.2 Como levo isso para a minha empresa?

"O meu cenário não é a rede de lojas. Como começo?"

**Quem gerencia** começa, por critério da mentoria, pelas perguntas que vêm antes do SQL: o que uma linha significa e quem é dono do número. Se ouvir "depende" ou "todo mundo", você achou o próximo passo.

**Quem é da área** refaz a silver. O roteiro é critério da mentoria:

1. Traga uma tabela só para um banco seu, descartável. Nunca escreva na produção nem na réplica.
2. Confirme se a empresa permite a cópia. Sem permissão, ou com dado pessoal, use a mesma estrutura com dado inventado.
3. Escreva o grão antes do SQL.
4. Trate nulo, texto, data e fuso (capítulos 6 a 8; no SQL Server, também o 17), com um teste de dado para cada regra (capítulo 13).
5. Compare contagem e total com a origem.

Não conhecemos a versão, a edição nem a collation do seu banco, e o laboratório só rodou em Linux. Confira cada receita no seu ambiente.

**O equívoco comum.** Esperar a ferramenta para começar. SQL à mão serve, e nenhum critério da rubrica do capítulo 22 pede dbt.

### 24.3 O que fica para os próximos conceitos?

"Sobrou assunto. Quem cuida do resto?" Quatro vizinhos. Confira na trilha o que já está disponível.

| Conceito | O que ele responde | O que você leva daqui |
|---|---|---|
| Orquestração | Quem roda o código, em que ordem e a que horas. | O SQL que você validou vira tarefa. |
| Ingestão e captura de mudanças (CDC, change data capture) | Como o dado chega da origem. | A bronze que recebe e a pergunta: a foto diária ainda atende? |
| Qualidade e governança | Contratos, integração contínua (CI, continuous integration) e testes a fundo. | Os testes do capítulo 13 e o registro do número do capítulo 18. |
| Entrega e IA | Como o número chega a quem pergunta, com a camada semântica. | A estrela e a definição do número. |

**A ponte com a Orquestração.** No Lab 7, a Dag chama o `dbt build` por `BashOperator`, com o dbt num ambiente virtual do Python (virtualenv) criado na construção da imagem. Vamos ver o que acontece quando o dado quebra. Com itens duplicados, o dbt sai com código 1. Isso vira `AirflowException`, e a tarefa e a execução da Dag falham. Refeita a bronze, a mesma Dag volta ao sucesso.

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com Airflow 3.3.2 (imagem `apache/airflow:3.3.2-python3.13`), `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, contra Postgres 16.15. Comando: `docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"`. Três execuções em `lab/saidas/lab7_orquestrador_roda_dbt.txt`: `success`, `failed` (`ERROR=2`) e `success`.

**A ponte com a entrega.** Com camada semântica, o guia de marts do dbt muda a recomendação: em vez de tabela larga, o mart fica o mais normalizado possível. A terminologia do dbt descreve essa camada como motor de desnormalização (denormalization engine). Inferência: quando ela entrar, reabra a escolha do capítulo 9. Critério da mentoria: pergunta feita a uma IA pede a mesma definição do número do capítulo 18.

### 24.4 Engenheiro: o dbt v1 vai acabar?

"Fico no v1 ou já migro?"

**O que é.** A dbt Labs já anunciou qual será a última versão menor da linha 1.x (número no capítulo 16). O suporte crítico, de segurança e instalação, vai além da janela normal de um ano, sem data de corte definida e com expectativa de 3 a 5 anos. Ficar no v1 é caminho suportado ("remains fully supported"), mas recursos novos chegam só no v2.

**Como funciona na prática.** Para migrar, a documentação pede quatro coisas: resolver os avisos de depreciação, com o `dbt-autofix` para os que se corrigem automaticamente; testar o projeto com a flag opcional (opt-in) `--use-v2-parser`, na versão indicada no post das distribuições; ter adaptador e autenticação suportados; rodar na última versão do v1 sem avisos de depreciação nem erros. Não verificado: nada disso foi executado aqui.

Sem data de corte, a data precisa ser sua. Critério da mentoria: marque no calendário o dia de reabrir a decisão, com um dono. Nesse dia, responda:

1. O adaptador do seu banco é suportado no v2? Comece pelo capítulo 16.
2. O projeto roda na última versão do v1 sem aviso?
3. Que recurso novo faz falta hoje, com um exemplo?

Inferência: se a primeira resposta for não, a migração espera. Registre o motivo.

**O equívoco comum.** Ler "última versão menor" como fim do suporte. A fonte diz o contrário.

### 24.5 E o Data Vault?

"Devia ter visto Data Vault?" Não aprofundamos, de propósito. Data Vault é um padrão de modelagem para armazém corporativo, com hubs (chaves de negócio), links (relações) e satellites (atributos descritivos e histórico), que a Databricks coloca na silver do medalhão. A fonte é um post de fornecedor; o livro e o padrão de Linstedt não foram abertos.

### 24.6 O que guardar?

"Se eu esquecer tudo, o que fica?" Uma frase: antes do SQL, decida o que uma linha significa. Quando um termo travar no caminho, o capítulo seguinte tem a definição em uma frase.

## 25. Glossário

"Esqueci o que esse termo quer dizer. Onde confiro sem reler o capítulo?" Aqui. Cada termo tem uma definição curta, na mesma grafia dos capítulos. Use a lista para consultar e para alinhar a conversa com o time. Quando duas pessoas usam a mesma palavra com sentidos diferentes, o número também diverge.

Antes do SQL, decida o que uma linha significa. Por isso, se for ler só um termo, leia **Grão**, em 25.2.

### 25.1 Camadas

"Em que camada isto fica?"

- **Arquitetura medalhão:** Organização do dado em camadas de qualidade crescente: bronze, silver e gold. Prática recomendada, não requisito.
- **Bronze:** Camada do dado cru, como chegou da origem, com validação mínima.
- **Silver:** Camada do dado limpo e validado. Na mentoria, onde mora a regra que conserta registro a registro sem mudar o grão.
- **Gold:** Camada pronta para o negócio. Na mentoria, onde mora o que junta ou agrega, como a estrela.

### 25.2 Modelo

"O que uma linha significa, e como as tabelas se ligam?"

- **Grão:** O que uma linha da tabela significa. Na fato de vendas, um item de pedido.
- **Fato:** Medição de um evento de negócio, quase sempre numérica.
- **Dimensão:** Contexto do evento, com os atributos usados para filtrar e agrupar.
- **Medida:** Coluna numérica da fato que se resume.
- **Chave natural:** Identificador que vem do sistema de origem.
- **Chave substituta:** Chave própria da dimensão, sem significado de negócio, que identifica uma versão da linha.
- **Esquema estrela:** Modelo dimensional em banco relacional: fatos ligadas às dimensões por chave.
- **One big table:** Uso de mercado para uma tabela só, com todas as colunas de um conceito. Aqui, camada de consumo sobre a estrela.
- **Fan-out:** Nome de uso corrente para o JOIN que multiplica linhas porque uma das tabelas tem mais de uma linha por chave.
- **Drilling across:** Técnica do Kimball que busca respostas separadas em cada fato e as junta pelos atributos comuns.

### 25.3 Histórico

"O valor mudou. Como guardo o que ele era antes?"

- **SCD:** Dimensão de mudança lenta (slowly changing dimension): técnica para tratar o atributo que muda.
- **SCD tipo 1:** Sobrescreve o valor e perde o histórico.
- **SCD tipo 2:** Cria uma linha nova a cada mudança, com início e fim de vigência.
- **Vigência:** Período em que uma versão vale.
- **Intervalo meio aberto:** Vale do início, inclusive, até o fim, exclusive: `>=` e `<`.
- **Foto:** Cópia agendada do estado de uma tabela num dia. Fica crua na bronze.
- **Snapshot:** Palavra com três sentidos: fato periódica no Kimball, SCD tipo 2 no dbt, carga inicial no CDC.
- **Membro desconhecido:** Linha da dimensão, aqui com chave `'-1'`, que recebe o fato sem versão correspondente.

### 25.4 Transformação

"Como o SQL vira objeto no banco, e o que acontece quando roda de novo?"

- **Modelo:** No dbt, um `SELECT` salvo em arquivo, que vira objeto no banco ao rodar.
- **Materialização:** Estratégia para guardar o resultado do modelo no banco: view, table, incremental.
- **View:** Consulta salva: não guarda dado e roda a cada uso.
- **Table:** Resultado gravado em tabela, refeito a cada execução.
- **Incremental:** Modelo que processa só parte dos dados a cada execução, sobre o que já existe.
- **Idempotência:** Rodar de novo dá o mesmo resultado de rodar uma vez.
- **ELT:** Extrair, carregar e transformar no destino, com o processamento dele.

### 25.5 Testes

"Como provo que o número está certo, e de onde ele veio?"

- **Teste de dado:** Consulta que busca as linhas que desmentem uma regra; zero linhas, passou.
- **Linhagem:** Como o dado se move, onde é transformado e onde é consumido.
- **Definição do número:** O que o número significa, com regra, grão e dono, escrita junto do SQL.

### 25.6 Ferramenta e banco

"Esse nome é do dbt, do Postgres ou do SQL Server?"

- **OLTP:** Banco que grava transações, muito normalizado para isso.
- **Réplica:** Cópia do banco mantida pela replicação; aceitar leitura depende da tecnologia. Em hot standby no Postgres, não aceita escrita nenhuma.
- **Adaptador:** Pacote que liga o dbt a um banco específico.
- **dbt v1 e dbt v2:** As duas gerações do dbt. A v1 é a linha 1.x; a v2 é a geração nova, com as distribuições `dbt` e `dbt-oss`.
- **T-SQL:** O dialeto SQL do SQL Server.
- **Collation:** Regra do banco para ordenar e comparar texto: caixa, acento, página de código.
- **Query Store:** Recurso do SQL Server que guarda, por banco, consultas, planos e contagens.
- **Extended Events:** Recurso do SQL Server para capturar eventos, com filtro, por uma sessão criada para isso.

Com os termos à mão, a seção seguinte reúne as referências e as fontes para você conferir cada afirmação na origem.

## Referências

"Quero ir à fonte. Por onde começo?" Comece por estas páginas. São a documentação principal do que vimos, abertas em 2026-11-03. A lista completa, por grupo, vem na seção seguinte.

Critério da mentoria: leia primeiro o grão e os quatro passos. A ferramenta vem depois.

**Modelagem dimensional**

- Kimball Group, grão. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/ (consulta em 2026-11-03)
- Kimball Group, quatro passos. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/four-4-step-design-process/ (consulta em 2026-11-03)
- Kimball Group, tipo 2. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/ (consulta em 2026-11-03)
- Microsoft Learn, estrela no Power BI. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema (consulta em 2026-11-03)

**Camadas**

- Databricks, medalhão. https://docs.databricks.com/aws/en/lakehouse/medallion (consulta em 2026-11-03)

**dbt**

- Modelos. https://docs.getdbt.com/docs/build/models (consulta em 2026-11-03)
- Materializações. https://docs.getdbt.com/docs/build/materializations (consulta em 2026-11-03)
- Testes de dado. https://docs.getdbt.com/docs/build/data-tests (consulta em 2026-11-03)
- Snapshots. https://docs.getdbt.com/docs/build/snapshots (consulta em 2026-11-03)
- Versões. https://docs.getdbt.com/docs/dbt-versions (consulta em 2026-11-03)

**Bancos**

- PostgreSQL 16, data e hora. https://www.postgresql.org/docs/16/functions-datetime.html (consulta em 2026-11-03)
- PostgreSQL 16, `pg_stat_statements`. https://www.postgresql.org/docs/16/pgstatstatements.html (consulta em 2026-11-03)
- SQL Server, `MERGE`. https://learn.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql (consulta em 2026-11-03)
- SQL Server, Query Store. https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver16 (consulta em 2026-11-03)

Documentação muda. Antes de decidir por uma versão ou um preço, abra a página de novo e confira a data.

## Fontes verificadas (2026-11-04)

"Como confiro de onde veio cada afirmação?" Uma linha por afirmação factual que sustenta os capítulos, agrupadas por fonte. As páginas foram abertas em 2026-11-03. Em 2026-11-04, abrimos de novo as de `COALESCE` e `NULLIF`, de `pg_input_is_valid`, de horário corrente, do `psql` e de snapshot do dbt, e pela primeira vez as de schema customizado e de teste unitário do dbt e as duas da apostila de Orquestração. As definições do glossário são resumos da mentoria. Abra a página que sustenta o ponto que você vai levar ao time.

### Modelagem dimensional (Kimball Group)

- O `UPDATE` noturno apaga o preço anterior; as fotos guardam 15 linhas, e o tipo 2 derivado delas, 7. Saída `lab/saidas/lab4_preco_update_e_scd2.txt`. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/
- SCD tipo 2 cria linha nova com chave substituta nova e pede início, fim e indicador de vigência. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/
- SCD tipo 2 e o preço que o `UPDATE` apaga. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/
- Tipo 2, linha nova a cada mudança. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/
- Grão como passo central do desenho dimensional, declarado antes de dimensões e fatos. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/
- O grão diz o que uma linha da fato representa, vem antes de dimensões e fatos, grãos diferentes não se misturam e o grão atômico resiste a consultas imprevisíveis. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/
- Declarar o grão é o passo central do desenho dimensional e vem antes de dimensões e fatos. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/
- Fato como medição de um evento de negócio. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/facts-for-measurement/
- Fato como medição, ligada a um evento físico observável, com medidas coerentes com o grão. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/facts-for-measurement/
- Fato como medição de um evento físico, coerente com o grão. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/facts-for-measurement/
- Dimensão como contexto para filtrar e agrupar. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimensions-for-context/
- Dimensão como contexto, com um único valor para cada linha da fato sempre que possível. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimensions-for-context/
- Dimensão como contexto, com valor único por linha da fato. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimensions-for-context/
- A dimensão deve ter, sempre que possível, um único valor para cada linha da fato. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimensions-for-context/
- As quatro decisões do desenho dimensional, nesta ordem. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/four-4-step-design-process/
- Medida nula na fato, funções de agregação e chave estrangeira com linha padrão. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/fact-table-null/
- Linha padrão para chave estrangeira nula. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/fact-table-null/
- Atributo descritivo nulo vira texto, porque bancos agrupam e filtram nulo de forma inconsistente. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/null-dimension-attribute/
- Chave primária da dimensão, inteiro sem significado e isenção da dimensão de data. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimension-surrogate-key/
- Chave natural não é chave primária da dimensão; inteiros sem significado, em sequência a partir de 1; dimensão de data isenta. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimension-surrogate-key/
- Chave natural e chave substituta. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/dimension-surrogate-key/
- Esquema estrela como modelo dimensional em banco relacional. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/star-schema-olap-cube/
- O BI nunca deve juntar duas fatos pelas chaves estrangeiras; drilling across. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/multipass-sql/
- Juntar dois lados "muitos" e responder em passadas separadas (drilling across). https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/multipass-sql/
- Respostas separadas, juntadas pelos atributos comuns, em vez de juntar duas fatos. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/multipass-sql/
- SCD tipo 1 sobrescreve e destrói o histórico, com recálculo de agregados. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-1/
- Snapshot como fato periódica no Kimball. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/periodic-snapshot-fact-table/
- Snapshot no Kimball. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/periodic-snapshot-fact-table/
- Largura e suspeita sobre o join. https://www.kimballgroup.com/1998/05/surrogate-keys/
- Melhora por fatos e índices menores. https://www.kimballgroup.com/2003/10/fistful-of-flaws/
- Linha provisória para fato que chega antes. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/late-arriving-dimension/
- "You don't need to store the unit price". https://www.kimballgroup.com/2003/01/fact-tables-and-dimension-tables/

### Microsoft: Power BI, Fabric e arquitetura

- A estrela com o grão escrito devolve 430,90, 111,90 e 293,30, e a one big table como view sobre ela tem 13 linhas e 836,10. Saída `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema
- Power BI: classificar cada tabela como dimensão ou fato, grão consistente, e valores das chaves que determinam o grão, com o exemplo da meta mensal. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema
- Visual que filtra, agrupa e resume, lados "um" e "muitos", não misturar os tipos e grão consistente. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema (página datada de 2024-12-30, metadados de atualização de 2026-04-01)
- Atributo que muda muito como medida na fato; atualização não incremental como tipo 1; sistema intermediário, busca da versão vigente na data do fato e limite do Power Query; dificuldade com SCD e recomendação de armazém. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema
- Busca por tempo relevante à data do fato, "It should never be summed". https://learn.microsoft.com/en-us/power-bi/guidance/star-schema
- Power Query difícil com grande volume ou SCD; atualização não incremental com efeito de tipo 1; sistema intermediário e busca da versão vigente na data do fato; modelo semântico carrega dimensão tipo 2 pronta. https://learn.microsoft.com/en-us/power-bi/guidance/star-schema
- A Microsoft recomenda centralizar a preparação do Power Query num dataflow, para chegar a uma fonte única da verdade; a página, de 2024-12-30, trata do Dataflow Gen1, legado, e indica o Gen2. A divergência de 130,00 e 170,00 é simulação em SQL da mentoria e não vem dessa página. https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-self-service-data-preparation
- Tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow; a página trata do Dataflow Gen1, em estado legado, e indica o Gen2 (ms.date 2024-12-30). https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-self-service-data-preparation
- Centralizar a preparação do Power Query num dataflow, fonte única da verdade; a página trata do Dataflow Gen1, legado, e indica o Gen2 (ms.date 2024-12-30). A divergência de 130,00 e 170,00 é simulação em SQL. https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-self-service-data-preparation
- Centralizar a preparação do Power Query num dataflow, para uma fonte única da verdade; a página trata do Dataflow Gen1 e indica o Gen2. https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-self-service-data-preparation
- Preparação centralizada em dataflow, fonte única da verdade (ms.date 2024-12-30). https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-self-service-data-preparation
- Banco transacional muito normalizado para gravar; análise em cima dele pede consultas complexas; "aren't always ideal"; exceção com esquema bem planejado; histórico em data mart ou armazém. https://learn.microsoft.com/en-us/azure/architecture/data-guide/relational-data/online-transaction-processing
- ELT e ETL diferem no lugar da transformação; quando ETL ainda é a escolha. https://learn.microsoft.com/en-us/azure/architecture/data-guide/relational-data/etl
- `DateTime.LocalNow` no Desktop e no Power Query Online (ms.date 2025-09-16). https://learn.microsoft.com/en-us/powerquery-m/datetime-localnow
- Duplicata no lado "um" faz a atualização inteira falhar. A leitura sobre a tabela já juntada é inferência. https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand (página datada de 2025-09-05)
- Duplicata no lado "um" de uma relação faz a atualização inteira falhar ("the entire data refresh will fail"). https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand
- Nunca truncar e recarregar dimensão com chave substituta gerada automaticamente; versões do tipo 2 podem não se regenerar; não sincronizar exclusão com a dimensão. https://learn.microsoft.com/en-us/fabric/data-warehouse/dimensional-modeling-load-tables (atualizada em 2026-07-06)
- Nunca truncar dimensão com chave gerada, tipicamente `IDENTITY`, busca da versão, falha da busca, inferred member, recarga de fato como último recurso. https://learn.microsoft.com/en-us/fabric/data-warehouse/dimensional-modeling-load-tables
- Carga de tabelas dimensionais, referência da prova das três receitas pagas. https://learn.microsoft.com/en-us/fabric/data-warehouse/dimensional-modeling-load-tables
- Menor inteiro, membro especial com -1, menor data no início da primeira versão, atributo numérico levado à fato. https://learn.microsoft.com/en-us/fabric/data-warehouse/dimensional-modeling-dimension-tables
- Chave `NOT NULL` e preço unitário não aditivo. https://learn.microsoft.com/en-us/fabric/data-warehouse/dimensional-modeling-fact-tables
- Value encoding e hash encoding no Power BI. https://learn.microsoft.com/en-us/power-bi/guidance/import-modeling-data-reduction
- Coluna no Power Query, no DAX e no SQL. https://learn.microsoft.com/en-us/power-bi/guidance/import-modeling-data-reduction
- Três estratégias de dono do conteúdo. https://learn.microsoft.com/en-us/power-bi/guidance/fabric-adoption-roadmap-content-ownership-and-management
- Autoatendimento gerenciado: poucos modelos compartilhados e versão única da verdade. https://learn.microsoft.com/en-us/power-bi/guidance/powerbi-implementation-planning-usage-scenario-managed-self-service-bi
- Limites de atualização em capacidade compartilhada (ms.date 2026-09-18). https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data

### SQL Server (Microsoft)

- Secundário legível do Always On e escrita em outros bancos da instância. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups
- Grupo de disponibilidade básico sem leitura no secundário. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/basic-availability-groups-always-on-availability-groups
- `ROW_NUMBER` não determinístico quando o `ORDER BY` empata (ms.date 2026-06-15). https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql
- `DISTINCT ON` não existe em T-SQL: a tentativa dá erro. https://learn.microsoft.com/en-us/sql/t-sql/queries/select-transact-sql (ms.date 2026-09-16), saída `lab/sqlserver/saidas/2022/lab9_dedup.txt`
- `SELECT` e `QUALIFY`. https://learn.microsoft.com/en-us/sql/t-sql/queries/select-transact-sql
- `ISNULL` converte para o tipo do primeiro argumento e pode truncar a substituição. https://learn.microsoft.com/en-us/sql/t-sql/functions/isnull-transact-sql
- Tabela temporal: uma linha no histórico por modificação, sem `TRUNCATE` com versionamento ligado, vigência em UTC, presente em todas as edições nas páginas das versões 2022 e 2025. https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal/overview (ms.date 2026-08-18)
- `IDENTITY` no SQL Server. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql-identity-property
- `HASHBYTES` no SQL Server. https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql
- Termos da Developer na 2022, uso e seção 5. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- Termos do SQL Server 2022 Developer, seções 1.a.i e 5. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- Termos da Developer na 2025, uso e seção 5. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf
- Termos do SQL Server 2025 Developer. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf
- Edições, Express e Developer. https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022
- Imagem em contêiner e `ACCEPT_EULA`. https://learn.microsoft.com/en-us/sql/linux/containers/deploy
- Imagem do SQL Server em contêiner. https://learn.microsoft.com/en-us/sql/linux/containers/deploy
- `MSSQL_PID` e `ACCEPT_EULA`. https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables?view=sql-server-ver17
- `sqlcmd`, `-C`, `-b` e `-P`. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
- `sqlcmd -b`. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
- `sqlcmd`, `-C` e `-P`. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
- `sqlcmd`: `-C`, `-P` inseguro, `-b`. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
- `TRIM`. https://learn.microsoft.com/en-us/sql/t-sql/functions/trim-transact-sql
- Collation. https://learn.microsoft.com/en-us/sql/relational-databases/collations/collation-and-unicode-support
- Cláusula `COLLATE`. https://learn.microsoft.com/en-us/sql/t-sql/statements/collations
- Comparação de texto e espaço à direita. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/string-comparison-assignment
- `varchar`. https://learn.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql
- `nvarchar`. https://learn.microsoft.com/en-us/sql/t-sql/data-types/nchar-and-nvarchar-transact-sql
- `TRANSLATE`. https://learn.microsoft.com/en-us/sql/t-sql/functions/translate-transact-sql
- Sumário de funções do T-SQL, sem `INITCAP` nem `UNACCENT`. https://learn.microsoft.com/en-us/sql/t-sql/functions/functions
- `TRY_CONVERT`. https://learn.microsoft.com/en-us/sql/t-sql/functions/try-convert-transact-sql
- `CAST` e `CONVERT`, estilos e texto vazio. https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql
- `TRY_CONVERT` e texto vazio em `numeric` e `decimal` (ms.date 2026-10-13). https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql
- `SET DATEFORMAT`. https://learn.microsoft.com/en-us/sql/t-sql/statements/set-dateformat-transact-sql
- `AT TIME ZONE`. https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql
- Fuso no Linux. https://learn.microsoft.com/en-us/sql/linux/configure/time-zone
- `COALESCE`. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/coalesce-transact-sql
- `CASE`. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql
- `UNIQUE` e nulo. https://learn.microsoft.com/en-us/sql/relational-databases/tables/unique-constraints-and-check-constraints
- `MERGE`. https://learn.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql
- `THROW`. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql
- Transações e o que não cabe nelas. https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide
- `CREATE VIEW` e `SCHEMABINDING`. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
- View sem `SCHEMABINDING` e `sp_refreshview`. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
- `DROP TABLE`. https://learn.microsoft.com/en-us/sql/t-sql/statements/drop-table-transact-sql
- `SEQUENCE`. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql
- `CONCAT`. https://learn.microsoft.com/en-us/sql/t-sql/functions/concat-transact-sql
- Novidades da 2025. https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2025
- Query Store: padrão por versão e modo de captura. https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver16, https://learn.microsoft.com/en-us/sql/relational-databases/performance/manage-the-query-store?view=sql-server-ver16 e https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-query-store-options-transact-sql?view=sql-server-ver16
- Query Store: texto ("as provided by the user", que não vale quando o motor parametriza), `query_parameterization_type`, view expandida no plano. https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-query-text-transact-sql?view=sql-server-ver16 e https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-query-transact-sql?view=sql-server-ver16
- Query Store: gravação de texto, plano e contadores. https://learn.microsoft.com/en-us/sql/relational-databases/performance/how-query-store-collects-data?view=sql-server-ver16
- Query Store em secundário, nível 1. https://learn.microsoft.com/en-us/sql/relational-databases/performance/query-store-for-secondary-replicas?view=sql-server-ver16
- Visões dinâmicas e texto de módulo cifrado. https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-stats-transact-sql?view=sql-server-ver16 e https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-sql-text-transact-sql
- Extended Events: início rápido, permissões, alvos e `NO_EVENT_LOSS`. https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/quick-start-extended-events-in-sql-server?view=sql-server-ver16, https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/extended-events?view=sql-server-ver16, https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/targets-for-extended-events-in-sql-server?view=sql-server-ver16 e https://learn.microsoft.com/en-us/sql/t-sql/statements/create-event-session-transact-sql?view=sql-server-ver16
- SQL Trace e Profiler preteridos, nível 1. https://learn.microsoft.com/en-us/sql/tools/sql-server-profiler/sql-server-profiler?view=sql-server-ver16
- Catálogo do SQL Server. https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-sql-referenced-entities-transact-sql?view=sql-server-ver16, https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql?view=sql-server-ver16 e https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-modules-transact-sql
- Termos da edição Developer, seção 5, leitura factual, sem interpretação jurídica. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf e https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf
- `SET XACT_ABORT` (ms.date 2019-10-03). https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql
- `RAISERROR` não obedece a `SET XACT_ABORT`. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql
- `ACCEPT_EULA` e `MSSQL_PID`. https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables e https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables?view=sql-server-ver17
- `SELECT INTO` no T-SQL, usado na silver e na gold. https://learn.microsoft.com/en-us/sql/t-sql/queries/select-into-clause-transact-sql
- Extended Events. https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/quick-start-extended-events-in-sql-server?view=sql-server-ver16
- `SET XACT_ABORT` e `sqlcmd -b`. https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql e https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
- `ISNULL` e `COALESCE` no SQL Server. https://learn.microsoft.com/en-us/sql/t-sql/functions/isnull-transact-sql e https://learn.microsoft.com/en-us/sql/t-sql/language-elements/coalesce-transact-sql (ms.date 2025-01-28)
- `SET XACT_ABORT`, `RAISERROR` e `THROW`. https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql (ms.date 2019-10-03), https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql e https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql
- `LIKE`. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/like-transact-sql

### Databricks, Fivetran e textos de mercado

- A arquitetura medalhão organiza o dado em bronze (cru), silver (validado) e gold (enriquecido), e é prática recomendada, não requisito ("a recommended best practice but not a requirement"). https://docs.databricks.com/aws/en/lakehouse/medallion
- Medalhão como camadas que indicam qualidade. https://docs.databricks.com/aws/en/lakehouse/medallion
- Medalhão como prática recomendada, papel de bronze, silver e gold, validação mínima na bronze, início da modelagem na silver. https://docs.databricks.com/aws/en/lakehouse/medallion
- Bronze com validação mínima; silver que limpa e valida (nulos, duplicatas, conversão de tipo, junções) e guarda ao menos uma representação validada e não agregada de cada registro. https://docs.databricks.com/aws/en/lakehouse/medallion
- Arquitetura medalhão, prática recomendada e não requisito; bronze, silver e gold. https://docs.databricks.com/aws/en/lakehouse/medallion
- Pesquisa de comunidade de Joe Reis, publicada em 2026-02-20: 1.101 respostas, múltipla escolha; 11% marcaram "None / modeling is going well"; pressão por velocidade 59%, falta de dono claro 51%, manutenção difícil 39%, ferramenta 19%; o post agradece a um fornecedor de ferramenta de modelagem. https://practicaldatamodeling.substack.com/p/the-organizational-crisis-in-data
- Pesquisa de comunidade de Joe Reis, 2026-02-20. https://practicaldatamodeling.substack.com/p/the-organizational-crisis-in-data
- Pesquisa de comunidade de Joe Reis, publicada em 2026-02-20: 1.101 respostas, múltipla escolha; ferramenta 19%, falta de dono claro 51%, pressão por velocidade 59%, manutenção difícil 39%, "None / modeling is going well" 11%. https://practicaldatamodeling.substack.com/p/the-organizational-crisis-in-data
- Silver "just-enough", regras de negócio complexas na passagem para a gold, estrela na gold. https://www.databricks.com/blog/what-is-medallion-architecture
- Benchmark de estrela contra tabela desnormalizada, com escopo e resultados. Fonte de fornecedor. https://www.fivetran.com/blog/star-schema-vs-obt
- Postmortem da consulta de metadados, 2025-11-18. https://blog.cloudflare.com/18-november-2025-outage/
- Conclusão da fusão. https://www.fivetran.com/press/fivetran-dbt-labs-complete-merger-to-create-the-data-infrastructure-for-trusted-ai-agents
- Data Vault, post de fornecedor. https://www.databricks.com/blog/what-is-data-vault (Databricks Staff, 2022-04-21)

### dbt

- `dbt-core` 1.12.6, de 2026-10-14, Apache-2.0. https://pypi.org/pypi/dbt-core/json
- `dbt-core` 1.12.6, Apache-2.0. https://pypi.org/pypi/dbt-core/json
- `dbt-postgres` 1.11.0, de 2026-07-16, exige `dbt-core<2.0,>=1.8.0rc1`. https://pypi.org/project/dbt-postgres/
- Postgres com dbt na geração v1. https://docs.getdbt.com/docs/local/connect-data-platform/postgres-setup
- Postgres com dbt é geração v1, adaptador mantido pela dbt Labs. https://docs.getdbt.com/docs/local/connect-data-platform/postgres-setup
- Modelo do dbt é principalmente um `select` em arquivo `.sql`, e rodar transforma sem tirar o dado do armazém. https://docs.getdbt.com/docs/build/models
- Modelo como `select` em arquivo `.sql`, o T do ELT. https://docs.getdbt.com/docs/build/models
- Modelo Python roda na plataforma de dados, e só em plataformas específicas. https://docs.getdbt.com/docs/build/python-models
- De `INSERT ... SELECT` para modelo, e a mudança de paradigma do procedural para o declarativo. https://docs.getdbt.com/guides/migrate-from-stored-procedures
- `INSERT ... SELECT` vira modelo; migrar procedures é mudança grande de paradigma. https://docs.getdbt.com/guides/migrate-from-stored-procedures
- `INSERT ... SELECT` vira modelo; mudança de paradigma do procedural para o declarativo. https://docs.getdbt.com/guides/migrate-from-stored-procedures
- Mart, one big table e camada semântica na terminologia do dbt. https://docs.getdbt.com/best-practices/how-we-build-our-metrics/semantic-layer-6-terminology
- One big table, mart e camada semântica na terminologia do dbt. https://docs.getdbt.com/best-practices/how-we-build-our-metrics/semantic-layer-6-terminology (atualizada em 2025-04-16)
- Camada semântica como "denormalization engine". https://docs.getdbt.com/best-practices/how-we-build-our-metrics/semantic-layer-6-terminology (atualizada em 2025-04-16)
- One big table, na terminologia do dbt. https://docs.getdbt.com/best-practices/how-we-build-our-metrics/semantic-layer-6-terminology
- Mart largo e desnormalizado no guia de marts do dbt, com exceção quando há camada semântica. https://docs.getdbt.com/best-practices/how-we-structure/4-marts
- Tabela larga, exceção com camada semântica e materialização do mart. https://docs.getdbt.com/best-practices/how-we-structure/4-marts (atualizada em 2026-07-07)
- Tabela larga e exceção com camada semântica no guia de marts do dbt. https://docs.getdbt.com/best-practices/how-we-structure/4-marts (atualizada em 2026-07-07)
- Staging com lógica condicional, veto à agregação e junção como "almost always a bad idea". https://docs.getdbt.com/best-practices/how-we-structure/2-staging
- Arco do dado moldado pela origem ao moldado pelo negócio, cada transformação num lugar só, guia sem o termo medalhão. https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview
- Snapshots ignoram o full refresh. https://docs.getdbt.com/docs/build/snapshots
- Snapshot do dbt implementa tipo 2, não se reconstrói, roda em agenda, com schema separado e chave realmente única. https://docs.getdbt.com/docs/build/snapshots (atualizada em 2026-09-29)
- `dbt_scd_id` de uso interno e `updated_at` no snapshot. https://docs.getdbt.com/docs/build/snapshots
- Snapshot em YAML, estratégias, colunas, "can't be rebuilt", `--full-refresh` ignorado. https://docs.getdbt.com/docs/build/snapshots
- Snapshots do dbt. https://docs.getdbt.com/docs/build/snapshots
- Snapshot no dbt. https://docs.getdbt.com/docs/build/snapshots
- `unique` sobre uma expressão de duas colunas. https://docs.getdbt.com/faqs/Tests/uniqueness-two-columns
- Teste de dado: a consulta que busca as linhas que desmentem a regra, e os testes genéricos do dbt. https://docs.getdbt.com/docs/build/data-tests
- Teste de dado como `select` que busca as linhas que desmentem a afirmação, e os quatro genéricos. https://docs.getdbt.com/docs/build/data-tests
- Comando `dbt build`, usado na execução do laboratório. https://docs.getdbt.com/reference/commands/build
- No `dbt build`, falha de teste faz os dependentes serem pulados; para não pular, ajusta-se a severidade ou os limites. https://docs.getdbt.com/reference/commands/build
- `dbt build` e resumo da execução. https://docs.getdbt.com/reference/commands/build
- Referência do comando `dbt build`, usado no Exercício 6 e na parte opcional do mini-desafio. https://docs.getdbt.com/reference/commands/build
- Defesa do hash e custos admitidos, em blog de fornecedor. https://docs.getdbt.com/blog/managing-surrogate-keys
- Argumento de dispensar o join, em texto sem versão na dimensão. https://docs.getdbt.com/blog/kimball-dimensional-model
- Pacote lido para a fórmula do `dbt_scd_id`. https://pypi.org/pypi/dbt-adapters/1.24.5/json
- Exemplo de fórmula e frase sobre `check`. https://docs.getdbt.com/reference/resource-configs/snapshot_meta_column_names
- Fim da versão aberta em 9999-12-31. https://docs.getdbt.com/reference/resource-configs/dbt_valid_to_current
- `generate_surrogate_key`. https://raw.githubusercontent.com/dbt-labs/dbt-utils/refs/tags/1.4.1/macros/sql/generate_surrogate_key.sql
- `relationships` exclui nulo. https://docs.getdbt.com/reference/resource-properties/data-tests
- Argumentos de teste sob `arguments:`. https://docs.getdbt.com/reference/resource-properties/data-tests
- `unique`, `relationships` e `accepted_values` ignoram nulo na forma do código do dbt v1. https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-adapters/src/dbt/include/global_project/macros/generic_test_sql/unique.sql
- Testes genéricos ignoram nulo, no código do dbt v1. https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-adapters/src/dbt/include/global_project/macros/generic_test_sql/unique.sql
- View sobre o dado de origem traz sempre os registros mais recentes. https://docs.getdbt.com/docs/build/materializations
- Materialização, tipos embutidos, view como padrão, table para o BI, "don't start with incremental models". https://docs.getdbt.com/docs/build/materializations
- Materializações, view como padrão, table para o BI. https://docs.getdbt.com/docs/build/materializations
- Materialização, view, table e incremental. https://docs.getdbt.com/docs/build/materializations
- Sem `unique_key`, só acréscimo na maioria dos adaptadores; nulo em `unique_key`; `--full-refresh`. https://docs.getdbt.com/docs/build/incremental-models
- Incremental sem `unique_key`, `--full-refresh` e nulo na chave. https://docs.getdbt.com/docs/build/incremental-models
- Estratégias de incremental no `dbt-postgres` e seus padrões. https://docs.getdbt.com/reference/resource-configs/postgres-configs
- "For SCD2, use dbt snapshots, not delete+insert". https://docs.getdbt.com/docs/build/incremental-strategy.md
- Fato atrasado, janela de volta e afastamento da origem. https://docs.getdbt.com/best-practices/materializations/4-incremental-models
- `var()` e variáveis do projeto. https://docs.getdbt.com/docs/build/project-variables
- `var()` no `dbt_project.yml`. https://docs.getdbt.com/docs/build/project-variables
- `dbt docs generate`; a página de hoje descreve o v2, e o comportamento do v1 é o observado. https://docs.getdbt.com/reference/commands/cmd-docs
- `dbt docs` (a página de hoje descreve o v2; o comportamento da linha 1.x é o observado). https://docs.getdbt.com/reference/commands/cmd-docs
- `dbt docs`, com o comportamento da linha 1.x observado no laboratório. https://docs.getdbt.com/reference/commands/cmd-docs
- O grafo só vê o que o projeto declara. https://docs.getdbt.com/reference/exposure-properties e https://docs.getdbt.com/docs/build/udfs
- Snapshot em bloco SQL segue disponível, YAML recomendado. https://docs.getdbt.com/reference/resource-configs/snapshots-jinja-legacy
- Configurações de snapshot e `schema`. https://docs.getdbt.com/reference/snapshot-configs
- `tests:` renomeado para `data_tests:`. https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v1.8
- Avisos de sintaxe antiga e a restrição por banco. https://docs.getdbt.com/reference/deprecations
- Nome do schema customizado, `<target_schema>_<custom_schema>`. https://docs.getdbt.com/docs/build/custom-schemas
- Teste unitário só em desenvolvimento ou CI. https://docs.getdbt.com/docs/build/unit-tests
- Situação de cada versão do dbt. https://docs.getdbt.com/docs/dbt-versions
- Versões do v2. https://docs.getdbt.com/docs/dbt/dbt-releases
- Distribuições, licenças, condições de uso, 1.13 como última menor, expectativa de 3 a 5 anos, compromisso com o `dbt-oss` e histórico de nomes. https://www.getdbt.com/licenses-faq
- dbt v1 sob Apache 2.0. https://www.getdbt.com/licenses-faq
- Última versão menor da linha 1.x, suporte crítico e expectativa de 3 a 5 anos, sem data de corte. https://www.getdbt.com/licenses-faq
- O adaptador como principal fator, "No" à pergunta de pagamento, `pip install dbt-core` e `--use-v2-parser`. https://docs.getdbt.com/blog/comparing-dbt-and-dbt-oss
- O adaptador como principal fator da geração, e "No" à pergunta sobre pagar à dbt Labs (2026-09-16). https://docs.getdbt.com/blog/comparing-dbt-and-dbt-oss
- Subir de versão e testar com a flag opt-in. https://docs.getdbt.com/blog/comparing-dbt-and-dbt-oss
- Aviso sobre o nome `dbt-core` no README da 2.0.0rc10. https://pypi.org/project/dbt-core/
- O que o `dbt-oss` não inclui. https://docs.getdbt.com/docs/local/install-dbt-v2
- Docs v2, lite e full. https://docs.getdbt.com/docs/dbt/dbt-availability
- Tabela de adaptadores do v2. https://docs.getdbt.com/docs/supported-data-platforms
- Tabela de adaptadores da v2, sem Postgres e sem SQL Server. https://docs.getdbt.com/docs/supported-data-platforms
- Pedido do adaptador de Postgres. https://api.github.com/repos/dbt-labs/dbt/issues/13123
- `dbt-postgres`. https://docs.getdbt.com/docs/local/connect-data-platform/postgres-setup e https://pypi.org/project/dbt-postgres/
- Preço da plataforma, a reconferir na publicação. https://www.getdbt.com/pricing
- Preço público da plataforma em 2026-11-03; reconferir na data de decidir. https://www.getdbt.com/pricing
- Migração para o v2. https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v2, https://docs.getdbt.com/docs/dbt/supported-features e https://docs.getdbt.com/reference/global-configs/parsing
- DuckDB: adaptador no v2, `dbt-duckdb` no v1, versão 2.0.0, suporte e arquivo. https://docs.getdbt.com/docs/local/connect-data-platform/duckdb-setup, https://pypi.org/pypi/dbt-duckdb/json e https://duckdb.org/2026/10/21/announcing-duckdb-200.html
- `dbt-sqlserver`. https://pypi.org/project/dbt-sqlserver/, https://pypi.org/pypi/dbt-sqlserver/json e https://docs.getdbt.com/docs/local/connect-data-platform/mssql-setup
- Limites do adaptador no SQL Server. https://docs.getdbt.com/reference/resource-configs/mssql-configs
- Configurações do adaptador. https://docs.getdbt.com/reference/resource-configs/mssql-configs
- `dbt-sqlserver`, versão, licença e dependências. https://pypi.org/project/dbt-sqlserver/ e https://pypi.org/pypi/dbt-sqlserver/json
- Adaptador do dbt para SQL Server, suporte e versão mínima. https://docs.getdbt.com/docs/local/connect-data-platform/mssql-setup
- Definição de linhagem, fonte de fornecedor. https://www.getdbt.com/blog/getting-started-with-data-lineage
- Linhagem, em fonte de fornecedor. https://www.getdbt.com/blog/getting-started-with-data-lineage
- Exposições e o que o grafo declara. https://docs.getdbt.com/docs/build/exposures, https://docs.getdbt.com/reference/exposure-properties e https://docs.getdbt.com/docs/build/udfs
- Cron como forma razoável de agendar, e o aviso sobre o que falta para produção. https://docs.getdbt.com/docs/deploy/deployment-tools
- `dbt-sqlserver`: licença MIT e plugin de comunidade. https://pypi.org/project/dbt-sqlserver/ e https://docs.getdbt.com/docs/local/connect-data-platform/mssql-setup
- dbt State exige login e é cobrado por uso. https://docs.getdbt.com/docs/deploy/dbt-state-about
- `dbt-postgres` 1.11.0 e versões declaradas de Python. https://pypi.org/pypi/dbt-postgres/1.11.0/json
- Exposições do dbt. https://docs.getdbt.com/docs/build/exposures e https://docs.getdbt.com/reference/exposure-properties
- Avisos de depreciação e `dbt-autofix`, v1 com suporte e recursos novos só no v2. https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v2
- Adaptador e autenticação suportados, última versão do v1 sem avisos nem erros. https://docs.getdbt.com/docs/dbt/supported-features
- A flag `--use-v2-parser`. https://docs.getdbt.com/reference/global-configs/parsing
- PyPI: https://pypi.org/project/dbt-core/ ; https://pypi.org/pypi/dbt-core/json ; https://pypi.org/project/dbt-postgres/ ; https://pypi.org/pypi/dbt-postgres/1.11.0/json ; https://pypi.org/project/dbt-duckdb/ ; https://pypi.org/pypi/dbt-duckdb/json ; https://pypi.org/project/dbt-sqlserver/ ; https://pypi.org/project/duckdb/ ; https://pypi.org/pypi/duckdb/2.0.0/json
- dbt Labs, guia de chave substituta. https://www.getdbt.com/blog/guide-to-surrogate-key

### PostgreSQL

- PostgreSQL 16.15, com suporte até 2028-11-09. https://www.postgresql.org/support/versioning/
- PostgreSQL 16 com suporte até 2028-11-09. https://www.postgresql.org/support/versioning/
- Uma réplica Postgres em hot standby não aceita escrita, nem tabela temporária ("not even temporary tables may be written"). https://www.postgresql.org/docs/16/hot-standby.html
- Hot standby sem escrita, cancelamento de consulta por conflito e `hot_standby_feedback`. https://www.postgresql.org/docs/16/hot-standby.html
- Réplica física e o aviso sobre replicação lógica. https://www.postgresql.org/docs/16/hot-standby.html
- Réplica em espera ativa não aceita escrita, nem tabela temporária. https://www.postgresql.org/docs/16/hot-standby.html
- O atendimento das 00h25 em UTC é 21h25 do dia anterior depois da conversão, e 2 de 4 atendimentos mudam de dia. Saída `lab/saidas/lab2_fuso_e_datas.txt`. https://www.postgresql.org/docs/16/functions-datetime.html
- Funções de horário corrente devolvem o início da transação. https://www.postgresql.org/docs/16/functions-datetime.html
- Regra do `AT TIME ZONE` sobre `timestamp` sem fuso e `to_date`. https://www.postgresql.org/docs/16/functions-datetime.html
- `timestamp` sem fuso `AT TIME ZONE` supõe que o valor já está no fuso indicado. https://www.postgresql.org/docs/16/functions-datetime.html
- O JOIN tem uma linha para cada linha da outra tabela que satisfaz a condição ("the joined table has a row for each row in T2 that satisfies the join condition with R1"); no dia 20, 6 linhas viram 9 e a receita vai de 430,90 para 850,90. Saída `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. https://www.postgresql.org/docs/16/queries-table-expressions.html
- O `JOIN` gera uma linha para cada combinação que satisfaz a condição, o que explica a multiplicação de linhas sem erro. https://www.postgresql.org/docs/16/queries-table-expressions.html
- O JOIN gera uma linha para cada linha da segunda tabela que atende à condição. https://www.postgresql.org/docs/16/queries-table-expressions.html
- `unaccent` e o limite de `TRIM`, caixa e acento diante de erro de digitação. https://www.postgresql.org/docs/16/unaccent.html
- `unaccent` marcada como "trusted", instalável por quem tem `CREATE` no banco. https://www.postgresql.org/docs/16/unaccent.html
- `DISTINCT ON`: "the 'first row' of each set is unpredictable unless ORDER BY is used". https://www.postgresql.org/docs/16/sql-select.html
- `SELECT DISTINCT` só remove linhas idênticas. https://www.postgresql.org/docs/16/sql-select.html
- `DISTINCT` e a primeira linha de `DISTINCT ON`. https://www.postgresql.org/docs/16/sql-select.html
- Soma de zero linhas é nulo, não zero. https://www.postgresql.org/docs/16/functions-aggregate.html
- Funções de agregação e nulo. https://www.postgresql.org/docs/16/functions-aggregate.html
- `CASE` sem `ELSE` devolve nulo; comportamento de `COALESCE` e `NULLIF`. https://www.postgresql.org/docs/16/functions-conditional.html
- `CASE` sem `ELSE` devolve nulo quando nenhuma condição é verdadeira. https://www.postgresql.org/docs/16/functions-conditional.html
- `pg_input_is_valid` e `pg_input_error_info`. https://www.postgresql.org/docs/16/functions-info.html
- Sinal da especificação POSIX, oposto da ISO-8601. https://www.postgresql.org/docs/16/datetime-posix-timezone-specs.html
- Especificação POSIX de fuso, positiva a oeste. https://www.postgresql.org/docs/16/datetime-posix-timezone-specs.html
- Literal com tipo sem fuso, `timestamptz` e sessão. https://www.postgresql.org/docs/16/datatype-datetime.html
- `DateStyle` e formato de data. https://www.postgresql.org/docs/16/datatype-datetime.html
- `BETWEEN` e timestamps: seção "Don't use BETWEEN (especially with timestamps)". https://wiki.postgresql.org/wiki/Don%27t_Do_This (editada em 2024-11-21)
- `BETWEEN` e timestamps (editada em 2024-11-21). https://wiki.postgresql.org/wiki/Don%27t_Do_This
- `daterange` e limites de intervalo. https://www.postgresql.org/docs/16/rangetypes.html
- `TRUNCATE`, `CONTINUE IDENTITY` e `RESTART IDENTITY`. https://www.postgresql.org/docs/16/sql-truncate.html
- Sequência queima números e não garante ausência de buraco. https://www.postgresql.org/docs/16/functions-sequence.html
- Identidade como coluna com sequência implícita. https://www.postgresql.org/docs/16/sql-createtable.html
- Funções de tamanho de objeto. https://www.postgresql.org/docs/16/functions-admin.html
- Deduplicação do B-tree. https://www.postgresql.org/docs/16/btree-implementation.html
- `md5`, `concat` e `concat_ws` diante de nulo. https://www.postgresql.org/docs/16/functions-string.html
- `REFRESH MATERIALIZED VIEW` substitui o conteúdo. https://www.postgresql.org/docs/16/sql-refreshmaterializedview.html
- Dois nulos não são iguais numa restrição `UNIQUE`; `NULLS NOT DISTINCT`. https://www.postgresql.org/docs/16/ddl-constraints.html
- Nulos em `UNIQUE` e `NULLS NOT DISTINCT`. https://www.postgresql.org/docs/16/ddl-constraints.html
- `ON CONFLICT DO UPDATE` e violação de cardinalidade. https://www.postgresql.org/docs/16/sql-insert.html
- `MERGE`, violação de unicidade e de cardinalidade. https://www.postgresql.org/docs/16/sql-merge.html
- `psql`: continuar depois de erro, `ON_ERROR_STOP` e `--single-transaction`. https://www.postgresql.org/docs/16/app-psql.html
- `psql`, `ON_ERROR_STOP` e `--single-transaction`. https://www.postgresql.org/docs/16/app-psql.html
- `psql`, as opções de linha de comando usadas nos exercícios. https://www.postgresql.org/docs/16/app-psql.html
- `psql`: `ON_ERROR_STOP` e `--single-transaction`. https://www.postgresql.org/docs/16/app-psql.html
- `pg_stat_statements`: carga, memória, normalização, colunas, `track`, permissão. https://www.postgresql.org/docs/16/pgstatstatements.html
- Log de consultas, permissão por parâmetro e aviso de dado sensível ("Logged statements might reveal sensitive data and even contain plaintext passwords"). https://www.postgresql.org/docs/16/runtime-config-logging.html
- `pg_stat_activity`, `pg_read_all_stats` e `track_activity_query_size`. https://www.postgresql.org/docs/16/monitoring-stats.html e https://www.postgresql.org/docs/16/runtime-config-statistics.html
- `auto_explain` e o aviso sobre `log_analyze`. https://www.postgresql.org/docs/16/auto-explain.html
- Dependências e `view_table_usage`. https://www.postgresql.org/docs/16/ddl-depend.html e https://www.postgresql.org/docs/16/infoschema-view-table-usage.html
- Limites de `CREATE VIEW` e `CREATE OR REPLACE VIEW`. https://www.postgresql.org/docs/16/sql-createview.html
- `ON CONFLICT` e `MERGE` com chave repetida. https://www.postgresql.org/docs/16/sql-insert.html e https://www.postgresql.org/docs/16/sql-merge.html

### Apache Airflow, Debezium, DuckDB, SQLMesh e Docker

- Imagem `postgres:16.15-alpine`. https://hub.docker.com/_/postgres
- Memória por contêiner com `docker stats`. https://docs.docker.com/reference/cli/docker/container/stats/
- Medição de memória. https://docs.docker.com/reference/cli/docker/container/stats/
- `docker stats`, usado nas medidas. https://docs.docker.com/reference/cli/docker/container/stats/
- Construção da imagem do dbt. https://docs.docker.com/reference/cli/docker/compose/build/
- `docker compose build`. https://docs.docker.com/reference/cli/docker/compose/build/
- Snapshot inicial do Debezium, modo `initial`. https://debezium.io/documentation/reference/stable/connectors/postgresql.html (Debezium 3.7)
- Snapshot no CDC, no Debezium. https://debezium.io/documentation/reference/stable/connectors/postgresql.html
- Orquestrador rodando o `dbt build` por um comando de shell. https://airflow.apache.org/docs/apache-airflow-providers-standard/stable/operators/bash.html
- `BashOperator` e código de saída. https://airflow.apache.org/docs/apache-airflow-providers-standard/stable/operators/bash.html
- `BashOperator`: "a non-zero exit code produces an AirflowException and thus a task failure". https://airflow.apache.org/docs/apache-airflow-providers-standard/stable/operators/bash.html
- Código de saída diferente de zero vira `AirflowException` no `BashOperator`. https://airflow.apache.org/docs/apache-airflow-providers-standard/stable/operators/bash.html
- A tarefa deve dar o mesmo resultado a cada tentativa; trocar `INSERT` por `UPSERT`. https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html
- A tarefa deve dar o mesmo resultado a cada tentativa; `UPSERT` no lugar de `INSERT`. https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html
- SQLMesh. https://github.com/SQLMesh/sqlmesh e https://sqlmesh.readthedocs.io/en/stable/integrations/overview/
- Resolução de pacotes sem lock, nível 2, com `uv pip compile` e Python 3.13; páginas de pacote consultadas. https://pypi.org/project/duckdb/ e https://pypi.org/project/dbt-duckdb/

### Fuso, lei e energia

- Fim do horário de verão na base da IANA (versão 2019b) e versão mais recente. https://data.iana.org/time-zones/tzdb/NEWS
- Os 16 identificadores do Brasil e as UFs de `America/Sao_Paulo`. https://data.iana.org/time-zones/tzdb/zone1970.tab
- Decreto nº 9.772/2019, art. 1º. A página avisa que o texto não substitui o publicado no DOU de 26.4.2019, edição extra, retificado em 29.4.2019. https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2019/decreto/D9772.htm
- Relatório do MME sobre 2026/2027. https://www.gov.br/mme/pt-br/assuntos/secretarias/secretaria-nacional-energia-eletrica/agenda-estrategica-eletroenergetica-2026/RELATRIODEMONITORAMENTO_AGENDA__2TRIM_MINv310826vf2.pdf
- LGPD, arts. 6º, III, 16 e 18, IV. https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm

### Apostilas da mentoria

- Apostila de Orquestração, seção 10.3, a foto agendada. https://github.com/carreiradadosia/apostilas/blob/main/engenharia_de_dados/orquestracao/fundamentos/capitulos/10-proteger-a-origem-e-guardar-o-que-some.md
- Apostila de Orquestração, seção 6.1, idempotência. https://github.com/carreiradadosia/apostilas/blob/main/engenharia_de_dados/orquestracao/fundamentos/capitulos/06-nova-tentativa-e-idempotencia.md

### Do laboratório, por afirmação

- Tabela de origem de cada coluna, igualdade do `SELECT` com o modelo dbt e o item 101/1 com 2 `Camiseta básica` a 60,00: nível 3, `lab/saidas/lab9_fatos_da_carga.txt`.
- Bancos `erp` e `dw`, papel `replica_leitura` e `postgres_fdw`: nível 3, `lab/postgres-init/01_erp_e_dw.sh` e `lab/saidas/lab9_fatos_da_carga.txt`.
- Composição do pedido 104 (uma linha em pedidos, dois itens, duas parcelas, os três somando 310,90): nível 3, `lab/saidas/lab9_fatos_da_carga.txt`, 2026-11-04, carga do laboratório em `lab/postgres-init/01_erp_e_dw.sh`.
- Antes e depois, contagem 11 e 10, pedido 103 e coluna redundante: nível 3, `lab/saidas/lab1_silver_a_mao.txt`.
- `DISTINCT` em dados sintéticos: nível 3, `lab/sql/77_provas_curtas_do_join.sql` e `lab/saidas/lab9_provas_curtas_do_join.txt`.
- Receita de 430,90, 111,90 e 293,30, total de 836,10, e 13 linhas na fato e na view. Nível 3, `postgres:16.15-alpine`. `lab/saidas/lab3_gold_estrela_e_fan_out.txt`
- Dimensão de produto com 6 linhas no Lab 3 e 8 linhas com as fotos dos três dias. Nível 3, `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0. `lab/saidas/lab3_gold_estrela_e_fan_out.txt` e `lab/saidas/lab5_projeto_dbt.txt`
- Provas com dados sintéticos, nível 3. `lab/sql/76_reprocesso_sintetico.sql` e `lab/saidas/lab9_reprocesso_sintetico.txt`.
- `var()` sem valor padrão e `--full-refresh` no snapshot, nível 3. `lab/saidas/lab9_dbt_var_e_full_refresh.txt`.
- `psql` diante de erro, nível 3. `lab/saidas/lab9_psql_erro.txt`.
- Dag que roda o dbt, com falha e volta ao sucesso. Saídas `lab/saidas/lab7_orquestrador_construir_imagem.txt` e `lab/saidas/lab7_orquestrador_roda_dbt.txt`.

### Saídas capturadas do laboratório

"O que rodou de verdade?" Estas capturas ficam com o laboratório. Caminho relativo ao módulo `modelagem/dbt/`. Execução em Linux, em contêineres descartáveis. Nada rodou em Windows.

**Laboratório principal, em `lab/saidas/`**

- `lab/saidas/lab0_subir_do_zero.txt`
- `lab/saidas/lab0_construir_imagem_dbt.txt`
- `lab/saidas/lab1_silver_a_mao.txt`
- `lab/saidas/lab2_fuso_e_datas.txt`
- `lab/saidas/lab3_gold_estrela_e_fan_out.txt`
- `lab/saidas/lab4_preco_update_e_scd2.txt`
- `lab/saidas/lab5_projeto_dbt.txt`
- `lab/saidas/lab6_testes_que_param.txt`
- `lab/saidas/lab7_orquestrador_construir_imagem.txt`
- `lab/saidas/lab7_orquestrador_roda_dbt.txt`
- `lab/saidas/produto_fora_da_ultima_foto.txt`
- `lab/saidas/sonda_dbt_v2_com_postgres.txt`
- `lab/saidas/recursos_medidos.txt`
- `lab/saidas/alternativa_duckdb.txt`
- `lab/saidas/exercicios_enunciados.txt`
- `lab/saidas/cap00_docker_versoes.txt`
- `lab/saidas/cap16_resolucao_sem_lock.txt`

As capturas `lab9_*` reúnem as provas curtas que os capítulos citam, cada uma com o estado do banco no cabeçalho. O prefixo é só nome de arquivo: o Lab 9 mora em `lab/linhagem/`.

- `lab/saidas/lab9_preparo.txt`
- `lab/saidas/lab9_chave_identidade.txt`
- `lab/saidas/lab9_dbt_var_e_full_refresh.txt`
- `lab/saidas/lab9_dbt_venda_sem_versao.txt`
- `lab/saidas/lab9_fatos_da_carga.txt`
- `lab/saidas/lab9_fuso_por_sessao.txt`
- `lab/saidas/lab9_ligacao_com_a_versao.txt`
- `lab/saidas/lab9_provas_curtas_do_join.txt`
- `lab/saidas/lab9_psql_erro.txt`
- `lab/saidas/lab9_receita_tres_precos.txt`
- `lab/saidas/lab9_reprocesso_sintetico.txt`
- `lab/saidas/lab9_tzdata_da_imagem.txt`
- `lab/saidas/lab9_venda_sem_versao.txt`

**T-SQL, em `lab/sqlserver/saidas/`**

A pasta `2022/` e a pasta `2025/` trazem os mesmos arquivos. A `2025/` traz também `lab0_edicoes.txt`.

- `lab/sqlserver/saidas/2022/lab0_ambiente.txt`
- `lab/sqlserver/saidas/2022/lab1_silver_a_mao.txt`
- `lab/sqlserver/saidas/2022/lab2_fuso_e_datas.txt`
- `lab/sqlserver/saidas/2022/lab3_gold_estrela_e_fan_out.txt`
- `lab/sqlserver/saidas/2022/lab4_preco_update_e_scd2.txt`
- `lab/sqlserver/saidas/2022/lab5_conferencia_postgres.txt`
- `lab/sqlserver/saidas/2022/lab6_texto_e_collation.txt`
- `lab/sqlserver/saidas/2022/lab7_datas_em_texto.txt`
- `lab/sqlserver/saidas/2022/lab8_nulos.txt`
- `lab/sqlserver/saidas/2022/lab9_dedup.txt`
- `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`
- `lab/sqlserver/saidas/2022/lab11_chave_substituta.txt`
- `lab/sqlserver/saidas/2022/lab12_versoes.txt`
- `lab/sqlserver/saidas/2022/lab13_sintaxe_do_postgres.txt`
- `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt`
- `lab/sqlserver/saidas/2022/lab15_datas_com_tab.txt`
- `lab/sqlserver/saidas/2025/lab0_edicoes.txt`
- `lab/sqlserver/saidas/dbt_sqlserver_resolucao.txt`
- `lab/sqlserver/saidas/diferencas_2022_2025.txt`
- `lab/sqlserver/saidas/diferencas_2025_enterprise_standard.txt`
- `lab/sqlserver/saidas/postgres_contraprova.txt`

**Linhagem, em `lab/linhagem/saidas/`**

- `lab/linhagem/saidas/dbt_01_linhagem.txt`
- `lab/linhagem/saidas/mssql_00_ambiente.txt`
- `lab/linhagem/saidas/mssql_01_extended_events.txt`
- `lab/linhagem/saidas/mssql_02_cache_de_plano.txt`
- `lab/linhagem/saidas/mssql_03_requests.txt`
- `lab/linhagem/saidas/mssql_04_query_store.txt`
- `lab/linhagem/saidas/mssql_05_catalogo.txt`
- `lab/linhagem/saidas/mssql_06_permissoes.txt`
- `lab/linhagem/saidas/mssql_07_reinicio.txt`
- `lab/linhagem/saidas/pg_00_ambiente.txt`
- `lab/linhagem/saidas/pg_01_activity.txt`
- `lab/linhagem/saidas/pg_02_statements.txt`
- `lab/linhagem/saidas/pg_03_log.txt`
- `lab/linhagem/saidas/pg_04_auto_explain.txt`
- `lab/linhagem/saidas/pg_05_catalogo.txt`
- `lab/linhagem/saidas/pg_06_replica.txt`
- `lab/linhagem/saidas/pg_07_reinicio.txt`
- `lab/linhagem/saidas/pg_08_custo_laboratorio.txt`

**Provas de chave.** As provas de chave substituta têm captura pública nas saídas `lab9_*` acima. Três seguem como teste à parte, sem arquivo publicado: a tabela de custo da seção 12.3, as armadilhas do hash e o `dbt_scd_id` da seção 12.4. Nível 3, em 2026-11-03, com `postgres:16.15-alpine`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e `dbt-adapters` 1.24.5.
