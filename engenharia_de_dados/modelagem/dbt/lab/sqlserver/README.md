# Laboratório de T-SQL: silver e gold da rede de lojas

Mesmos dados sintéticos e mesmos tratamentos do laboratório em Postgres, em SQL Server no contêiner oficial para Linux.
Nível 3: tudo em `saidas/` foi executado e capturado. Nada de Windows nem de Power Query aqui.

## Licença, antes de subir

Este laboratório usa a edição Developer, gratuita, licenciada para desenvolvimento e teste, nunca para produção. Leia os termos:

- SQL Server 2022: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf
- SQL Server 2025: https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2025-developer,-express,-evaluation/retail/SQL_Server_2025_Developer_Express_and_Evaluation_Edition_English.pdf

O `docker-compose.yaml` não traz o aceite. Quem roda aceita ao passar `ACCEPT_EULA=Y` na linha de comando; sem isso, o Compose para com uma mensagem.

Essa trava, `${ACCEPT_EULA:?}`, só barra a variável vazia ou ausente. A imagem sobe com qualquer valor não vazio, então nem a trava nem o contêiner de pé provam que alguém leu os termos. Cabe a quem roda ler os termos e aceitar conscientemente.

Os termos pedem aprovação escrita da Microsoft para divulgar resultado de benchmark. Por isso o `capturar.sh` não registra hora nem tempo de execução, só a data, e este material não traz comparação de desempenho.

## Como rodar

Precisa de Docker com Compose, `python3`, x86-64 e cerca de 2,5 GB de memória livre. As imagens têm perto de 1,7 GB cada. O `python3` entra em um passo do Lab 11, que confere o MD5 fora do banco.

```bash
./preparar.sh                    # generates .env with a random sa password
ACCEPT_EULA=Y ./roteiro.sh 2022  # runs everything from an empty volume, then takes the project down
ACCEPT_EULA=Y ./roteiro.sh 2025  # same script on 2025
```

Para usar à mão:

```bash
ACCEPT_EULA=Y docker compose up -d
./sq.sh master 00_erp_e_dw.sql -b
./sq.sh dw 10_bronze_carga.sql -b
ACCEPT_EULA=Y docker compose down -v
```

`sq.sh` chama o `sqlcmd` de dentro do contêiner. Nenhuma porta é publicada no host, e a senha vai pela variável `SQLCMDPASSWORD`, nunca por `-P`. O `sa` é só para o laboratório.

Variáveis que o `roteiro.sh` lê:

| Variável | Para que serve | Sem ela |
|---|---|---|
| `ACCEPT_EULA` | o aceite dos termos, por quem roda | o Compose para com uma mensagem |
| `MSSQL_PID` | a edição na 2025: `EnterpriseDeveloper` ou `StandardDeveloper`. Na 2022 o roteiro fixa `Developer` | `EnterpriseDeveloper` na 2025 |
| `SAIDA` | a pasta das capturas, para rodar de novo sem sobrescrever `saidas/` | `saidas/<versão>` |
| `MANTER_DE_PE` | com `1`, não derruba o projeto no fim, para consultar à mão | derruba com `docker compose down -v` |

O que gera as demais saídas:

```bash
./comparar_versoes.sh                # needs both runs above
ACCEPT_EULA=Y ./edicoes_2025.sh      # which edition each MSSQL_PID value starts on 2025
ACCEPT_EULA=Y MSSQL_PID=StandardDeveloper SAIDA=/tmp/standard ./roteiro.sh 2025
./comparar_edicoes_2025.sh /tmp/standard
./contraprova_postgres.sh            # starts and removes a throwaway Postgres, tsql-pg
```

A `contraprova_postgres.sh` usa a imagem `postgres:16.15-alpine`, sem porta publicada e sem senha, e remove o contêiner no fim.

## O que tem aqui

| Pasta ou arquivo | Conteúdo |
|---|---|
| `sql/10` a `sql/40` | os tratamentos, na mesma numeração do laboratório em Postgres. Na gold, chave em hash com `HASHBYTES` e `SHA2_256`, e venda sem versão no membro `'-1'` |
| `sql/60` a `sql/67` | o que é próprio do T-SQL: collation, datas em texto, nulos, deduplicação, `MERGE` e recarga, chave substituta (`IDENTITY` e `SEQUENCE` como demonstração à parte), versões e a sintaxe do Postgres que não passa |
| `sql/68a` a `sql/68d`, `sql/69` | a recarga com `RAISERROR`, `THROW`, `TRY/CATCH` e vários lotes, cada um em sua chamada de `sqlcmd`, porque a saída é por chamada (Lab 14); texto só com tab, `NULLIF(TRIM(x), N'')` e `TRIM` com lista de caracteres (Lab 15) |
| `sql/70_conferencia_postgres.sql` | 32 números do laboratório em Postgres contra este servidor, dois deles sobre o membro `'-1'` |
| `saidas/2022`, `saidas/2025` | capturas de cada laboratório, em cada versão |
| `saidas/diferencas_2022_2025.txt` | o que muda entre as duas, sem ruído de data e de nome de restrição (`./comparar_versoes.sh`) |
| `saidas/2025/lab0_edicoes.txt` | a edição que cada valor de `MSSQL_PID` sobe na 2025 (`./edicoes_2025.sh`) |
| `saidas/diferencas_2025_enterprise_standard.txt` | a mesma execução na 2025 com `EnterpriseDeveloper` e com `StandardDeveloper` (`./comparar_edicoes_2025.sh`) |
| `saidas/dbt_sqlserver_resolucao.txt` | `dbt-sqlserver` resolvendo com `dbt-core` 1.12.6, sem conexão ao banco |
| `saidas/postgres_contraprova.txt` | as mesmas comparações de texto no Postgres 16 (`sql/postgres_contraprova.sql`, por `./contraprova_postgres.sh`) |

## Limites

Rodou em Linux, em contêiner, com uma instância só. A réplica é um banco comum lido por sinônimos, sem grupo de disponibilidade. Quem precisa de Windows, de Power Query ou de uma réplica de verdade não encontra isso aqui.

## Fontes verificadas (2026-11-03)

- A partir do SQL Server 2016, todo algoritmo do `HASHBYTES` que não seja `SHA2_256` ou `SHA2_512` é preterido. https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17
- `ACCEPT_EULA`: "Sets the `ACCEPT_EULA` variable to any value to confirm your acceptance". https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables
