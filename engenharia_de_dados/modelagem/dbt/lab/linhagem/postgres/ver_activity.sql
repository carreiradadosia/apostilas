-- What pg_stat_activity shows about the application sessions at this instant.
SELECT usename, application_name, state, left(regexp_replace(query, '\s+', ' ', 'g'), 130) AS query,
       octet_length(query) AS bytes_do_texto
FROM pg_stat_activity
WHERE application_name = 'erp_relatorios';
