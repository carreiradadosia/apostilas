# Laboratório de linhagem: que SQL um relatório roda

Um sistema fictício gera um relatório de faturamento, e o laboratório descobre que consultas ele rodou, em Postgres 16 e em SQL Server 2022, sem acesso aos dados. Depois declara a mesma linhagem num projeto dbt. Dados sintéticos.

Nível 3: tudo em `saidas/` foi executado e capturado com `ACCEPT_EULA=Y ./rodar.sh`, em 2026-11-03. Versões: `postgres:16.15-alpine`, `mcr.microsoft.com/mssql/server:2022-CU27-GDR1-ubuntu-22.04`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0.

## Termos do SQL Server, antes de subir

Este laboratório usa a edição Developer, gratuita, licenciada para desenvolvimento e teste, nunca para produção. Leia os termos: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf

O `docker-compose.yaml` não traz o aceite. Quem roda aceita ao passar `ACCEPT_EULA=Y`; sem isso, o Compose para com uma mensagem. Essa trava, `${ACCEPT_EULA:?}`, só barra a variável vazia ou ausente. A imagem sobe com qualquer valor não vazio, então nem a trava nem o contêiner de pé provam que alguém leu os termos. Cabe a quem roda ler antes.

A seção 5 dos termos pede aprovação escrita da Microsoft para divulgar resultado de benchmark. Por isso as saídas levam só a data, sem hora, e os scripts de SQL Server não selecionam duração nem CPU. Não publique medição de desempenho de SQL Server feita aqui sem essa aprovação.

## Como rodar

Precisa de Docker com Compose, x86-64 e 3 GB de memória livre para o SQL Server. Remove contêineres e volumes no fim e mantém as imagens.

```bash
./preparar.sh               # generates .env with random lab secrets
ACCEPT_EULA=Y ./rodar.sh    # after reading the SQL Server Developer terms
```

Nenhuma porta é publicada no host: todo comando passa por `docker compose exec`.

## O que tem aqui

| Pasta ou arquivo | Conteúdo |
|---|---|
| `roteiro_postgres.sh`, `postgres/` | `pg_stat_activity`, `pg_stat_statements`, log de consultas, `auto_explain`, catálogo, réplica física e reinício |
| `roteiro_mssql.sh`, `mssql/` | Extended Events, visões dinâmicas, Query Store, catálogo, matriz de permissões e reinício |
| `roteiro_dbt.sh`, `dbt/` | descrição, `meta`, exposição declarada à mão e `dbt docs`, contra o Postgres |
| `app/` | a aplicação fictícia que gera o relatório por um driver TDS real |
| `saidas/` | as capturas de cada fase |

## Limites

Rodou em Linux, em contêiner. SQL Server com uma instância só, sem grupo de disponibilidade. A página gráfica do `dbt docs` não foi aberta em navegador: há HTTP 200 de dentro do contêiner e o manifesto. O custo em `saidas/pg_08_custo_laboratorio.txt` vale só para este Postgres, numa máquina compartilhada, e não prevê produção. Nada foi testado em Windows, em Power Query nem no monitor de um ERP.

## Fontes verificadas (2026-11-03)

- Termos do SQL Server 2022 Developer, seções 1.a.i e 5. https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- `ACCEPT_EULA`: "Sets the `ACCEPT_EULA` variable to any value to confirm your acceptance". https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables
