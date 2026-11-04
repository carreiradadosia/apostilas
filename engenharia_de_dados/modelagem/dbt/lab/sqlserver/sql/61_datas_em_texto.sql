PRINT N'== Estilo explícito: 103 é dd/mm/aaaa, 112 é aaaammdd, 23 é aaaa-mm-dd. Inválida vira NULL.';
SELECT TRY_CONVERT(date, N'20/10/2026', 103) AS estilo_103,
       TRY_CONVERT(date, N'20261020', 112) AS estilo_112,
       TRY_CONVERT(date, N'2026-10-20', 23) AS estilo_23,
       TRY_CONVERT(date, N'31/02/2026', 103) AS impossivel,
       TRY_CONVERT(date, NULL, 103) AS nulo,
       TRY_CONVERT(date, N'xx', 103) AS lixo;
GO
PRINT N'== Texto vazio não é erro: vira 1900-01-01 em data e 0 em int. NULLIF(TRIM(x), N'''') cobre vazio e espaços, não cobre tab (Lab 15).';
SELECT TRY_CONVERT(date, N'', 103) AS vazio_em_date,
       TRY_CONVERT(date, N'   ', 103) AS so_espacos_em_date,
       TRY_CAST(N'' AS date) AS try_cast_vazio,
       TRY_CONVERT(date, NULLIF(TRIM(N'   '), N''), 103) AS com_nullif,
       TRY_CONVERT(int, N'') AS vazio_em_int,
       TRY_CONVERT(numeric(12, 2), N'') AS vazio_em_numeric;
GO
PRINT N'== A carga não aborta, mas o nulo precisa ser contado: quem não mede perde a linha em silêncio.';
SELECT COUNT(*) AS linhas,
       SUM(CASE WHEN dia IS NULL AND texto IS NOT NULL THEN 1 ELSE 0 END) AS texto_invalido
FROM (VALUES (N'20/10/2026'), (N'31/02/2026'), (N'21/10/2026')) AS t(texto)
CROSS APPLY (SELECT TRY_CONVERT(date, t.texto, 103) AS dia) AS c;
GO
PRINT N'== CONVERT aborta. Severidade 16.';
SELECT CONVERT(date, N'31/02/2026', 103) AS com_convert;
GO
PRINT N'== TRY_CONVERT não salva conversão proibida entre tipos: isso é erro, não NULL.';
GO
SELECT TRY_CONVERT(date, 20261020) AS inteiro_para_data;
GO
PRINT N'== TRY_CAST não aceita estilo: depende de DATEFORMAT.';
SET DATEFORMAT mdy;
SELECT @@LANGUAGE AS idioma, 'mdy' AS dateformat_da_sessao,
       TRY_CAST(N'20/10/2026' AS date) AS dia_20_mes_10,
       TRY_CAST(N'02/03/2026' AS date) AS ambigua,
       TRY_CONVERT(date, N'02/03/2026', 103) AS ambigua_com_estilo_103;
SET DATEFORMAT dmy;
SELECT @@LANGUAGE AS idioma, 'dmy' AS dateformat_da_sessao,
       TRY_CAST(N'20/10/2026' AS date) AS dia_20_mes_10,
       TRY_CAST(N'02/03/2026' AS date) AS ambigua,
       TRY_CONVERT(date, N'02/03/2026', 103) AS ambigua_com_estilo_103;
SET DATEFORMAT mdy;
GO
PRINT N'== SET LANGUAGE muda o DATEFORMAT. O DATEFIRST muda em alguns idiomas: Brasil fica em 7, Itália vai a 1.';
SET LANGUAGE us_english;
SELECT @@LANGUAGE AS idioma, @@DATEFIRST AS datefirst, DATEPART(weekday, CONVERT(date, '20261102', 112)) AS weekday_da_segunda,
       TRY_CAST(N'02/03/2026' AS date) AS ambigua;
SET LANGUAGE Brazilian;
SELECT @@LANGUAGE AS idioma, @@DATEFIRST AS datefirst, DATEPART(weekday, CONVERT(date, '20261102', 112)) AS weekday_da_segunda,
       TRY_CAST(N'02/03/2026' AS date) AS ambigua;
SET LANGUAGE Italian;
SELECT @@LANGUAGE AS idioma, @@DATEFIRST AS datefirst, DATEPART(weekday, CONVERT(date, '20261102', 112)) AS weekday_da_segunda,
       TRY_CAST(N'02/03/2026' AS date) AS ambigua,
       ((DATEPART(weekday, CONVERT(date, '20261102', 112)) + @@DATEFIRST - 2) % 7) + 1 AS formula_da_dim_data;
SET LANGUAGE us_english;
GO
PRINT N'== Mesmo texto ISO com traços: date e datetime2 ignoram DATEFORMAT, datetime não.';
SET DATEFORMAT dmy;
SELECT TRY_CAST(N'2026-02-03' AS date) AS em_date,
       TRY_CAST(N'2026-02-03' AS datetime2(0)) AS em_datetime2,
       TRY_CAST(N'2026-02-03' AS datetime) AS em_datetime,
       TRY_CAST(N'20260203' AS datetime) AS em_datetime_sem_tracos;
SET DATEFORMAT mdy;
GO
