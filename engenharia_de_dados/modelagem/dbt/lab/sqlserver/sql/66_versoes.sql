PRINT N'== Versão, edição e nível de compatibilidade padrão de um banco novo.';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(30)) AS versao,
       CAST(SERVERPROPERTY('ProductUpdateLevel') AS nvarchar(30)) AS atualizacao,
       CAST(SERVERPROPERTY('Edition') AS nvarchar(60)) AS edicao,
       CAST(SERVERPROPERTY('EngineEdition') AS int) AS motor,
       (SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME()) AS compatibilidade;
GO
PRINT N'== GENERATE_SERIES, 2022 ou mais novo: mesmo número de dias da dimensão.';
SELECT COUNT(*) AS dias
FROM GENERATE_SERIES(0, DATEDIFF(day, CONVERT(date, '20261001', 112), CONVERT(date, '20261231', 112))) AS s;
GO
PRINT N'== IS DISTINCT FROM, 2022 ou mais novo: mesmo número de mudanças de preço.';
WITH fotos AS (
    SELECT id, preco, _dia_referencia,
           LAG(preco) OVER (PARTITION BY id ORDER BY _dia_referencia) AS preco_anterior,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _dia_referencia) AS ordem
    FROM bronze.produtos_foto
)
SELECT COUNT(*) AS versoes FROM fotos WHERE ordem = 1 OR preco IS DISTINCT FROM preco_anterior;
GO
PRINT N'== TRIM com LEADING, 2022 com compatibilidade 160 ou mais.';
SELECT N'[' + TRIM(LEADING N' ' FROM N'  x ') + N']' AS trim_leading;
GO
PRINT N'== Só na 2025: REGEXP_REPLACE.';
GO
SELECT REGEXP_REPLACE(N'Loja   Centro', N'\s+', N' ') AS regexp;
GO
PRINT N'== Só na 2025: operador de concatenação ||.';
GO
SELECT N'a' || N'b' AS concat_pipes;
GO
PRINT N'== Só na 2025: CURRENT_DATE. A data real fica fora da captura.';
GO
SELECT CASE WHEN CURRENT_DATE IS NOT NULL THEN N'existe' END AS current_date_existe;
GO
PRINT N'== Em nenhuma das duas: INITCAP, QUALIFY.';
GO
SELECT INITCAP(N'x') AS tentativa;
GO
SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS o FROM bronze.lojas QUALIFY o = 1;
GO
