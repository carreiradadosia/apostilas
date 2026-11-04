---
title: "8. Silver: datas e fuso horário"
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

[Índice](../README.md#capítulos) · [Anterior: 7. Silver: nulo com critério e CASE WHEN](07-silver.md) · [Próximo: 9. Fato, dimensão e esquema estrela](09-fato-dimensao-e-esquema-estrela.md)

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

---

[Índice](../README.md#capítulos) · [Anterior: 7. Silver: nulo com critério e CASE WHEN](07-silver.md) · [Próximo: 9. Fato, dimensão e esquema estrela](09-fato-dimensao-e-esquema-estrela.md)
