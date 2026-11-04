-- Read-only simulation of a product that leaves the last photo, comparing the two silver filters.
-- Nothing is written: the photo of day 23 exists only inside the CTE, in a read-only transaction.
START TRANSACTION READ ONLY;

\echo == Fotos da bronze: os 5 produtos estão nas 3 fotos, e não existe foto do dia 23.
SELECT _dia_referencia, count(*) AS produtos FROM bronze.produtos_foto GROUP BY 1 ORDER BY 1;

\echo == Versões da dimensão, sem contar o membro desconhecido. Só a simulação separa os dois filtros.
WITH fotos AS (
    SELECT 1 AS ordem_cenario, 'dados reais' AS cenario, id, preco, _dia_referencia
    FROM bronze.produtos_foto
    UNION ALL
    SELECT 2, 'produto 50 fora da foto do dia 23', id, preco, _dia_referencia
    FROM bronze.produtos_foto
    UNION ALL
    SELECT 2, 'produto 50 fora da foto do dia 23', id, preco, DATE '2026-10-23'
    FROM bronze.produtos_foto
    WHERE _dia_referencia = DATE '2026-10-22' AND id <> 50
), marcadas AS (
    SELECT ordem_cenario, cenario, id AS produto_id, preco, _dia_referencia AS dia,
           lag(preco) OVER (PARTITION BY cenario, id ORDER BY _dia_referencia) AS preco_anterior,
           row_number() OVER (PARTITION BY cenario, id ORDER BY _dia_referencia) AS ordem
    FROM fotos
), vigencia AS (
    -- Same rule as silver.produtos_vigencia: one row per price period.
    SELECT ordem_cenario, cenario, produto_id
    FROM marcadas
    WHERE ordem = 1 OR preco IS DISTINCT FROM preco_anterior
), filtro_global AS (
    -- The earlier silver filter: only what is in the latest photo overall.
    SELECT f.cenario, f.id AS produto_id
    FROM fotos f
    WHERE f._dia_referencia = (SELECT max(m._dia_referencia) FROM fotos m WHERE m.cenario = f.cenario)
), filtro_por_produto AS (
    -- The current silver filter: the latest photo of each product.
    SELECT DISTINCT ON (cenario, id) cenario, id AS produto_id
    FROM fotos
    ORDER BY cenario, id, _dia_referencia DESC
)
SELECT v.cenario,
       count(*) AS versoes_na_vigencia,
       count(g.produto_id) AS dimensao_filtro_global,
       count(p.produto_id) AS dimensao_filtro_por_produto
FROM vigencia v
LEFT JOIN filtro_global g USING (cenario, produto_id)
LEFT JOIN filtro_por_produto p USING (cenario, produto_id)
GROUP BY v.ordem_cenario, v.cenario
ORDER BY v.ordem_cenario;

\echo == A versão que o filtro global perde: o produto 50 tem uma só, e a foto do dia 23 não muda o preço de ninguém.
SELECT produto_id, preco, valido_de, valido_ate FROM silver.produtos_vigencia WHERE produto_id = 50;

COMMIT;
