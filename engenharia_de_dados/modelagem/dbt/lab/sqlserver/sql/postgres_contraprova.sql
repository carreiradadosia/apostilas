-- Same text checks on Postgres 16, so the comparison in the notes is observed and not assumed.
SELECT count(*) AS distinct_categorias
FROM (SELECT DISTINCT categoria FROM (VALUES ('Papelaria'), ('PAPELARIA'), ('papelaria '), ('Papelária')) AS t(categoria)) d;
SELECT 'abc' = 'abc   ' AS igual_com_espaco, 'PAGO' = 'pago' AS igual_com_caixa;
SELECT initcap('caixa-d''água 500g') AS initcap_pg;
