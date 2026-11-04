-- Exercise input: which ids the table holds after the reload. 0 alone means yesterday's load survived.
SELECT coalesce(string_agg(id::text, ',' ORDER BY id), '(vazia)') AS ids_na_tabela FROM silver.recarga_exemplo;
