---
title: "16. dbt hoje: geração, licença, adaptador e preço"
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

[Índice](../README.md#capítulos) · [Anterior: 15. O mesmo SQL como projeto dbt](15-o-mesmo-sql-como-projeto-dbt.md) · [Próximo: 17. SQL Server: a silver e a gold em T-SQL](17-sql-server.md)

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

---

[Índice](../README.md#capítulos) · [Anterior: 15. O mesmo SQL como projeto dbt](15-o-mesmo-sql-como-projeto-dbt.md) · [Próximo: 17. SQL Server: a silver e a gold em T-SQL](17-sql-server.md)
