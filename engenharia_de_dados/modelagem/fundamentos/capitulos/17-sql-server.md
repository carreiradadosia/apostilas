---
title: "17. SQL Server: a silver e a gold em T-SQL"
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

[Índice](../README.md#capítulos) · [Anterior: 16. dbt hoje: geração, licença, adaptador e preço](16-dbt-hoje.md) · [Próximo: 18. De onde vem este número: definição e linhagem](18-de-onde-vem-este-numero.md)

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

---

[Índice](../README.md#capítulos) · [Anterior: 16. dbt hoje: geração, licença, adaptador e preço](16-dbt-hoje.md) · [Próximo: 18. De onde vem este número: definição e linhagem](18-de-onde-vem-este-numero.md)
