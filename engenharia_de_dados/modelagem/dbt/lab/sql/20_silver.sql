-- Silver: one clean row per business key. Rebuilt from bronze on every run.
DROP TABLE IF EXISTS silver.lojas, silver.de_para_categoria, silver.produtos,
    silver.produtos_vigencia, silver.pedidos, silver.itens, silver.atendimentos CASCADE;

CREATE TABLE silver.lojas AS
SELECT id AS loja_id,
       initcap(trim(nome)) AS nome,
       initcap(unaccent(trim(cidade))) AS cidade,
       fecha_as
FROM bronze.lojas;

-- TRIM, case and accent do not fix a typo: that takes a mapping someone owns.
CREATE TABLE silver.de_para_categoria (categoria_origem text PRIMARY KEY, categoria text NOT NULL);
INSERT INTO silver.de_para_categoria VALUES ('papelria', 'papelaria');

-- Latest photo of each product, not the latest global one: a product that leaves
-- the last photo keeps its name and category, so its versions stay in the dimension.
CREATE TABLE silver.produtos AS
WITH ultima_foto AS (
    SELECT DISTINCT ON (id) *
    FROM bronze.produtos_foto
    ORDER BY id, _dia_referencia DESC
)
SELECT u.id AS produto_id,
       initcap(trim(u.nome)) AS nome,
       COALESCE(d.categoria, lower(unaccent(trim(u.categoria)))) AS categoria,
       u.preco,
       u.custo  -- stays null on purpose: unknown cost is not zero cost
FROM ultima_foto u
LEFT JOIN silver.de_para_categoria d
       ON d.categoria_origem = lower(unaccent(trim(u.categoria)));

-- Type 2 history derived from the photos: one row per price period, half-open interval.
CREATE TABLE silver.produtos_vigencia AS
WITH fotos AS (
    SELECT id AS produto_id, preco, _dia_referencia AS dia,
           lag(preco) OVER (PARTITION BY id ORDER BY _dia_referencia) AS preco_anterior,
           row_number() OVER (PARTITION BY id ORDER BY _dia_referencia) AS ordem
    FROM bronze.produtos_foto
), mudancas AS (
    SELECT produto_id, preco, dia AS valido_de
    FROM fotos
    WHERE ordem = 1 OR preco IS DISTINCT FROM preco_anterior
)
SELECT produto_id, preco, valido_de,
       lead(valido_de) OVER (PARTITION BY produto_id ORDER BY valido_de) AS valido_ate
FROM mudancas;

CREATE TABLE silver.pedidos AS
WITH ultima_carga AS (
    SELECT *, row_number() OVER (PARTITION BY id ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.pedidos
)
SELECT id AS pedido_id,
       loja_id,
       COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado') AS cliente,
       valor,
       lower(trim(status)) AS status_origem,
       CASE lower(trim(status))
           WHEN 'pago' THEN 'pago'
           WHEN 'cancelado' THEN 'cancelado'
           WHEN 'pendente' THEN 'pendente'
           ELSE 'desconhecido'
       END AS status,
       to_date(emissao_texto, 'DD/MM/YYYY') AS dia_emissao,
       criado_em AT TIME ZONE 'America/Sao_Paulo' AS criado_em_utc,
       criado_em::date AS dia_local
FROM ultima_carga
WHERE ordem = 1;

CREATE TABLE silver.itens AS
SELECT pedido_id, item_seq, produto_id, quantidade, preco_unitario,
       quantidade * preco_unitario AS valor_item
FROM bronze.itens_pedido;

-- The source stores UTC in a column without zone: declare it as UTC, then read it in local time.
CREATE TABLE silver.atendimentos AS
SELECT id AS atendimento_id,
       loja_id,
       COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AS inicio_utc,
       COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS inicio_local,
       (COALESCE(atendido_em_utc, criado_em_utc) AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo')::date AS dia_local,
       atendido_em_utc IS NULL AS sem_atendido_em
FROM bronze.atendimentos;

SELECT 'silver.pedidos' AS tabela, count(*) AS linhas FROM silver.pedidos
UNION ALL SELECT 'silver.itens', count(*) FROM silver.itens
UNION ALL SELECT 'silver.lojas', count(*) FROM silver.lojas
UNION ALL SELECT 'silver.produtos', count(*) FROM silver.produtos
UNION ALL SELECT 'silver.produtos_vigencia', count(*) FROM silver.produtos_vigencia
UNION ALL SELECT 'silver.atendimentos', count(*) FROM silver.atendimentos;
