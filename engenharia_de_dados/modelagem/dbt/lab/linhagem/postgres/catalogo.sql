-- From the object name in the captured SQL to the source tables, reading only the catalog.
-- Joined by name rather than cast to regclass, so a role without USAGE on the schema can run it.

-- Definition of the view.
SELECT pg_get_viewdef(c.oid, true) AS definicao
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'relatorios' AND c.relname = 'vw_faturamento_itens';

-- The SQL-standard view: limited to tables owned by a role the caller holds.
SELECT view_schema, view_name, table_schema, table_name
FROM information_schema.view_table_usage
WHERE view_schema = 'relatorios'
ORDER BY table_name;

-- The dependency catalog: tables and columns used by the view, with no ownership filter.
SELECT DISTINCT tn.nspname AS esquema, t.relname AS tabela, a.attname AS coluna
FROM pg_class v
JOIN pg_namespace vn ON vn.oid = v.relnamespace
JOIN pg_rewrite r ON r.ev_class = v.oid
JOIN pg_depend d ON d.classid = 'pg_rewrite'::regclass AND d.objid = r.oid
                AND d.refclassid = 'pg_class'::regclass AND d.refobjid <> v.oid
JOIN pg_class t ON t.oid = d.refobjid
JOIN pg_namespace tn ON tn.oid = t.relnamespace
LEFT JOIN pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
WHERE vn.nspname = 'relatorios' AND v.relname = 'vw_faturamento_itens'
ORDER BY 1, 2, 3;

-- What each function declares as dependency: PL/pgSQL records nothing about the body.
SELECT p.proname AS funcao, l.lanname AS linguagem,
       coalesce(string_agg(DISTINCT t.relname, ', ') FILTER (WHERE t.relkind IN ('r', 'v')), '(nenhuma tabela ou view)') AS depende_de
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
JOIN pg_language l ON l.oid = p.prolang
LEFT JOIN pg_depend d ON d.classid = 'pg_proc'::regclass AND d.objid = p.oid
                     AND d.refclassid = 'pg_class'::regclass
LEFT JOIN pg_class t ON t.oid = d.refobjid
WHERE n.nspname = 'relatorios'
GROUP BY p.proname, l.lanname
ORDER BY 1;

-- The function source: the only way in for a string-literal body.
SELECT p.proname AS funcao, regexp_replace(p.prosrc, '\s+', ' ', 'g') AS corpo
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'relatorios' AND p.proname = 'faturamento_por_loja';
