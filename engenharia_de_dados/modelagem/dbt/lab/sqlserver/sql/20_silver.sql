-- Silver: one clean row per business key. Rebuilt from bronze on every run.
-- Needs SQL Server 2017 or later (TRIM, TRANSLATE); nothing here depends on 2022 or 2025.
SET XACT_ABORT ON;
GO
-- T-SQL has no INITCAP: first letter after a space goes up, everything else goes down.
CREATE OR ALTER FUNCTION silver.iniciais (@texto nvarchar(200))
RETURNS nvarchar(200)
AS
BEGIN
    DECLARE @saida nvarchar(200) = LOWER(@texto), @i int = 1, @n int = LEN(@texto);
    WHILE @i <= @n
    BEGIN
        IF @i = 1 OR SUBSTRING(@saida, @i - 1, 1) = N' '
            SET @saida = STUFF(@saida, @i, 1, UPPER(SUBSTRING(@saida, @i, 1)));
        SET @i += 1;
    END;
    RETURN @saida;
END;
GO
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
GO
-- DDL is transactional here: a failure in the middle leaves the previous silver standing.
BEGIN TRANSACTION;

DROP TABLE IF EXISTS silver.lojas, silver.de_para_categoria, silver.produtos,
    silver.produtos_vigencia, silver.pedidos, silver.itens, silver.atendimentos;

SELECT id AS loja_id,
       silver.iniciais(TRIM(nome)) AS nome,
       silver.iniciais(silver.sem_acento(TRIM(cidade))) AS cidade,
       fecha_as
INTO silver.lojas
FROM bronze.lojas;

-- TRIM, case and accent do not fix a typo: that takes a mapping someone owns.
CREATE TABLE silver.de_para_categoria (categoria_origem nvarchar(100) PRIMARY KEY, categoria nvarchar(100) NOT NULL);
INSERT INTO silver.de_para_categoria (categoria_origem, categoria) VALUES (N'papelria', N'papelaria');

-- Latest photo of each product, not the latest global one: a product that leaves
-- the last photo keeps its name and category, so its versions stay in the dimension.
WITH ultima_foto AS (
    SELECT id, nome, categoria, preco, custo,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _dia_referencia DESC) AS ordem
    FROM bronze.produtos_foto
)
SELECT u.id AS produto_id,
       silver.iniciais(TRIM(u.nome)) AS nome,
       COALESCE(d.categoria, LOWER(silver.sem_acento(TRIM(u.categoria)))) AS categoria,
       u.preco,
       u.custo  -- stays null on purpose: unknown cost is not zero cost
INTO silver.produtos
FROM ultima_foto u
LEFT JOIN silver.de_para_categoria d
       ON d.categoria_origem = LOWER(silver.sem_acento(TRIM(u.categoria)))
WHERE u.ordem = 1;

-- Type 2 history derived from the photos: one row per price period, half-open interval.
WITH fotos AS (
    SELECT id AS produto_id, preco, _dia_referencia AS dia,
           LAG(preco) OVER (PARTITION BY id ORDER BY _dia_referencia) AS preco_anterior,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _dia_referencia) AS ordem
    FROM bronze.produtos_foto
), mudancas AS (
    SELECT produto_id, preco, dia AS valido_de
    FROM fotos
    WHERE ordem = 1 OR preco <> preco_anterior
)
SELECT produto_id, preco, valido_de,
       LEAD(valido_de) OVER (PARTITION BY produto_id ORDER BY valido_de) AS valido_ate
INTO silver.produtos_vigencia
FROM mudancas;

-- No DISTINCT ON and no QUALIFY in SQL Server: number the rows in a CTE and filter outside.
WITH ultima_carga AS (
    SELECT id, loja_id, cliente, valor, status, emissao_texto, criado_em,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.pedidos
)
SELECT id AS pedido_id,
       loja_id,
       COALESCE(NULLIF(silver.iniciais(TRIM(cliente)), N''), N'Não informado') AS cliente,
       valor,
       LOWER(TRIM(status)) AS status_origem,
       CASE LOWER(TRIM(status))
           WHEN N'pago' THEN N'pago'
           WHEN N'cancelado' THEN N'cancelado'
           WHEN N'pendente' THEN N'pendente'
           ELSE N'desconhecido'
       END AS status,
       -- NULLIF first: an empty string converts to 1900-01-01, not to NULL.
       TRY_CONVERT(date, NULLIF(TRIM(emissao_texto), N''), 103) AS dia_emissao,
       criado_em AT TIME ZONE N'E. South America Standard Time' AT TIME ZONE N'UTC' AS criado_em_utc,
       CAST(criado_em AS date) AS dia_local
INTO silver.pedidos
FROM ultima_carga
WHERE ordem = 1;

SELECT pedido_id, item_seq, produto_id, quantidade, preco_unitario,
       quantidade * preco_unitario AS valor_item
INTO silver.itens
FROM bronze.itens_pedido;

-- The source stores UTC in a column without zone: declare it as UTC, then read it in local time.
SELECT id AS atendimento_id,
       loja_id,
       COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE N'UTC' AS inicio_utc,
       CAST(COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE N'UTC'
            AT TIME ZONE N'E. South America Standard Time' AS datetime2(0)) AS inicio_local,
       CAST(COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE N'UTC'
            AT TIME ZONE N'E. South America Standard Time' AS date) AS dia_local,
       CASE WHEN atendido_em_utc IS NULL THEN 1 ELSE 0 END AS sem_atendido_em
INTO silver.atendimentos
FROM bronze.atendimentos;

COMMIT;

SELECT N'silver.pedidos' AS tabela, COUNT(*) AS linhas FROM silver.pedidos
UNION ALL SELECT N'silver.itens', COUNT(*) FROM silver.itens
UNION ALL SELECT N'silver.lojas', COUNT(*) FROM silver.lojas
UNION ALL SELECT N'silver.produtos', COUNT(*) FROM silver.produtos
UNION ALL SELECT N'silver.produtos_vigencia', COUNT(*) FROM silver.produtos_vigencia
UNION ALL SELECT N'silver.atendimentos', COUNT(*) FROM silver.atendimentos;
GO
