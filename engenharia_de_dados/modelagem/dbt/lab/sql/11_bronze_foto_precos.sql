-- Daily photo of the product table, raw. Run with: psql -v dia=2026-10-20 -f ...
DELETE FROM bronze.produtos_foto WHERE _dia_referencia = :'dia'::date;
INSERT INTO bronze.produtos_foto SELECT *, :'dia'::date FROM replica.produtos;
SELECT _dia_referencia, count(*) AS linhas FROM bronze.produtos_foto GROUP BY 1 ORDER BY 1;
