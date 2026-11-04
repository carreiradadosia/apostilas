---
title: "Referências e Fontes verificadas (2026-11-04)"
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

[Índice](../README.md#capítulos) · [Anterior: 25. Glossário](25-glossario.md)

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

---

[Índice](../README.md#capítulos) · [Anterior: 25. Glossário](25-glossario.md)
