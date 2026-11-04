PRINT N'== Collation do servidor e do banco, e o que acontece com o UTF-8 deste arquivo.';
SELECT CAST(SERVERPROPERTY('Collation') AS nvarchar(128)) AS servidor,
       CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS nvarchar(128)) AS banco,
       UNICODE(N'ã') AS unicode_de_a_til;

PRINT N'== TRIM e caixa. TRIM sem argumento só tira espaço; tab e espaço duro ficam.';
SELECT N'[' + TRIM(N'  Loja Centro ') + N']' AS trim_espaco,
       UPPER(N'são joão') AS upper_com_acento,
       LOWER(N'SÃO JOÃO') AS lower_com_acento,
       LEN(TRIM(NCHAR(9) + N'x' + NCHAR(9))) AS len_com_tab,
       LEN(TRIM(NCHAR(160) + N'x' + NCHAR(160))) AS len_com_espaco_duro,
       LEN(TRIM(NCHAR(9) + NCHAR(160) + N' ' FROM NCHAR(9) + N'x' + NCHAR(160))) AS len_com_lista_de_caracteres;
GO
PRINT N'== INITCAP e unaccent, do Postgres, não existem em T-SQL.';
GO
SELECT INITCAP(N'são joão') AS tentativa;
GO
SELECT unaccent(N'são joão') AS tentativa;
GO
PRINT N'== Collation padrão é insensível a caixa: comparação, DISTINCT e GROUP BY.';
SELECT CASE WHEN N'PAGO' = N'pago' THEN N'igual' ELSE N'diferente' END AS padrao_ci,
       CASE WHEN N'PAGO' = N'pago' COLLATE Latin1_General_100_CS_AS THEN N'igual' ELSE N'diferente' END AS com_cs,
       CASE WHEN N'São Paulo' = N'Sao Paulo' THEN N'igual' ELSE N'diferente' END AS padrao_as,
       CASE WHEN N'São Paulo' = N'Sao Paulo' COLLATE Latin1_General_100_CI_AI THEN N'igual' ELSE N'diferente' END AS com_ai;

CREATE TABLE #categorias (categoria nvarchar(30));
INSERT INTO #categorias VALUES (N'Papelaria'), (N'PAPELARIA'), (N'papelaria '), (N'Papelária');

SELECT DISTINCT categoria AS distinct_padrao FROM #categorias;
SELECT categoria AS grupo_padrao, COUNT(*) AS linhas FROM #categorias GROUP BY categoria;
SELECT categoria COLLATE Latin1_General_100_CS_AS AS grupo_sensivel, COUNT(*) AS linhas
FROM #categorias GROUP BY categoria COLLATE Latin1_General_100_CS_AS;
SELECT MIN(categoria) COLLATE Latin1_General_100_CI_AI AS grupo_ai, COUNT(*) AS linhas
FROM #categorias GROUP BY categoria COLLATE Latin1_General_100_CI_AI;
DROP TABLE #categorias;

PRINT N'== Sem TRIM, a collation ainda salva a caixa e o espaço à direita. Não salva o espaço à esquerda.';
SELECT bruto,
       CASE bruto WHEN N'pago' THEN N'casou' ELSE N'não casou' END AS comparacao_direta
FROM (VALUES (N'PAGO'), (N'pago '), (N' Pago ')) AS t(bruto);

PRINT N'== Espaço à direita: igual em =, some em LEN, conta em DATALENGTH. Em LIKE, depende de ser nvarchar ou varchar.';
SELECT CASE WHEN N'abc' = N'abc   ' THEN N'igual' ELSE N'diferente' END AS igual_com_espaco,
       CASE WHEN N'abc' = N'abc   ' COLLATE Latin1_General_100_BIN2 THEN N'igual' ELSE N'diferente' END AS igual_em_binaria,
       LEN(N'abc   ') AS len,
       DATALENGTH(N'abc   ') AS datalength_nvarchar,
       DATALENGTH('abc   ') AS datalength_varchar,
       CASE WHEN N'abc' LIKE N'abc   ' THEN N'casou' ELSE N'não casou' END AS like_padrao_com_espaco,
       CASE WHEN N'abc   ' LIKE N'abc' THEN N'casou' ELSE N'não casou' END AS like_valor_nvarchar,
       CASE WHEN 'abc   ' LIKE 'abc' THEN N'casou' ELSE N'não casou' END AS like_valor_varchar;

PRINT N'== N e varchar: português cabe na página de código deste banco, o resto vira ? sem erro.';
DECLARE @v varchar(20) = N'São João Ж', @n nvarchar(20) = N'São João Ж';
SELECT @v AS em_varchar, @n AS em_nvarchar, 'São João Ж' AS literal_sem_n, N'São João Ж' AS literal_com_n,
       DATALENGTH(@v) AS bytes_varchar, DATALENGTH(@n) AS bytes_nvarchar;
GO
PRINT N'== Acento: collation compara ignorando, mas não remove. O valor sai igual.';
SELECT N'São Paulo' COLLATE Latin1_General_100_CI_AI AS com_collate,
       CASE WHEN N'São Paulo' COLLATE Latin1_General_100_CI_AI = N'SAO PAULO' THEN N'igual' ELSE N'diferente' END AS compara_com_ai;

PRINT N'== TRANSLATE é a forma documentada de trocar caractere por caractere. A collation da entrada muda o resultado.';
SELECT TRANSLATE(N'Álvaro São João', N'áãÁÃ', N'aaAA') AS padrao_ci,
       TRANSLATE(N'Álvaro São João' COLLATE Latin1_General_100_BIN2, N'áãÁÃ', N'aaAA') AS binaria,
       TRANSLATE(N'Alvaro' COLLATE Latin1_General_100_CI_AI, N'a', N'X') AS ai_troca_sem_acento_tambem,
       TRANSLATE(N'Álvaro' COLLATE Latin1_General_100_CI_AI, N'a', N'X') AS ai_troca_com_acento_tambem;

SELECT silver.sem_acento(N'Conceição Ação Órgão Índio Ünico') AS sem_acento_do_laboratorio,
       LOWER(silver.sem_acento(N' CAFÉ ')) AS em_cadeia_sem_trim;
GO
PRINT N'== TRANSLATE com listas de tamanho diferente é erro, não truncamento.';
SELECT TRANSLATE(N'abc', N'ab', N'x') AS tentativa;
GO
PRINT N'== Duas collations na mesma comparação: erro de compilação, comum entre o ERP e um banco novo.';
CREATE TABLE #a (c nvarchar(10) COLLATE Latin1_General_CI_AS);
CREATE TABLE #b (c nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS);
GO
SELECT COUNT(*) AS linhas FROM #a JOIN #b ON #a.c = #b.c;
GO
SELECT COUNT(*) AS linhas_com_collate FROM #a JOIN #b ON #a.c = #b.c COLLATE Latin1_General_CI_AS;
GO
