-- Daily photo of the product table, raw. Run with: sqlcmd -v dia=2026-10-20 -i ...
DELETE FROM bronze.produtos_foto WHERE _dia_referencia = CONVERT(date, '$(dia)', 23);

INSERT INTO bronze.produtos_foto (id, nome, categoria, preco, custo, atualizado_em, _dia_referencia)
SELECT id, nome, categoria, preco, custo, atualizado_em, CONVERT(date, '$(dia)', 23)
FROM replica.produtos;

SELECT _dia_referencia, COUNT(*) AS linhas
FROM bronze.produtos_foto
GROUP BY _dia_referencia
ORDER BY _dia_referencia;
