-- Test the text before the cast: pg_input_is_valid answers without an error, pg_input_error_info says why.
\pset border 1

\echo == DateStyle da sessão antes do teste.
SHOW datestyle;

\echo == Com dia antes do mês, como o texto da origem.
SET datestyle = 'ISO, DMY';
SELECT v AS emissao_texto,
       pg_input_is_valid(v, 'date') AS valida,
       CASE WHEN pg_input_is_valid(v, 'date') THEN v::date END AS dia
FROM (VALUES ('20/10/2026'), ('31/02/2026'), ('ontem')) AS t(v);
SELECT message, sql_error_code FROM pg_input_error_info('31/02/2026', 'date');
RESET datestyle;
SHOW datestyle;
