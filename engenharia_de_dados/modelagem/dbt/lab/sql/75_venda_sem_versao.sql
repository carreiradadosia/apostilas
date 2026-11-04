-- A sale with no price version: five ways to treat it, over the 13 real items plus 4 synthetic sales.
-- Run after Lab 4 (three photos). The synthetic sales live only in this file's schema: bronze and silver stay as they are.
-- 900: sold before the first photo. 901: 22h30 local, the day changes in UTC.
-- 902: sold at 1h, before the 3h nightly job that changed the price. 903: a product no photo has seen.
\pset border 1
\pset null '<nulo>'
DROP SCHEMA IF EXISTS ensaio_sem_versao CASCADE;
CREATE SCHEMA ensaio_sem_versao;

CREATE TABLE ensaio_sem_versao.vendas_sinteticas (
    pedido_id integer, item_seq integer, produto_id integer, quantidade integer,
    preco_unitario numeric(12, 2), status text, criado_em timestamp without time zone
);
INSERT INTO ensaio_sem_versao.vendas_sinteticas VALUES
    (900, 1, 10, 1, 60.00, 'pago', '2026-10-19 12:00'),
    (901, 1, 40, 1, 20.50, 'pago', '2026-10-21 22:30'),
    (902, 1, 40, 1, 20.50, 'pago', '2026-10-22 01:00'),
    (903, 1, 60, 1,  9.00, 'pago', '2026-10-22 15:00');

-- Same columns and same day rule as the silver: the ERP writes local time, so the local day is the date part.
CREATE VIEW ensaio_sem_versao.vendas AS
SELECT i.pedido_id, i.item_seq, i.produto_id, i.quantidade, i.preco_unitario, i.valor_item, o.status,
       o.dia_local, o.criado_em_utc
FROM silver.itens i JOIN silver.pedidos o USING (pedido_id)
UNION ALL
SELECT pedido_id, item_seq, produto_id, quantidade, preco_unitario, quantidade * preco_unitario, status,
       criado_em::date, criado_em AT TIME ZONE 'America/Sao_Paulo'
FROM ensaio_sem_versao.vendas_sinteticas;

-- Base dimension with the lab hash key; the options below change only what a failed lookup finds.
CREATE TABLE ensaio_sem_versao.d_base AS
SELECT md5(v.produto_id::text || '|' || to_char(v.valido_de, 'YYYY-MM-DD')) AS produto_sk,
       v.produto_id, p.nome, v.preco AS preco_tabela, v.valido_de, v.valido_ate
FROM silver.produtos_vigencia v JOIN silver.produtos p USING (produto_id);
CREATE TABLE ensaio_sem_versao.d_membro AS
SELECT * FROM ensaio_sem_versao.d_base
UNION ALL SELECT '-1', NULL, 'Desconhecido', NULL, NULL, NULL;
CREATE TABLE ensaio_sem_versao.d_recuada AS
SELECT produto_sk, produto_id, nome, preco_tabela,
       CASE WHEN valido_de = min(valido_de) OVER (PARTITION BY produto_id)
            THEN (SELECT min(data_id) FROM gold.dim_data) ELSE valido_de END AS valido_de,
       valido_ate
FROM ensaio_sem_versao.d_base;
CREATE TABLE ensaio_sem_versao.d_versao_zero AS
SELECT * FROM ensaio_sem_versao.d_base
UNION ALL
SELECT md5(produto_id::text || '|anterior'), produto_id, min(nome), NULL,
       (SELECT min(data_id) FROM gold.dim_data), min(valido_de)
FROM ensaio_sem_versao.d_base GROUP BY produto_id;

CREATE TABLE ensaio_sem_versao.f_a AS
SELECT v.*, d.produto_sk, d.preco_tabela FROM ensaio_sem_versao.vendas v
JOIN ensaio_sem_versao.d_base d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                               AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate);
CREATE TABLE ensaio_sem_versao.f_b AS
SELECT v.*, d.produto_sk, d.preco_tabela FROM ensaio_sem_versao.vendas v
LEFT JOIN ensaio_sem_versao.d_base d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                                    AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate);
CREATE TABLE ensaio_sem_versao.f_c AS
SELECT v.*, COALESCE(d.produto_sk, '-1') AS produto_sk, d.preco_tabela FROM ensaio_sem_versao.vendas v
LEFT JOIN ensaio_sem_versao.d_membro d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                                      AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate);
CREATE TABLE ensaio_sem_versao.f_d AS
SELECT v.*, d.produto_sk, d.preco_tabela FROM ensaio_sem_versao.vendas v
LEFT JOIN ensaio_sem_versao.d_recuada d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                                       AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate);
CREATE TABLE ensaio_sem_versao.f_e AS
SELECT v.*, d.produto_sk, d.preco_tabela FROM ensaio_sem_versao.vendas v
LEFT JOIN ensaio_sem_versao.d_versao_zero d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                                           AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate);

\echo == Referência: 13 itens reais e 4 sintéticos; a receita paga certa é 836,10 + 110,00.
SELECT count(*) AS itens, sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga FROM ensaio_sem_versao.vendas;

\echo == As cinco opções, com o que not_null e relationships contariam em cada uma.
-- Orphans use the same query the dbt relationships test compiles to: nulls are left out.
CREATE FUNCTION pg_temp.orfas(fato regclass, dim regclass) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
    EXECUTE format('WITH child AS (SELECT produto_sk AS from_field FROM %s WHERE produto_sk IS NOT NULL),
                         parent AS (SELECT produto_sk AS to_field FROM %s)
                    SELECT count(*) FROM child LEFT JOIN parent ON child.from_field = parent.to_field
                    WHERE parent.to_field IS NULL', fato, dim) INTO n;
    RETURN n;
END $$;
SELECT opcao, linhas, receita_paga, nulos_not_null, orfas_relationships, sem_preco_tabela FROM (
    SELECT 1 AS o, 'A. JOIN: a venda some' AS opcao, count(*) AS linhas,
           sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga,
           count(*) FILTER (WHERE produto_sk IS NULL) AS nulos_not_null,
           pg_temp.orfas('ensaio_sem_versao.f_a', 'ensaio_sem_versao.d_base') AS orfas_relationships,
           count(*) FILTER (WHERE preco_tabela IS NULL) AS sem_preco_tabela
    FROM ensaio_sem_versao.f_a
    UNION ALL
    SELECT 2, 'B. LEFT JOIN: chave nula', count(*), sum(valor_item) FILTER (WHERE status = 'pago'),
           count(*) FILTER (WHERE produto_sk IS NULL), pg_temp.orfas('ensaio_sem_versao.f_b', 'ensaio_sem_versao.d_base'),
           count(*) FILTER (WHERE preco_tabela IS NULL)
    FROM ensaio_sem_versao.f_b
    UNION ALL
    SELECT 3, 'C. membro desconhecido', count(*), sum(valor_item) FILTER (WHERE status = 'pago'),
           count(*) FILTER (WHERE produto_sk IS NULL), pg_temp.orfas('ensaio_sem_versao.f_c', 'ensaio_sem_versao.d_membro'),
           count(*) FILTER (WHERE preco_tabela IS NULL)
    FROM ensaio_sem_versao.f_c
    UNION ALL
    SELECT 4, 'D. primeira versão recuada', count(*), sum(valor_item) FILTER (WHERE status = 'pago'),
           count(*) FILTER (WHERE produto_sk IS NULL), pg_temp.orfas('ensaio_sem_versao.f_d', 'ensaio_sem_versao.d_recuada'),
           count(*) FILTER (WHERE preco_tabela IS NULL)
    FROM ensaio_sem_versao.f_d
    UNION ALL
    SELECT 5, 'E. versão zero, preço nulo', count(*), sum(valor_item) FILTER (WHERE status = 'pago'),
           count(*) FILTER (WHERE produto_sk IS NULL), pg_temp.orfas('ensaio_sem_versao.f_e', 'ensaio_sem_versao.d_versao_zero'),
           count(*) FILTER (WHERE preco_tabela IS NULL)
    FROM ensaio_sem_versao.f_e
) t ORDER BY o;

\echo == relationships pela chave natural, na opção B: acusa só o produto que nenhuma foto viu.
SELECT count(*) AS orfas_pela_chave_natural FROM ensaio_sem_versao.f_b f
WHERE f.produto_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM silver.produtos p WHERE p.produto_id = f.produto_id);

\echo == O que cada opção lê para as duas vendas sem versão.
SELECT f.pedido_id, f.produto_id AS produto_vendido, 'B' AS opcao, d.nome, f.preco_unitario, f.preco_tabela
FROM ensaio_sem_versao.f_b f LEFT JOIN ensaio_sem_versao.d_base d USING (produto_sk) WHERE f.pedido_id IN (900, 903)
UNION ALL
SELECT f.pedido_id, f.produto_id, 'C', d.nome, f.preco_unitario, f.preco_tabela
FROM ensaio_sem_versao.f_c f LEFT JOIN ensaio_sem_versao.d_membro d USING (produto_sk) WHERE f.pedido_id IN (900, 903)
UNION ALL
SELECT f.pedido_id, f.produto_id, 'D', d.nome, f.preco_unitario, f.preco_tabela
FROM ensaio_sem_versao.f_d f LEFT JOIN ensaio_sem_versao.d_recuada d USING (produto_sk) WHERE f.pedido_id IN (900, 903)
UNION ALL
SELECT f.pedido_id, f.produto_id, 'E', d.nome, f.preco_unitario, f.preco_tabela
FROM ensaio_sem_versao.f_e f LEFT JOIN ensaio_sem_versao.d_versao_zero d USING (produto_sk) WHERE f.pedido_id IN (900, 903)
ORDER BY 1, 3;

\echo == Mesmo relógio: a venda das 22h30 do dia 21 pelo dia local e pelo dia em UTC.
SELECT v.pedido_id, v.preco_unitario, 'local' AS calendario, v.dia_local AS dia, d.preco_tabela
FROM ensaio_sem_versao.vendas v
JOIN ensaio_sem_versao.d_base d ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
                               AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate)
WHERE v.pedido_id = 901
UNION ALL
SELECT v.pedido_id, v.preco_unitario, 'UTC', (v.criado_em_utc AT TIME ZONE 'UTC')::date, d.preco_tabela
FROM ensaio_sem_versao.vendas v
JOIN ensaio_sem_versao.d_base d ON d.produto_id = v.produto_id
 AND (v.criado_em_utc AT TIME ZONE 'UTC')::date >= d.valido_de
 AND (d.valido_ate IS NULL OR (v.criado_em_utc AT TIME ZONE 'UTC')::date < d.valido_ate)
WHERE v.pedido_id = 901;

\echo == Limite da foto diária: venda à 1h do dia 22, antes da rotina das 3h. A vigência já marca o preço novo.
SELECT f.pedido_id, f.dia_local, f.preco_unitario AS praticado, f.preco_tabela AS tabela_do_dia,
       f.preco_unitario - f.preco_tabela AS diferenca
FROM ensaio_sem_versao.f_c f WHERE f.pedido_id = 902;
