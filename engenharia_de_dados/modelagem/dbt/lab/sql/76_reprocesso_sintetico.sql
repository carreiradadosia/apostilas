-- Reprocessing on synthetic rows, chapter 14: the same load twice, a failure inside the transaction,
-- a repeated key in the batch, a late fact and a view against a materialized view.
-- Run with ON_ERROR_STOP off: some cases end in an error on purpose, and the next block shows what was left.
-- Writes only to its own schema, rebuilt on every run.
\pset border 1
DROP SCHEMA IF EXISTS ensaio_reprocesso CASCADE;
CREATE SCHEMA ensaio_reprocesso;
SET search_path = ensaio_reprocesso;
\pset null '(nulo)'
\echo == 1. INSERT duas vezes
-- A daily load with one row per store. Synthetic data.
CREATE TABLE carga_do_dia (dia date, loja_id int, receita numeric(10,2));
INSERT INTO carga_do_dia VALUES ('2026-10-20', 1, 130.00), ('2026-10-20', 2, 90.00);
CREATE TABLE fct_dia (dia date, loja_id int, receita numeric(10,2));

-- The same load twice, as an orchestrator retry would do.
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
INSERT INTO fct_dia SELECT * FROM carga_do_dia;

SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;

\echo == 2. DELETE e INSERT numa transação, duas vezes
TRUNCATE fct_dia;
BEGIN;
DELETE FROM fct_dia WHERE dia = '2026-10-20';
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
COMMIT;
BEGIN;
DELETE FROM fct_dia WHERE dia = '2026-10-20';
INSERT INTO fct_dia SELECT * FROM carga_do_dia;
COMMIT;
SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;

\echo == 2b. falha no meio da transação preserva a janela
BEGIN;
DELETE FROM fct_dia WHERE dia = '2026-10-20';
INSERT INTO fct_dia VALUES ('2026-10-20', 1, 'nao_e_numero');
ROLLBACK;
SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;

\echo == 3. UNIQUE e ON CONFLICT, duas vezes
TRUNCATE fct_dia;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE (dia, loja_id);
INSERT INTO fct_dia SELECT * FROM carga_do_dia
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
INSERT INTO fct_dia SELECT * FROM carga_do_dia
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT loja_id, count(*) AS linhas, sum(receita) AS receita
FROM fct_dia GROUP BY 1 ORDER BY 1;

\echo == 4. Chave com nulo, UNIQUE padrão
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT count(*) AS linhas FROM fct_dia WHERE dia = '2026-10-23';

\echo == 4b. Chave com nulo, UNIQUE NULLS NOT DISTINCT
DELETE FROM fct_dia WHERE dia = '2026-10-23';
ALTER TABLE fct_dia DROP CONSTRAINT fct_dia_grao;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE NULLS NOT DISTINCT (dia, loja_id);
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
INSERT INTO fct_dia VALUES ('2026-10-23', NULL, 10.00)
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT count(*) AS linhas FROM fct_dia WHERE dia = '2026-10-23';

\echo == 5. Chave repetida no lote
-- A batch with the same key twice.
CREATE TABLE lote (dia date, loja_id int, receita numeric(10,2));
INSERT INTO lote VALUES ('2026-10-22', 1, 10.00), ('2026-10-22', 1, 20.00);

\echo == 5a. ON CONFLICT, chave nova
TRUNCATE fct_dia;
ALTER TABLE fct_dia DROP CONSTRAINT fct_dia_grao;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE (dia, loja_id);
INSERT INTO fct_dia SELECT * FROM lote
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5b. ON CONFLICT, chave existente
INSERT INTO fct_dia VALUES ('2026-10-22', 1, 5.00);
INSERT INTO fct_dia SELECT * FROM lote
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5c. MERGE com UNIQUE, chave nova
TRUNCATE fct_dia;
MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5d. MERGE com UNIQUE, chave existente
INSERT INTO fct_dia VALUES ('2026-10-22', 1, 5.00);
MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5e. Sem UNIQUE: MERGE, chave nova
TRUNCATE fct_dia;
ALTER TABLE fct_dia DROP CONSTRAINT fct_dia_grao;
MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5f. Sem UNIQUE: MERGE, chave existente
TRUNCATE fct_dia;
INSERT INTO fct_dia VALUES ('2026-10-22', 1, 5.00);
MERGE INTO fct_dia f USING lote l ON f.dia = l.dia AND f.loja_id = l.loja_id
WHEN MATCHED THEN UPDATE SET receita = l.receita
WHEN NOT MATCHED THEN INSERT VALUES (l.dia, l.loja_id, l.receita);
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5g. Sem UNIQUE: DELETE USING e INSERT, chave nova
TRUNCATE fct_dia;
BEGIN;
DELETE FROM fct_dia f USING lote l WHERE f.dia = l.dia AND f.loja_id = l.loja_id;
INSERT INTO fct_dia SELECT * FROM lote;
COMMIT;
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5h. Sem UNIQUE: DELETE USING e INSERT, chave existente
TRUNCATE fct_dia;
INSERT INTO fct_dia VALUES ('2026-10-22', 1, 5.00);
BEGIN;
DELETE FROM fct_dia f USING lote l WHERE f.dia = l.dia AND f.loja_id = l.loja_id;
INSERT INTO fct_dia SELECT * FROM lote;
COMMIT;
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 5i. Lote deduplicado antes de gravar, com ON CONFLICT
TRUNCATE fct_dia;
ALTER TABLE fct_dia ADD CONSTRAINT fct_dia_grao UNIQUE (dia, loja_id);
INSERT INTO fct_dia
SELECT DISTINCT ON (dia, loja_id) dia, loja_id, receita FROM lote ORDER BY dia, loja_id, receita DESC
ON CONFLICT (dia, loja_id) DO UPDATE SET receita = EXCLUDED.receita;
SELECT count(*) AS linhas, sum(receita) AS receita FROM fct_dia;

\echo == 6. Fato atrasado
CREATE TABLE origem (atendimento_id int PRIMARY KEY, dia date);
CREATE TABLE alvo (atendimento_id int PRIMARY KEY, dia date);
INSERT INTO origem VALUES (1, '2026-10-20'), (2, '2026-10-21');
INSERT INTO alvo SELECT * FROM origem;

-- Attendance 3 belongs to day 20 and only shows up now.
INSERT INTO origem VALUES (3, '2026-10-20');

\echo == 6a. Filtro no máximo do alvo
INSERT INTO alvo SELECT * FROM origem
WHERE dia >= (SELECT max(dia) FROM alvo)
ON CONFLICT (atendimento_id) DO UPDATE SET dia = EXCLUDED.dia;
SELECT (SELECT count(*) FROM origem) AS na_origem, (SELECT count(*) FROM alvo) AS no_alvo;

\echo == 6b. Janela de volta de um dia
INSERT INTO alvo SELECT * FROM origem
WHERE dia >= (SELECT max(dia) FROM alvo) - 1
ON CONFLICT (atendimento_id) DO UPDATE SET dia = EXCLUDED.dia;
SELECT (SELECT count(*) FROM origem) AS na_origem, (SELECT count(*) FROM alvo) AS no_alvo;

\echo == 6c. Atraso maior que a janela
INSERT INTO origem VALUES (4, '2026-10-18');
INSERT INTO alvo SELECT * FROM origem
WHERE dia >= (SELECT max(dia) FROM alvo) - 1
ON CONFLICT (atendimento_id) DO UPDATE SET dia = EXCLUDED.dia;
SELECT (SELECT count(*) FROM origem) AS na_origem, (SELECT count(*) FROM alvo) AS no_alvo;

\echo == 7. Sem ferramenta: view e materialized view
CREATE TABLE base (id int, valor numeric(10,2));
INSERT INTO base VALUES (1, 10.00);
CREATE VIEW v_base AS SELECT id, valor FROM base;
CREATE MATERIALIZED VIEW mv_base AS SELECT id, valor FROM base;
INSERT INTO base VALUES (2, 20.00);
SELECT (SELECT count(*) FROM v_base) AS na_view, (SELECT count(*) FROM mv_base) AS na_materializada;
REFRESH MATERIALIZED VIEW mv_base;
SELECT (SELECT count(*) FROM v_base) AS na_view, (SELECT count(*) FROM mv_base) AS na_materializada;
RESET search_path;
