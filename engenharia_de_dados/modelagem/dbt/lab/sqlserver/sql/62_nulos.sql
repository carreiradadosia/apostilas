PRINT N'== ISNULL usa o tipo do primeiro argumento e trunca; COALESCE usa o de maior precedência.';
DECLARE @curto varchar(2) = NULL;
SELECT ISNULL(@curto, 'desconhecido') AS com_isnull, COALESCE(@curto, 'desconhecido') AS com_coalesce;
GO
PRINT N'== Tipo do resultado, lido do catálogo depois de SELECT INTO.';
DROP TABLE IF EXISTS #tipos;
SELECT ISNULL(a, 'desconhecido') AS com_isnull,
       COALESCE(a, 'desconhecido') AS com_coalesce,
       ISNULL(n, 0) AS isnull_numerico,
       COALESCE(n, 0) AS coalesce_numerico
INTO #tipos
FROM (VALUES (CAST(NULL AS varchar(2)), CAST(NULL AS numeric(12, 2)))) AS t(a, n);
SELECT c.name AS coluna, ty.name AS tipo, c.max_length, c.precision, c.scale, c.is_nullable
FROM tempdb.sys.columns c
JOIN tempdb.sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('tempdb..#tipos')
ORDER BY c.column_id;
GO
PRINT N'== COALESCE com tipos que não convertem: o texto tenta virar número e a linha quebra.';
GO
SELECT COALESCE(CAST(NULL AS int), N'desconhecido') AS inteiro_ou_texto;
GO
PRINT N'== ISNULL nas mesmas condições devolve erro igual, porque converte para int.';
GO
SELECT ISNULL(CAST(NULL AS int), N'desconhecido') AS inteiro_ou_texto;
GO
PRINT N'== Só NULL literal em COALESCE é erro; em ISNULL devolve int.';
GO
SELECT COALESCE(NULL, NULL) AS tentativa;
GO
SELECT ISNULL(NULL, NULL) AS devolve_nulo;
GO
PRINT N'== CASE sem ELSE devolve NULL sem aviso; ELSE explícito fica visível e contável.';
SELECT status_novo,
       CASE status_novo WHEN N'pago' THEN N'pago' END AS sem_else,
       CASE status_novo WHEN N'pago' THEN N'pago' ELSE N'desconhecido' END AS com_else
FROM (VALUES (N'pago'), (N'estornado'), (NULL)) AS t(status_novo);
GO
PRINT N'== Nulo com critério: custo nulo fica nulo e é contado; zero mudaria a margem.';
SELECT COUNT(*) AS produtos,
       SUM(CASE WHEN custo IS NULL THEN 1 ELSE 0 END) AS sem_custo,
       SUM(preco - custo) AS margem_de_tabela_ignorando_nulo,
       SUM(preco - COALESCE(custo, 0)) AS margem_de_tabela_com_zero
FROM silver.produtos;
GO
PRINT N'== O aviso de SUM com NULL: neste sqlcmd, SELECT puro não mostra; SELECT INTO mostra.';
SELECT SUM(x) AS soma FROM (VALUES (1), (NULL)) AS t(x);
GO
SELECT SUM(x) AS soma INTO #soma FROM (VALUES (1), (NULL)) AS t(x);
GO
PRINT N'== NULLIF cobre texto vazio e também só espaços, porque = ignora espaço à direita.';
SELECT COALESCE(NULLIF(N'', N''), N'Não informado') AS vazio,
       COALESCE(NULLIF(N'   ', N''), N'Não informado') AS so_espacos,
       COALESCE(NULLIF(N'x', N''), N'Não informado') AS com_valor;
GO
