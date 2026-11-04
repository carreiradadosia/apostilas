-- What pg_stat_statements kept for the application role.
SELECT r.rolname AS papel, s.queryid, s.calls, s.rows, s.toplevel,
       left(regexp_replace(s.query, '\s+', ' ', 'g'), 150) AS query
FROM pg_stat_statements s
JOIN pg_roles r ON r.oid = s.userid
WHERE r.rolname = 'app_relatorio'
ORDER BY s.toplevel DESC, query;
