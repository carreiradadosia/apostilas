---
title: "18. De onde vem este número: definição e linhagem"
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

[Índice](../README.md#capítulos) · [Anterior: 17. SQL Server: a silver e a gold em T-SQL](17-sql-server.md) · [Próximo: 19. Onde a regra mora: a decisão de quem gerencia](19-onde-a-regra-mora.md)

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

---

[Índice](../README.md#capítulos) · [Anterior: 17. SQL Server: a silver e a gold em T-SQL](17-sql-server.md) · [Próximo: 19. Onde a regra mora: a decisão de quem gerencia](19-onde-a-regra-mora.md)
