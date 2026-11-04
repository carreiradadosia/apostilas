PRINT N'== O atendimento da meia-noite. Loja fecha às 22h; a origem grava UTC em coluna sem fuso.';
SELECT b.id, l.nome AS loja, l.fecha_as,
       b.criado_em_utc AS lido_como_esta,
       CAST(b.criado_em_utc AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS certo
FROM bronze.atendimentos b JOIN silver.lojas l ON l.loja_id = b.loja_id
ORDER BY b.id;

PRINT N'== Por dia: o relatório muda de dia.';
SELECT CAST(criado_em_utc AS date) AS dia_lido_como_esta, COUNT(*) AS atendimentos
FROM bronze.atendimentos
GROUP BY CAST(criado_em_utc AS date)
ORDER BY dia_lido_como_esta;
SELECT dia_local, COUNT(*) AS atendimentos FROM silver.atendimentos GROUP BY dia_local ORDER BY dia_local;

PRINT N'== Nome do fuso: o da IANA não existe aqui, o do Windows sim, mesmo no contêiner Linux.';
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE name IN (N'E. South America Standard Time', N'UTC');
SELECT COUNT(*) AS zonas_listadas, SUM(CASE WHEN name LIKE N'%/%' THEN 1 ELSE 0 END) AS nomes_iana_listados
FROM sys.time_zone_info;
GO
SELECT CAST('2026-10-21 00:30' AS datetime2(0)) AT TIME ZONE N'America/Sao_Paulo' AS nome_iana;
GO
SELECT CAST('2026-10-21 00:30' AS datetime2(0)) AT TIME ZONE N'-03:00' AS deslocamento_em_texto;
GO
PRINT N'== datetime2 contra datetimeoffset: no primeiro, AT TIME ZONE só carimba; no segundo, converte.';
SELECT x AS origem_utc,
       x AT TIME ZONE N'E. South America Standard Time' AS datetime2_so_carimba,
       x AT TIME ZONE N'UTC' AS declarado_utc,
       x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetimeoffset_converte
FROM (VALUES (CAST('2026-10-21 00:30' AS datetime2(0)))) AS t(x);

PRINT N'== Direção errada e conversão dupla, com o mesmo valor de origem.';
SELECT x AS origem_utc,
       CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS certo,
       x AT TIME ZONE N'E. South America Standard Time' AT TIME ZONE N'UTC' AS direcao_errada_em_utc,
       CAST(CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0))
            AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS convertido_duas_vezes,
       CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time'
            AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS repetido_sem_perder_o_deslocamento
FROM (VALUES (CAST('2026-10-21 00:30' AS datetime2(0)))) AS t(x);

PRINT N'== datetimeoffset: não há fuso de sessão. O dia sai do deslocamento que o valor carrega.';
SELECT CAST('2026-10-21 00:30 +00:00' AS datetimeoffset(0)) AS instante,
       CAST(CAST('2026-10-21 00:30 +00:00' AS datetimeoffset(0)) AS date) AS dia_em_utc,
       CAST(CAST('2026-10-21 00:30 +00:00' AS datetimeoffset(0)) AT TIME ZONE N'E. South America Standard Time' AS date) AS dia_em_brasilia;

PRINT N'== Nome de fuso contra deslocamento fixo: em 2018 havia horário de verão, em 2026 não.';
SELECT x AS utc,
       CAST(x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS por_nome,
       DATEADD(hour, -3, x) AS menos_3_fixo,
       DATEPART(tzoffset, x AT TIME ZONE N'UTC' AT TIME ZONE N'E. South America Standard Time') AS deslocamento_em_minutos
FROM (VALUES (CAST('2018-12-01 12:00' AS datetime2(0))),
             (CAST('2019-12-01 12:00' AS datetime2(0))),
             (CAST('2026-11-03 12:00' AS datetime2(0))),
             (CAST('2026-12-01 12:00' AS datetime2(0)))) AS t(x);

PRINT N'== Deslocamento em SWITCHOFFSET usa o sinal da norma: -03:00 é a oeste de Greenwich.';
SELECT SWITCHOFFSET(CAST('2026-10-21 00:30 +00:00' AS datetimeoffset(0)), '-03:00') AS menos_3,
       SWITCHOFFSET(CAST('2026-10-21 00:30 +00:00' AS datetimeoffset(0)), '+03:00') AS mais_3;

PRINT N'== Hora local que não existe (início do horário de verão de 2018) e hora que existe duas vezes (fim, em 2019).';
SELECT x AS hora_local_sem_fuso,
       x AT TIME ZONE N'E. South America Standard Time' AS carimbada,
       x AT TIME ZONE N'E. South America Standard Time' AT TIME ZONE N'UTC' AS em_utc
FROM (VALUES (CAST('2018-11-03 23:30' AS datetime2(0))),
             (CAST('2018-11-04 00:30' AS datetime2(0))),
             (CAST('2018-11-04 01:30' AS datetime2(0))),
             (CAST('2019-02-16 22:30' AS datetime2(0))),
             (CAST('2019-02-16 23:30' AS datetime2(0))),
             (CAST('2019-02-17 00:30' AS datetime2(0)))) AS t(x);

PRINT N'== Data em texto: a data impossível não para a carga com TRY_CONVERT; com CONVERT, para.';
SELECT TRY_CONVERT(date, N'20/10/2026', 103) AS boa,
       TRY_CONVERT(date, N'31/02/2026', 103) AS impossivel_vira_nulo;
GO
SELECT CONVERT(date, N'31/02/2026', 103) AS impossivel_com_convert;
GO
PRINT N'== Data como número: precisa virar texto antes.';
SELECT TRY_CONVERT(date, CONVERT(char(8), 20261020), 112) AS de_numero;
GO
